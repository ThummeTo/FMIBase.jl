#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

# What is included in this file:
# - the `fmi2ComponentState`--enum which mirrors the internal FMU state (state-machine, not the system state)
# - the `FMU2ComponentEnvironment`- and `FMU2Component`-struct 
# - the `FMU2`-struct

"""
Source: FMISpec 2.0.3 [p.16f]

This is a pointer to a data structure in the simulation environment that calls the FMU. Using this
pointer, data from the modelDescription.xml file [(for example, mapping of valueReferences to
variable names)] can be transferred between the simulation environment and the logger function
(see [FMISpec 2.0.3] section 2.1.5).
"""
mutable struct FMU2ComponentEnvironment
    logStatusOK::Bool
    logStatusWarning::Bool
    logStatusDiscard::Bool
    logStatusError::Bool
    logStatusFatal::Bool
    logStatusPending::Bool

    function FMU2ComponentEnvironment()
        inst = new()
        inst.logStatusOK = true
        inst.logStatusWarning = true
        inst.logStatusDiscard = true
        inst.logStatusError = true
        inst.logStatusFatal = true
        inst.logStatusPending = true
        return inst
    end
end
export FMU2ComponentEnvironment

"""
The mutable struct represents an allocated instance of an FMU in the FMI 2.0.2 Standard.
"""
mutable struct FMU2Component{F} <: FMUInstance
    addr::fmi2Component
    cRef::UInt64

    fmu::F
    state::fmi2ComponentState
    componentEnvironment::FMU2ComponentEnvironment
    type::Union{fmi2Type,Nothing}

    problem::Any # ToDo: ODEProblem, but this is not a dependency of FMICore.jl nor FMIImport.jl ...
    solution::FMUSolution
    force::Bool
    threadid::Integer

    loggingOn::Bool
    instanceName::String
    continuousStatesChanged::fmi2Boolean
    visible::Bool

    # FMI2 only
    callbackFunctions::fmi2CallbackFunctions
    eventInfo::Union{fmi2EventInfo,Nothing}

    # caches
    t::fmi2Real             # the system time
    t_offset::fmi2Real      # time offset between simulation environment and FMU
    x::Union{Array{fmi2Real,1},Nothing}   # the system states (or sometimes u)
    x_nominals::Union{Array{fmi2Real,1},Nothing}   # the system states (or sometimes u)
    x_d::Union{Array{fmi2Real,1},Nothing} # Union{Array{Union{fmi2Real,fmi2Integer,fmi2Boolean},1}, Array{fmi2Real}, Nothing}   # the system discrete states
    ẋ::Union{Array{fmi2Real,1},Nothing}   # the system state derivative (or sometimes u̇)
    ẍ::Union{Array{fmi2Real,1},Nothing}   # the system state second derivative
    #u::Union{Array{fmi2Real, 1}, Nothing}  # the system inputs
    #y::Union{Array{fmi2Real, 1}, Nothing}  # the system outputs
    #p::Union{Array{fmi2Real, 1}, Nothing}  # the system parameters
    z::Union{Array{fmi2Real,1},Nothing}   # the system event indicators
    z_prev::Union{Array{fmi2Real,1},Nothing}   # the last system event indicators

    values::Dict{fmi2ValueReference,Union{fmi2Real,fmi2Integer,fmi2Boolean}}

    x_vrs::Array{fmi2ValueReference,1}   # the system state value references 
    ẋ_vrs::Array{fmi2ValueReference,1}   # the system state derivative value references
    u_vrs::Array{fmi2ValueReference,1}   # the system input value references
    y_vrs::Array{fmi2ValueReference,1}   # the system output value references
    p_vrs::Array{fmi2ValueReference,1}   # the system parameter value references

    # sensitivities
    ∂ẋ_∂x::Any #::Union{J, Nothing}
    ∂ẋ_∂u::Any #::Union{J, Nothing}
    ∂ẋ_∂p::Any #::Union{J, Nothing}
    ∂ẋ_∂t::Any #::Union{G, Nothing}

    ∂y_∂x::Any #::Union{J, Nothing}
    ∂y_∂u::Any #::Union{J, Nothing}
    ∂y_∂p::Any #::Union{J, Nothing}
    ∂y_∂t::Any #::Union{G, Nothing}

    ∂e_∂x::Any #::Union{J, Nothing}
    ∂e_∂u::Any #::Union{J, Nothing}
    ∂e_∂p::Any #::Union{J, Nothing}
    ∂e_∂t::Any #::Union{G, Nothing}

    ∂xr_∂xl::Any #::Union{J, Nothing}

    # performance (pointers to prevent repeating allocations)
    _enterEventMode::Array{fmi2Boolean,1}
    _ptr_enterEventMode::Ptr{fmi2Boolean}
    _terminateSimulation::Array{fmi2Boolean,1}
    _ptr_terminateSimulation::Ptr{fmi2Boolean}

    # misc
    progressMeter::Any           # progress plot
    output::FMUADOutput
    rrule_input::FMUEvaluationInput     # input buffer (for rrules)
    eval_output::FMUEvaluationOutput   # output buffer with multiple arrays that behaves like a single array (to allow for single value return functions, necessary for propper AD)
    frule_output::FMUEvaluationOutput
    eventIndicatorBuffer::AbstractArray{<:fmi2Real}

    # parameters that need sensitivities and/or are catched by optimizers (like in FMIFlux.jl)
    default_t::Real
    default_p_refs::AbstractVector{<:fmi2ValueReference}
    default_p::AbstractVector{<:Real}
    default_x_d::AbstractVector{<:Real}
    default_ec_idcs::AbstractVector{<:fmi2ValueReference}
    default_dx_refs::AbstractVector{<:fmi2ValueReference}
    default_u::AbstractVector{<:Real}
    default_y_refs::AbstractVector{<:fmi2ValueReference}

    default_dx::AbstractVector{<:Real}
    default_y::AbstractVector{<:Real}
    default_ec::AbstractVector{<:Real}

    # a container for all created snapshots, so that we can properly release them at unload
    snapshots::Vector{FMUSnapshot}
    sampleSnapshot::Union{FMUSnapshot, Nothing} # a snapshot that is (re-)used for sampling 

    termSim::Bool

    # constructor
    function FMU2Component{F}() where {F}
        inst = new{F}()
        inst.cRef = UInt64(pointer_from_objref(inst))
        inst.state = fmi2ComponentStateInstantiated
        inst.t = NO_fmi2Real
        inst.t_offset = fmi2Real(0.0)
        inst.problem = nothing
        inst.type = nothing
        inst.threadid = Threads.threadid()

        # event handling 
        inst.eventInfo = fmi2EventInfo()

        # AD
        inst.output = FMUADOutput{Real}(; initType = Float64)
        inst.eval_output = FMUEvaluationOutput{Float64}()
        inst.rrule_input = FMUEvaluationInput()
        inst.frule_output = FMUEvaluationOutput{Float64}()

        # logging
        inst.loggingOn = false
        inst.visible = false
        inst.instanceName = ""

        # caches
        inst.x = nothing
        inst.x_nominals = nothing
        inst.x_d = nothing
        inst.ẋ = nothing
        inst.ẍ = nothing
        inst.z = nothing
        inst.z_prev = nothing

        inst.values = Dict{fmi2ValueReference,Union{fmi2Real,fmi2Integer,fmi2Boolean}}()
        inst.x_vrs = Array{fmi2ValueReference,1}()
        inst.ẋ_vrs = Array{fmi2ValueReference,1}()
        inst.u_vrs = Array{fmi2ValueReference,1}()
        inst.y_vrs = Array{fmi2ValueReference,1}()
        inst.p_vrs = Array{fmi2ValueReference,1}()

        # sensitivities
        inst.∂ẋ_∂x = nothing
        inst.∂ẋ_∂u = nothing
        inst.∂ẋ_∂p = nothing
        inst.∂ẋ_∂t = nothing

        inst.∂y_∂x = nothing
        inst.∂y_∂u = nothing
        inst.∂y_∂p = nothing
        inst.∂y_∂t = nothing

        inst.∂e_∂x = nothing
        inst.∂e_∂u = nothing
        inst.∂e_∂p = nothing
        inst.∂e_∂t = nothing

        inst.∂xr_∂xl = nothing

        # initialize further variables 
        inst.progressMeter = nothing

        inst.default_t = NO_fmi2Real
        inst.default_p_refs = EMPTY_fmi2ValueReference
        inst.default_p = EMPTY_fmi2Real
        inst.default_x_d = EMPTY_fmi2Real
        inst.default_ec_idcs = EMPTY_fmi2ValueReference
        inst.default_u = EMPTY_fmi2Real
        inst.default_y_refs = EMPTY_fmi2ValueReference
        inst.default_dx_refs = EMPTY_fmi2ValueReference

        inst.default_dx = EMPTY_fmi2Real
        inst.default_y = EMPTY_fmi2Real
        inst.default_ec = EMPTY_fmi2Real

        inst.snapshots = Vector{FMUSnapshot}()
        inst.sampleSnapshot = nothing

        inst.termSim = false

        # performance (pointers to prevent repeating allocations)
        inst._enterEventMode = zeros(fmi2Boolean, 1)
        inst._terminateSimulation = zeros(fmi2Boolean, 1)

        inst._ptr_enterEventMode = pointer(inst._enterEventMode)
        inst._ptr_terminateSimulation = pointer(inst._terminateSimulation)

        return inst
    end

    function FMU2Component(fmu::F) where {F}
        inst = FMU2Component{F}()
        inst.fmu = fmu

        inst.default_t = inst.fmu.default_t
        inst.default_p_refs =
            inst.fmu.default_p_refs === EMPTY_fmi2ValueReference ? inst.fmu.default_p_refs :
            copy(inst.fmu.default_p_refs)
        inst.default_p =
            inst.fmu.default_p === EMPTY_fmi2Real ? inst.fmu.default_p :
            copy(inst.fmu.default_p)
        inst.default_x_d =
            inst.fmu.default_x_d === EMPTY_fmi2Real ? inst.fmu.default_x_d :
            copy(inst.fmu.default_x_d)
        inst.default_ec =
            inst.fmu.default_ec === EMPTY_fmi2Real ? inst.fmu.default_ec :
            copy(inst.fmu.default_ec)
        inst.default_ec_idcs =
            inst.fmu.default_ec_idcs === EMPTY_fmi2ValueReference ?
            inst.fmu.default_ec_idcs : copy(inst.fmu.default_ec_idcs)
        inst.default_u =
            inst.fmu.default_u === EMPTY_fmi2Real ? inst.fmu.default_u :
            copy(inst.fmu.default_u)
        inst.default_y =
            inst.fmu.default_y === EMPTY_fmi2Real ? inst.fmu.default_y :
            copy(inst.fmu.default_y)
        inst.default_y_refs =
            inst.fmu.default_y_refs === EMPTY_fmi2ValueReference ? inst.fmu.default_y_refs :
            copy(inst.fmu.default_y_refs)
        inst.default_dx =
            inst.fmu.default_dx === EMPTY_fmi2Real ? inst.fmu.default_dx :
            copy(inst.fmu.default_dx)
        inst.default_dx_refs =
            inst.fmu.default_dx_refs === EMPTY_fmi2ValueReference ?
            inst.fmu.default_dx_refs : copy(inst.fmu.default_dx_refs)

        # event handling 
        inst.eventIndicatorBuffer =
            zeros(fmi2Real, fmu.modelDescription.numberOfEventIndicators)

        return inst
    end

    function FMU2Component(addr::fmi2Component, fmu::F) where {F}
        inst = FMU2Component(fmu)
        inst.addr = addr

        return inst
    end
end
export FMU2Component

# overloading get/set/haspropoerty for preallocated pointers (buffers for return values)

const FMU2Component_AdditionalFields = (:enterEventMode, :terminateSimulation)

function Base.setproperty!(str::FMU2Component, var::Symbol, value)
    if var ∈ FMU2Component_AdditionalFields
        fname = Symbol("_" * String(var))
        field = Base.getfield(str, fname)
        field[1] = value
        return nothing
    else
        return Base.setfield!(str, var, value)
    end
end

function Base.hasproperty(str::FMU2Component, var::Symbol)
    if var ∈ FMU2Component_AdditionalFields
        return true
    else
        return Base.hasfield(str, var)
    end
end

function Base.getproperty(str::FMU2Component, var::Symbol)
    if var ∈ FMU2Component_AdditionalFields
        fname = Symbol("_" * String(var))
        field = Base.getfield(str, fname)
        return field[1]
    else
        return Base.getfield(str, var)
    end
end

""" 
Overload the Base.show() function for custom printing of the FMU2Component.
"""
Base.show(io::IO, c::FMU2Component) = print(
    io,
    "FMU:            $(c.fmu.modelDescription.modelName)
    InstanceName:   $(isdefined(c, :instanceName) ? c.instanceName : "[not defined]")
    Address:        $(c.addr)
    State:          $(c.state)
    Logging:        $(c.loggingOn)
    FMU time:       $(c.t)
    FMU states:     $(c.x)",
)

"""
The mutable struct representing a FMU (and a container for all its instances) in the FMI 2.0.2 Standard.
Also contains the paths to the FMU and ZIP folder as well als all the FMI 2.0.2 function pointers.
"""
mutable struct FMU2 <: FMU
    modelName::String
    fmuResourceLocation::String
    logLevel::FMULogLevel

    modelDescription::fmi2ModelDescription

    type::fmi2Type
    instances::Vector{FMU2Component}

    # c-functions
    cInstantiate::Ptr{Cvoid}
    cGetTypesPlatform::Ptr{Cvoid}
    cGetVersion::Ptr{Cvoid}
    cFreeInstance::Ptr{Cvoid}
    cSetDebugLogging::Ptr{Cvoid}
    cSetupExperiment::Ptr{Cvoid}
    cEnterInitializationMode::Ptr{Cvoid}
    cExitInitializationMode::Ptr{Cvoid}
    cTerminate::Ptr{Cvoid}
    cReset::Ptr{Cvoid}
    cGetReal::Ptr{Cvoid}
    cSetReal::Ptr{Cvoid}
    cGetInteger::Ptr{Cvoid}
    cSetInteger::Ptr{Cvoid}
    cGetBoolean::Ptr{Cvoid}
    cSetBoolean::Ptr{Cvoid}
    cGetString::Ptr{Cvoid}
    cSetString::Ptr{Cvoid}
    cGetFMUstate::Ptr{Cvoid}
    cSetFMUstate::Ptr{Cvoid}
    cFreeFMUstate::Ptr{Cvoid}
    cSerializedFMUstateSize::Ptr{Cvoid}
    cSerializeFMUstate::Ptr{Cvoid}
    cDeSerializeFMUstate::Ptr{Cvoid}
    cGetDirectionalDerivative::Ptr{Cvoid}

    # Co Simulation function calls
    cSetRealInputDerivatives::Ptr{Cvoid}
    cGetRealOutputDerivatives::Ptr{Cvoid}
    cDoStep::Ptr{Cvoid}
    cCancelStep::Ptr{Cvoid}
    cGetStatus::Ptr{Cvoid}
    cGetRealStatus::Ptr{Cvoid}
    cGetIntegerStatus::Ptr{Cvoid}
    cGetBooleanStatus::Ptr{Cvoid}
    cGetStringStatus::Ptr{Cvoid}

    # Model Exchange function calls
    cEnterContinuousTimeMode::Ptr{Cvoid}
    cGetContinuousStates::Ptr{Cvoid}
    cGetDerivatives::Ptr{Cvoid}
    cSetTime::Ptr{Cvoid}
    cSetContinuousStates::Ptr{Cvoid}
    cCompletedIntegratorStep::Ptr{Cvoid}
    cEnterEventMode::Ptr{Cvoid}
    cNewDiscreteStates::Ptr{Cvoid}
    cGetEventIndicators::Ptr{Cvoid}
    cGetNominalsOfContinuousStates::Ptr{Cvoid}

    # paths of zipped and unzipped FMU folders
    path::String
    binaryPath::String
    zipPath::String

    # execution configuration
    executionConfig::FMUExecutionConfiguration

    # events
    hasStateEvents::Union{Bool,Nothing}
    hasTimeEvents::Union{Bool,Nothing}
    isZeroState::Bool
    isDummyDiscrete::Bool

    # c-libraries
    libHandle::Ptr{Nothing}
    callbackLibHandle::Ptr{Nothing} # for external callbacks
    cFunctionPtrs::Dict{String,Ptr{Nothing}}

    # multi-threading
    threadInstances::Dict{Integer,Union{FMU2Component,Nothing}}

    # indices of event indicators to be handled, if `nothing` all are handled
    handleEventIndicators::Union{Vector{fmi2ValueReference},Nothing}

    # parameters that need sensitivities and/or are catched by optimizers (like in FMIFlux.jl)
    default_t::Real
    default_p_refs::AbstractVector{<:fmi2ValueReference}
    default_p::AbstractVector{<:Real}
    default_x_d::AbstractVector{<:Real}
    default_ec::AbstractVector{<:Real}
    default_ec_idcs::AbstractVector{<:fmi2ValueReference}
    default_dx::AbstractVector{<:Real}
    default_dx_refs::AbstractVector{<:fmi2ValueReference}
    default_u::AbstractVector{<:Real}
    default_y::AbstractVector{<:Real}
    default_y_refs::AbstractVector{<:fmi2ValueReference}

    # Constructor
    function FMU2(logLevel::FMULogLevel = FMULogLevelWarn)
        inst = new()
        inst.instances = Vector{FMU2Component}()
        inst.callbackLibHandle = C_NULL
        inst.modelName = ""
        inst.logLevel = logLevel

        inst.hasStateEvents = nothing
        inst.hasTimeEvents = nothing

        inst.isDummyDiscrete = false

        inst.executionConfig = FMU_EXECUTION_CONFIGURATION_NO_RESET
        inst.threadInstances = Dict{Integer,Union{FMU2Component,Nothing}}()
        inst.cFunctionPtrs = Dict{String,Ptr{Nothing}}()

        inst.handleEventIndicators = nothing

        # parameters that need sensitivities and/or are catched by optimizers (like in FMIFlux.jl)
        inst.default_t = NO_fmi2Real
        inst.default_p_refs = EMPTY_fmi2ValueReference
        inst.default_p = EMPTY_fmi2Real
        inst.default_x_d = EMPTY_fmi2Real
        inst.default_ec = EMPTY_fmi2Real
        inst.default_ec_idcs = EMPTY_fmi2ValueReference
        inst.default_u = EMPTY_fmi2Real
        inst.default_y = EMPTY_fmi2Real
        inst.default_y_refs = EMPTY_fmi2ValueReference
        inst.default_dx = EMPTY_fmi2Real
        inst.default_dx_refs = EMPTY_fmi2ValueReference

        return inst
    end

    # required for creation of FMU layers in Flux.jl
    function FMU2(args...)
        return new(args...)
    end
end
export FMU2

function Base.hasproperty(f::FMU2, var::Symbol)
    if var == :components
        return true
    else
        return Base.hasfield(f, var)
    end
end

function Base.getproperty(f::FMU2, var::Symbol)
    if var == :components
        return Base.getfield(f, :instances)
    else
        return Base.getfield(f, var)
    end
end

function Base.setproperty!(f::FMU2, var::Symbol, val)
    if var == :components
        return Base.setfield!(f, :instances, val)
    else
        return Base.setfield!(f, var, val)
    end
end

""" 
Overload the Base.show() function for custom printing of the FMU2.
"""
function Base.show(io::IO, fmu::FMU2)
    print(io, "Model name:\t$(fmu.modelDescription.modelName)\nType:\t\t$(fmu.type)")
end
