#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

# What is included in this file:
# - the `fmi3InstanceState`-enum which mirrors the internal FMU state (state-machine, not the system state)
# - the `FMU3Instance`-struct 
# - the `FMU3`-struct
# - string/enum-converters for FMI-attribute-structs (e.g. `fmi3StatusToString`, ...)

"""
This is a pointer to a data structure in the importer. Using this pointer, data may be transferred between the importer and callback functions the importer provides with the instantiation functions.

Source: FMISpec 3.0.1 [2.2.3. Platform Dependent Definitions]
"""
mutable struct FMU3InstanceEnvironment
    logStatusOK::Bool
    logStatusWarning::Bool
    logStatusDiscard::Bool
    logStatusError::Bool
    logStatusFatal::Bool

    function FMU3InstanceEnvironment()
        inst = new()
        inst.logStatusOK = true
        inst.logStatusWarning = true
        inst.logStatusDiscard = true
        inst.logStatusError = true
        inst.logStatusFatal = true
        return inst
    end
end
export FMU3InstanceEnvironment

"""
Source: FMISpec3.0, Version D5ef1c1:: 2.2.1. Header Files and Naming of Functions

The mutable struct represents a pointer to an FMU specific data structure that contains the information needed to process the model equations or to process the co-simulation of the model/subsystem represented by the FMU.
"""
mutable struct FMU3Instance{F} <: FMUInstance
    addr::fmi3Instance
    cRef::UInt64

    fmu::F
    state::fmi3InstanceState
    instanceEnvironment::FMU3InstanceEnvironment
    type::Union{fmi3Type,Nothing}

    problem::Any
    solution::FMUSolution
    force::Bool
    threadid::Integer

    loggingOn::Bool
    instanceName::String
    continuousStatesChanged::fmi3Boolean
    visible::Bool

    # caches
    t::fmi3Float64             # the system time
    t_offset::fmi3Float64      # time offset between simulation environment and FMU
    x::Union{Array{fmi3Float64,1},Nothing}   # the system states (or sometimes u)
    x_nominals::Union{Array{fmi3Float64,1},Nothing}   # the system states (or sometimes u)
    x_d::Union{Array{fmi3Float64,1},Nothing} # Union{Array{Union{fmi3Float64,fmi3Int64,fmi3Boolean},1}, Array{fmi3Float64,1}, Nothing}   # the system discrete states, [TODO]: Extend to all data types
    ẋ::Union{Array{fmi3Float64,1},Nothing}   # the system state derivative (or sometimes u̇)
    ẍ::Union{Array{fmi3Float64,1},Nothing}   # the system state second derivative
    #u::Array{fmi3Float64, 1}   # the system inputs
    #y::Array{fmi3Float64, 1}   # the system outputs
    #p::Array{fmi3Float64, 1}   # the system parameters
    z::Union{Array{fmi3Float64,1},Nothing}   # the system event indicators
    z_prev::Union{Nothing,Array{fmi3Float64,1}}   # the last system event indicators

    values::Dict{fmi3ValueReference,Union{fmi3Float64,fmi3Int64,fmi3Boolean}} # [TODO]: Extend to all data types

    x_vrs::Array{fmi3ValueReference,1}   # the system state value references 
    ẋ_vrs::Array{fmi3ValueReference,1}   # the system state derivative value references
    u_vrs::Array{fmi3ValueReference,1}   # the system input value references
    y_vrs::Array{fmi3ValueReference,1}   # the system output value references
    p_vrs::Array{fmi3ValueReference,1}   # the system parameter value references

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

    # misc
    progressMeter::Any           # progress plot
    output::FMUADOutput
    rrule_input::FMUEvaluationInput     # input buffer (for rrules)
    eval_output::FMUEvaluationOutput   # output buffer with multiple arrays that behaves like a single array (to allow for single value return functions, necessary for propper AD)
    frule_output::FMUEvaluationOutput
    eventIndicatorBuffer::AbstractArray{<:fmi3Float64}

    # custom (deprecated)
    rootsFound::Array{fmi3Int32}
    stateEvent::fmi3Boolean
    timeEvent::fmi3Boolean
    stepEvent::fmi3Boolean

    # parameters that need sensitivities and/or are catched by optimizers (like in FMIFlux.jl)
    default_t::Real
    default_p_refs::AbstractVector{<:fmi3ValueReference}
    default_p::AbstractVector{<:Real}
    default_x_d::AbstractVector{<:Real}
    default_ec_idcs::AbstractVector{<:fmi3ValueReference}
    default_dx_refs::AbstractVector{<:fmi3ValueReference}
    default_u::AbstractVector{<:Real}
    default_y_refs::AbstractVector{<:fmi3ValueReference}

    default_dx::AbstractVector{<:Real}
    default_y::AbstractVector{<:Real}
    default_ec::AbstractVector{<:Real}

    # performance (pointers to prevent repeating allocations)
    _enterEventMode::Array{fmi3Boolean,1}
    _discreteStatesNeedUpdate::Array{fmi3Boolean,1}
    _terminateSimulation::Array{fmi3Boolean,1}
    _nominalsOfContinuousStatesChanged::Array{fmi3Boolean,1}
    _valuesOfContinuousStatesChanged::Array{fmi3Boolean,1}
    _nextEventTimeDefined::Array{fmi3Boolean,1}
    _nextEventTime::Array{fmi3Float64,1}

    _ptr_enterEventMode::Ptr{fmi3Boolean}
    _ptr_discreteStatesNeedUpdate::Ptr{fmi3Boolean}
    _ptr_terminateSimulation::Ptr{fmi3Boolean}
    _ptr_nominalsOfContinuousStatesChanged::Ptr{fmi3Boolean}
    _ptr_valuesOfContinuousStatesChanged::Ptr{fmi3Boolean}
    _ptr_nextEventTimeDefined::Ptr{fmi3Boolean}
    _ptr_nextEventTime::Ptr{fmi3Float64}

    # a container for all created snapshots, so that we can properly release them at unload
    snapshots::Vector{FMUSnapshot}
    sampleSnapshot::Union{FMUSnapshot,Nothing} # a snapshot that is (re-)used for sampling 

    termSim::Bool

    # constructor
    function FMU3Instance{F}() where {F}
        inst = new()

        inst.cRef = UInt64(pointer_from_objref(inst))

        inst.state = fmi3InstanceStateInstantiated
        inst.t = NO_fmi3Float64
        inst.t_offset = fmi3Float64(0.0)
        inst.problem = nothing
        inst.type = nothing
        inst.threadid = Threads.threadid()

        # performance (pointers to prevent repeating allocations)
        inst._enterEventMode = zeros(fmi3Boolean, 1)
        inst._discreteStatesNeedUpdate = zeros(fmi3Boolean, 1)
        inst._terminateSimulation = zeros(fmi3Boolean, 1)
        inst._nominalsOfContinuousStatesChanged = zeros(fmi3Boolean, 1)
        inst._valuesOfContinuousStatesChanged = zeros(fmi3Boolean, 1)
        inst._nextEventTimeDefined = zeros(fmi3Boolean, 1)
        inst._nextEventTime = zeros(fmi3Float64, 1)

        inst._ptr_enterEventMode = pointer(inst._enterEventMode)
        inst._ptr_discreteStatesNeedUpdate = pointer(inst._discreteStatesNeedUpdate)
        inst._ptr_terminateSimulation = pointer(inst._terminateSimulation)
        inst._ptr_nominalsOfContinuousStatesChanged =
            pointer(inst._nominalsOfContinuousStatesChanged)
        inst._ptr_valuesOfContinuousStatesChanged =
            pointer(inst._valuesOfContinuousStatesChanged)
        inst._ptr_nextEventTimeDefined = pointer(inst._nextEventTimeDefined)
        inst._ptr_nextEventTime = pointer(inst._nextEventTime)

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

        inst.values = Dict{fmi3ValueReference,Union{fmi3Float64,fmi3Int64,fmi3Boolean}}()
        inst.x_vrs = Array{fmi3ValueReference,1}()
        inst.ẋ_vrs = Array{fmi3ValueReference,1}()
        inst.u_vrs = Array{fmi3ValueReference,1}()
        inst.y_vrs = Array{fmi3ValueReference,1}()
        inst.p_vrs = Array{fmi3ValueReference,1}()

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

        inst.default_t = NO_fmi3Float64
        inst.default_p_refs = EMPTY_fmi3ValueReference
        inst.default_p = EMPTY_fmi3Float64
        inst.default_x_d = EMPTY_fmi3Float64
        inst.default_ec_idcs = EMPTY_fmi3ValueReference
        inst.default_u = EMPTY_fmi3Float64
        inst.default_y_refs = EMPTY_fmi3ValueReference
        inst.default_dx_refs = EMPTY_fmi3ValueReference

        inst.default_dx = EMPTY_fmi3Float64
        inst.default_y = EMPTY_fmi3Float64
        inst.default_ec = EMPTY_fmi3Float64

        inst.snapshots = Vector{FMUSnapshot}()
        inst.sampleSnapshot = nothing

        inst.termSim = false

        return inst
    end

    function FMU3Instance(fmu::F) where {F}
        inst = FMU3Instance{F}()

        inst.fmu = fmu

        inst.default_t = inst.fmu.default_t
        inst.default_p_refs =
            inst.fmu.default_p_refs === EMPTY_fmi3ValueReference ? inst.fmu.default_p_refs :
            copy(inst.fmu.default_p_refs)
        inst.default_p =
            inst.fmu.default_p === EMPTY_fmi3Float64 ? inst.fmu.default_p :
            copy(inst.fmu.default_p)
        inst.default_x_d =
            inst.fmu.default_x_d === EMPTY_fmi3Float64 ? inst.fmu.default_x_d :
            copy(inst.fmu.default_x_d)
        inst.default_ec =
            inst.fmu.default_ec === EMPTY_fmi3Float64 ? inst.fmu.default_ec :
            copy(inst.fmu.default_ec)
        inst.default_ec_idcs =
            inst.fmu.default_ec_idcs === EMPTY_fmi3ValueReference ?
            inst.fmu.default_ec_idcs : copy(inst.fmu.default_ec_idcs)
        inst.default_u =
            inst.fmu.default_u === EMPTY_fmi3Float64 ? inst.fmu.default_u :
            copy(inst.fmu.default_u)
        inst.default_y =
            inst.fmu.default_y === EMPTY_fmi3Float64 ? inst.fmu.default_y :
            copy(inst.fmu.default_y)
        inst.default_y_refs =
            inst.fmu.default_y_refs === EMPTY_fmi3ValueReference ? inst.fmu.default_y_refs :
            copy(inst.fmu.default_y_refs)
        inst.default_dx =
            inst.fmu.default_dx === EMPTY_fmi3Float64 ? inst.fmu.default_dx :
            copy(inst.fmu.default_dx)
        inst.default_dx_refs =
            inst.fmu.default_dx_refs === EMPTY_fmi3ValueReference ?
            inst.fmu.default_dx_refs : copy(inst.fmu.default_dx_refs)

        return inst
    end

    function FMU3Instance(addr::fmi3Instance, fmu::F) where {F}
        inst = FMU3Instance(fmu)
        inst.addr = addr

        return inst
    end

end
export FMU3Instance

# overloading get/set/haspropoerty for preallocated pointers (buffers for return values)

const FMU3Instance_AdditionalFields = (
    :enterEventMode,
    :discreteStatesNeedUpdate,
    :terminateSimulation,
    :nominalsOfContinuousStatesChanged,
    :valuesOfContinuousStatesChanged,
    :nextEventTimeDefined,
    :nextEventTime,
)

function Base.setproperty!(str::FMU3Instance, var::Symbol, value)
    if var ∈ FMU3Instance_AdditionalFields
        fname = Symbol("_" * String(var))
        field = Base.getfield(str, fname)
        field[1] = value
        return nothing
    else
        return Base.setfield!(str, var, value)
    end
end

function Base.hasproperty(str::FMU3Instance, var::Symbol)
    if var ∈ FMU3Instance_AdditionalFields
        return true
    else
        return Base.hasfield(str, var)
    end
end

function Base.getproperty(str::FMU3Instance, var::Symbol)
    if var ∈ FMU3Instance_AdditionalFields
        fname = Symbol("_" * String(var))
        field = Base.getfield(str, fname)
        return field[1]
    else
        return Base.getfield(str, var)
    end
end

""" 
Overload the Base.show() function for custom printing of the FMU3Instance.
"""
Base.show(io::IO, c::FMU3Instance) = print(
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
Source: FMISpec3.0, Version D5ef1c1: 2.2.1. Header Files and Naming of Functions

The mutable struct representing an FMU in the FMI 3.0 Standard.
Also contains the paths to the FMU and ZIP folder as well als all the FMI 3.0 function pointers
"""
mutable struct FMU3 <: FMU
    modelName::String
    fmuResourceLocation::String
    logLevel::FMULogLevel

    modelDescription::fmi3ModelDescription

    type::fmi3Type
    instances::Vector{FMU3Instance}

    # c-functions
    cInstantiateModelExchange::Ptr{Cvoid}
    cInstantiateCoSimulation::Ptr{Cvoid}
    cInstantiateScheduledExecution::Ptr{Cvoid}

    cGetVersion::Ptr{Cvoid}
    cFreeInstance::Ptr{Cvoid}
    cSetDebugLogging::Ptr{Cvoid}
    cEnterConfigurationMode::Ptr{Cvoid}
    cExitConfigurationMode::Ptr{Cvoid}
    cEnterInitializationMode::Ptr{Cvoid}
    cExitInitializationMode::Ptr{Cvoid}
    cTerminate::Ptr{Cvoid}
    cReset::Ptr{Cvoid}
    cGetFloat32::Ptr{Cvoid}
    cSetFloat32::Ptr{Cvoid}
    cGetFloat64::Ptr{Cvoid}
    cSetFloat64::Ptr{Cvoid}
    cGetInt8::Ptr{Cvoid}
    cSetInt8::Ptr{Cvoid}
    cGetUInt8::Ptr{Cvoid}
    cSetUInt8::Ptr{Cvoid}
    cGetInt16::Ptr{Cvoid}
    cSetInt16::Ptr{Cvoid}
    cGetUInt16::Ptr{Cvoid}
    cSetUInt16::Ptr{Cvoid}
    cGetInt32::Ptr{Cvoid}
    cSetInt32::Ptr{Cvoid}
    cGetUInt32::Ptr{Cvoid}
    cSetUInt32::Ptr{Cvoid}
    cGetInt64::Ptr{Cvoid}
    cSetInt64::Ptr{Cvoid}
    cGetUInt64::Ptr{Cvoid}
    cSetUInt64::Ptr{Cvoid}
    cGetBoolean::Ptr{Cvoid}
    cSetBoolean::Ptr{Cvoid}
    cGetString::Ptr{Cvoid}
    cSetString::Ptr{Cvoid}
    cGetBinary::Ptr{Cvoid}
    cSetBinary::Ptr{Cvoid}
    cGetFMUState::Ptr{Cvoid}
    cSetFMUState::Ptr{Cvoid}
    cFreeFMUState::Ptr{Cvoid}
    cSerializedFMUStateSize::Ptr{Cvoid}
    cSerializeFMUState::Ptr{Cvoid}
    cDeSerializeFMUState::Ptr{Cvoid}
    cGetDirectionalDerivative::Ptr{Cvoid}
    cGetAdjointDerivative::Ptr{Cvoid}
    cEvaluateDiscreteStates::Ptr{Cvoid}
    cGetNumberOfVariableDependencies::Ptr{Cvoid}
    cGetVariableDependencies::Ptr{Cvoid}

    # Co Simulation function calls
    cGetOutputDerivatives::Ptr{Cvoid}
    cEnterStepMode::Ptr{Cvoid}
    cDoStep::Ptr{Cvoid}

    # Model Exchange function calls
    cGetNumberOfContinuousStates::Ptr{Cvoid}
    cGetNumberOfEventIndicators::Ptr{Cvoid}
    cGetContinuousStates::Ptr{Cvoid}
    cGetNominalsOfContinuousStates::Ptr{Cvoid}
    cEnterContinuousTimeMode::Ptr{Cvoid}
    cSetTime::Ptr{Cvoid}
    cSetContinuousStates::Ptr{Cvoid}
    cGetContinuousStateDerivatives::Ptr{Cvoid}
    cGetEventIndicators::Ptr{Cvoid}
    cCompletedIntegratorStep::Ptr{Cvoid}
    cEnterEventMode::Ptr{Cvoid}
    cUpdateDiscreteStates::Ptr{Cvoid}

    # Scheduled Execution function calls
    cSetIntervalDecimal::Ptr{Cvoid}
    cSetIntervalFraction::Ptr{Cvoid}
    cGetIntervalDecimal::Ptr{Cvoid}
    cGetIntervalFraction::Ptr{Cvoid}
    cGetShiftDecimal::Ptr{Cvoid}
    cGetShiftFraction::Ptr{Cvoid}
    cActivateModelPartition::Ptr{Cvoid}

    # paths of ziped and unziped FMU folders
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
    # [Note] no callbackLibHandle in FMI3
    cFunctionPtrs::Dict{String,Ptr{Nothing}}

    # multi-threading
    threadInstances::Dict{Integer,Union{FMU3Instance,Nothing}}

    # indices of event indicators to be handled, if `nothing` all are handled
    handleEventIndicators::Union{Vector{fmi3ValueReference},Nothing}

    # parameters that need sensitivities and/or are catched by optimizers (like in FMIFlux.jl)
    default_t::Real
    default_p_refs::AbstractVector{<:fmi3ValueReference}
    default_p::AbstractVector{<:Real}
    default_x_d::AbstractVector{<:Real}
    default_ec::AbstractVector{<:Real}
    default_ec_idcs::AbstractVector{<:fmi3ValueReference}
    default_dx::AbstractVector{<:Real}
    default_dx_refs::AbstractVector{<:fmi3ValueReference}
    default_u::AbstractVector{<:Real}
    default_y::AbstractVector{<:Real}
    default_y_refs::AbstractVector{<:fmi3ValueReference}

    # Constructor
    function FMU3(logLevel::FMULogLevel = FMULogLevelWarn)
        inst = new()

        inst.modelName = ""
        inst.fmuResourceLocation = ""
        inst.logLevel = logLevel

        inst.instances = []

        inst.hasStateEvents = nothing
        inst.hasTimeEvents = nothing

        inst.isDummyDiscrete = false

        inst.executionConfig = FMU_EXECUTION_CONFIGURATION_NO_RESET
        inst.threadInstances = Dict{Integer,Union{FMU2Component,Nothing}}()
        inst.cFunctionPtrs = Dict{String,Ptr{Nothing}}()

        inst.handleEventIndicators = nothing

        # parameters that need sensitivities and/or are catched by optimizers (like in FMIFlux.jl)
        inst.default_t = NO_fmi3Float64
        inst.default_p_refs = EMPTY_fmi3ValueReference
        inst.default_p = EMPTY_fmi3Float64
        inst.default_x_d = EMPTY_fmi3Float64
        inst.default_ec = EMPTY_fmi3Float64
        inst.default_ec_idcs = EMPTY_fmi3ValueReference
        inst.default_u = EMPTY_fmi3Float64
        inst.default_y = EMPTY_fmi3Float64
        inst.default_y_refs = EMPTY_fmi3ValueReference
        inst.default_dx = EMPTY_fmi3Float64
        inst.default_dx_refs = EMPTY_fmi3ValueReference

        # c-functions
        inst.cInstantiateModelExchange = C_NULL
        inst.cInstantiateCoSimulation = C_NULL
        inst.cInstantiateScheduledExecution = C_NULL

        inst.cGetVersion = C_NULL
        inst.cFreeInstance = C_NULL
        inst.cSetDebugLogging = C_NULL
        inst.cEnterConfigurationMode = C_NULL
        inst.cExitConfigurationMode = C_NULL
        inst.cEnterInitializationMode = C_NULL
        inst.cExitInitializationMode = C_NULL
        inst.cTerminate = C_NULL
        inst.cReset = C_NULL
        inst.cGetFloat32 = C_NULL
        inst.cSetFloat32 = C_NULL
        inst.cGetFloat64 = C_NULL
        inst.cSetFloat64 = C_NULL
        inst.cGetInt8 = C_NULL
        inst.cSetInt8 = C_NULL
        inst.cGetUInt8 = C_NULL
        inst.cSetUInt8 = C_NULL
        inst.cGetInt16 = C_NULL
        inst.cSetInt16 = C_NULL
        inst.cGetUInt16 = C_NULL
        inst.cSetUInt16 = C_NULL
        inst.cGetInt32 = C_NULL
        inst.cSetInt32 = C_NULL
        inst.cGetUInt32 = C_NULL
        inst.cSetUInt32 = C_NULL
        inst.cGetInt64 = C_NULL
        inst.cSetInt64 = C_NULL
        inst.cGetUInt64 = C_NULL
        inst.cSetUInt64 = C_NULL
        inst.cGetBoolean = C_NULL
        inst.cSetBoolean = C_NULL
        inst.cGetString = C_NULL
        inst.cSetString = C_NULL
        inst.cGetBinary = C_NULL
        inst.cSetBinary = C_NULL
        inst.cGetFMUState = C_NULL
        inst.cSetFMUState = C_NULL
        inst.cFreeFMUState = C_NULL
        inst.cSerializedFMUStateSize = C_NULL
        inst.cSerializeFMUState = C_NULL
        inst.cDeSerializeFMUState = C_NULL
        inst.cGetDirectionalDerivative = C_NULL
        inst.cGetAdjointDerivative = C_NULL
        inst.cEvaluateDiscreteStates = C_NULL
        inst.cGetNumberOfVariableDependencies = C_NULL
        inst.cGetVariableDependencies = C_NULL

        # Co Simulation function calls
        inst.cGetOutputDerivatives = C_NULL
        inst.cEnterStepMode = C_NULL
        inst.cDoStep = C_NULL

        # Model Exchange function calls
        inst.cGetNumberOfContinuousStates = C_NULL
        inst.cGetNumberOfEventIndicators = C_NULL
        inst.cGetContinuousStates = C_NULL
        inst.cGetNominalsOfContinuousStates = C_NULL
        inst.cEnterContinuousTimeMode = C_NULL
        inst.cSetTime = C_NULL
        inst.cSetContinuousStates = C_NULL
        inst.cGetContinuousStateDerivatives = C_NULL
        inst.cGetEventIndicators = C_NULL
        inst.cCompletedIntegratorStep = C_NULL
        inst.cEnterEventMode = C_NULL
        inst.cUpdateDiscreteStates = C_NULL

        # Scheduled Execution function calls
        inst.cSetIntervalDecimal = C_NULL
        inst.cSetIntervalFraction = C_NULL
        inst.cGetIntervalDecimal = C_NULL
        inst.cGetIntervalFraction = C_NULL
        inst.cGetShiftDecimal = C_NULL
        inst.cGetShiftFraction = C_NULL
        inst.cActivateModelPartition = C_NULL

        return inst
    end
end
export FMU3

""" Overload the Base.show() function for custom printing of the FMU3"""
Base.show(io::IO, fmu::FMU3) = print(
    io,
    "Model name:       $(fmu.modelName)
    Type:              $(fmu.type)",
)
