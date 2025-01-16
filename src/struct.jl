#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

"""

    FMU 

The abstract type for FMUs (FMI 2 & 3).
"""
abstract type FMU end
export FMU

"""

    FMUInstance 

An instance of a FMU. This was called `component` in FMI2, but was corrected to `instance` in FMI3.
"""
abstract type FMUInstance end
export FMUInstance

"""
A mutable struct representing the excution configuration of a FMU.
For FMUs that have issues with calls like `fmi2Reset` or `fmi2FreeInstance`, this is pretty useful.

# Fields
- `terminate::Bool`: Call `fmi2Terminate` before every training step/simulation.
- `reset::Bool`: Call `fmi2Reset` before every training step/simulation.
- `setup::Bool`: Call setup functions before every training step/simulation.
- `instantiate::Bool`: Call `fmi2Instantiate` before every training step/simulation.
- `freeInstance::Bool`: Call `fmi2FreeInstance` after every training step/simulation.
- `loggingOn::Bool`: Enable or disable logging.
- `externalCallbacks::Bool`: Use external callbacks.
- `force::Bool`: Default value for forced actions.
- `handleStateEvents::Bool`: Handle state events during simulation/training.
- `handleTimeEvents::Bool`: Handle time events during simulation/training.
- `assertOnError::Bool`: Whether an exception is thrown if a `fmi2XXX` command fails (>= `fmi2StatusError`).
- `assertOnWarning::Bool`: Whether an exception is thrown if a `fmi2XXX` command warns (>= `fmi2StatusWarning`).
- `autoTimeShift::Bool`: Whether to shift all time-related functions for simulation intervals not starting at 0.0.
- `inplace_eval::Bool`: Whether FMU/Component evaluation should happen in place.
- `sensealg::Any`: Algorithm for sensitivity estimation over solve call ([ToDo] Datatype/Nothing).
- `rootSearchInterpolationPoints::UInt`: Number of root search interpolation points.
- `useVectorCallbacks::Bool`: Whether to use vector (faster) or scalar (slower) callbacks.
- `maxNewDiscreteStateCalls::UInt`: Max calls for `fmi2NewDiscreteStates` before throwing an exception.
- `maxStateEventsPerSecond::UInt`: Max state events allowed to occur per second (more is interpreted as event chattering).
- `snapshotDeltaTimeTolerance::Float64`: Distance to distinguish between snapshots.
- `eval_t_gradients::Bool`: If time gradients ∂ẋ/∂t and ∂y/∂t should be sampled (not part of the FMI standard).
- `JVPBuiltInDerivatives::Bool`: Use built-in directional derivatives for JVP-sensitivities over FMU without caching the Jacobian (because this is done in the FMU, but not per default).
- `VJPBuiltInDerivatives::Bool`: Use built-in adjoint derivatives for VJP-sensitivities over FMU without caching the Jacobian (because this is done in the FMU, but not per default).
- `sensitivity_strategy::Symbol`: Build-up strategy for Jacobians/gradients, available options are `:FMIDirectionalDerivative`, `:FMIAdjointDerivative`, `:FiniteDiff`.
- `set_p_every_step::Bool`: Whether parameters are set for every simulation step - this is uncommon, because parameters are often set just one time: during/after initialization.
- `concat_eval::Bool`: (Deprecated) Whether FMU/Component evaluation should return a tuple `(y, dx, ec)` or a concatenation `[y..., dx..., ec...]`.
"""
mutable struct FMUExecutionConfiguration
    terminate::Bool     # call fmi2Terminate before every training step / simulation
    reset::Bool         # call fmi2Reset before every training step / simulation
    setup::Bool         # call setup functions before every training step / simulation
    instantiate::Bool   # call fmi2Instantiate before every training step / simulation
    freeInstance::Bool  # call fmi2FreeInstance after every training step / simulation

    loggingOn::Bool
    externalCallbacks::Bool

    force::Bool     # default value for forced actions

    handleStateEvents::Bool                 # handle state events during simulation/training
    handleTimeEvents::Bool                  # handle time events during simulation/training

    assertOnError::Bool                     # wheter an exception is thrown if a fmi2XXX-command fails (>= fmi2StatusError)
    assertOnWarning::Bool                   # wheter an exception is thrown if a fmi2XXX-command warns (>= fmi2StatusWarning)

    autoTimeShift::Bool                     # wheter to shift all time-related functions for simulation intervals not starting at 0.0
    inplace_eval::Bool                      # wheter FMU/Component evaluation should happen in place

    sensealg::Any                                # algorithm for sensitivity estimation over solve call ([ToDo] Datatype/Nothing)
    rootSearchInterpolationPoints::UInt     # number of root search interpolation points
    useVectorCallbacks::Bool                # whether to vector (faster) or scalar (slower) callbacks

    maxNewDiscreteStateCalls::UInt          # max calls for fmi2NewDiscreteStates before throwing an exception
    maxStateEventsPerSecond::UInt           # max state events allowed to occur per second (more is interpreted as event chattering)
    snapshotDeltaTimeTolerance::Float64     # distance to distinguish between snapshots

    eval_t_gradients::Bool                  # if time gradients ∂ẋ_∂t and ∂y_∂t should be sampled (not part of the FMI standard)
    JVPBuiltInDerivatives::Bool             # use built-in directional derivatives for JVP-sensitivities over FMU without caching the jacobian (because this is done in the FMU, but not per default)
    VJPBuiltInDerivatives::Bool             # use built-in adjoint derivatives for VJP-sensitivities over FMU without caching the jacobian (because this is done in the FMU, but not per default)

    sensitivity_strategy::Symbol            # build up strategy for jacobians/gradients, available is `:FMIDirectionalDerivative`, `:FMIAdjointDerivative`, `:FiniteDiff`

    set_p_every_step::Bool                  # whether parameters are set for every simulation step - this is uncommon, because parameters are (often) set just one time: during/after intialization

    # deprecated 
    concat_eval::Bool                       # wheter FMU/Component evaluation should return a tuple (y, dx, ec) or a conacatenation [y..., dx..., ec...]
    isolatedStateDependency::Any

    function FMUExecutionConfiguration()
        inst = new()

        inst.terminate = true
        inst.reset = true
        inst.setup = true
        inst.instantiate = false
        inst.freeInstance = false

        inst.force = false

        inst.loggingOn = false
        inst.externalCallbacks = true

        inst.handleStateEvents = true
        inst.handleTimeEvents = true

        inst.assertOnError = false
        inst.assertOnWarning = false

        inst.autoTimeShift = false

        inst.sensealg = nothing # auto

        inst.rootSearchInterpolationPoints = 10
        inst.useVectorCallbacks = true

        inst.maxNewDiscreteStateCalls = 100
        inst.maxStateEventsPerSecond = 100
        inst.snapshotDeltaTimeTolerance = 1e-8

        inst.eval_t_gradients = false
        inst.JVPBuiltInDerivatives = false
        inst.VJPBuiltInDerivatives = false
        inst.sensitivity_strategy = :FMIDirectionalDerivative

        inst.set_p_every_step = false

        # deprecated 
        inst.concat_eval = true
        inst.isolatedStateDependency = false

        return inst
    end
end
export FMUExecutionConfiguration

# default for a "healthy" FMU - this is the fastetst 
FMU_EXECUTION_CONFIGURATION_RESET = FMUExecutionConfiguration()
FMU_EXECUTION_CONFIGURATION_RESET.terminate = true
FMU_EXECUTION_CONFIGURATION_RESET.reset = true
FMU_EXECUTION_CONFIGURATION_RESET.setup = true
FMU_EXECUTION_CONFIGURATION_RESET.instantiate = false
FMU_EXECUTION_CONFIGURATION_RESET.freeInstance = false
export FMU_EXECUTION_CONFIGURATION_RESET

# if your FMU has a problem with "fmi2Reset" - this is default
FMU_EXECUTION_CONFIGURATION_NO_RESET = FMUExecutionConfiguration()
FMU_EXECUTION_CONFIGURATION_NO_RESET.terminate = false
FMU_EXECUTION_CONFIGURATION_NO_RESET.reset = false
FMU_EXECUTION_CONFIGURATION_NO_RESET.setup = true
FMU_EXECUTION_CONFIGURATION_NO_RESET.instantiate = true
FMU_EXECUTION_CONFIGURATION_NO_RESET.freeInstance = true
export FMU_EXECUTION_CONFIGURATION_NO_RESET

# if your FMU has a problem with "fmi2Reset" and "fmi2FreeInstance" - this is for weak FMUs (but slower)
FMU_EXECUTION_CONFIGURATION_NO_FREEING = FMUExecutionConfiguration()
FMU_EXECUTION_CONFIGURATION_NO_FREEING.terminate = false
FMU_EXECUTION_CONFIGURATION_NO_FREEING.reset = false
FMU_EXECUTION_CONFIGURATION_NO_FREEING.setup = true
FMU_EXECUTION_CONFIGURATION_NO_FREEING.instantiate = true
FMU_EXECUTION_CONFIGURATION_NO_FREEING.freeInstance = false
export FMU_EXECUTION_CONFIGURATION_NO_FREEING

# do nothing, this is useful e.g. for set/get state applications
FMU_EXECUTION_CONFIGURATION_NOTHING = FMUExecutionConfiguration()
FMU_EXECUTION_CONFIGURATION_NOTHING.terminate = false
FMU_EXECUTION_CONFIGURATION_NOTHING.reset = false
FMU_EXECUTION_CONFIGURATION_NOTHING.setup = false
FMU_EXECUTION_CONFIGURATION_NOTHING.instantiate = false
FMU_EXECUTION_CONFIGURATION_NOTHING.freeInstance = false
export FMU_EXECUTION_CONFIGURATION_NOTHING

FMU_EXECUTION_CONFIGURATIONS = (
    FMU_EXECUTION_CONFIGURATION_NO_FREEING,
    FMU_EXECUTION_CONFIGURATION_NO_RESET,
    FMU_EXECUTION_CONFIGURATION_RESET,
    FMU_EXECUTION_CONFIGURATION_NOTHING,
)
export FMU_EXECUTION_CONFIGURATIONS

"""
 ToDo 
"""
mutable struct FMUSnapshot{E,C,D,I,S}

    t::Float64
    eventInfo::E
    state::UInt32
    instance::I
    fmuState::Union{S,Nothing}
    x_c::C
    x_d::D

    function FMUSnapshot{E,C,D,I,S}() where {E,C,D,I,S}
        inst = new{E,C,D,I,S}()
        inst.fmuState = nothing
        return inst
    end

    function FMUSnapshot(c::FMUInstance)

        t = c.t
        eventInfo = deepcopy(c.eventInfo)
        state = c.state
        instance = c
        fmuState = getFMUstate(c)
        #x_c = isnothing(c.x  ) ? nothing : copy(c.x  ) 
        #x_d = isnothing(c.x_d) ? nothing : copy(c.x_d)

        n_x_c = Csize_t(length(c.fmu.modelDescription.stateValueReferences))
        x_c = zeros(Float64, n_x_c)
        fmi2GetContinuousStates!(c.fmu.cGetContinuousStates, c.addr, x_c, n_x_c)
        x_d = nothing # ToDo

        E = typeof(eventInfo)
        C = typeof(x_c)
        D = typeof(x_d)
        I = typeof(instance)
        S = typeof(fmuState)

        inst = new{E,C,D,I,S}(t, eventInfo, state, instance, fmuState, x_c, x_d)

        # if !isnothing(fmuState)
        #     inst = finalizer((_inst) -> cleanup!(c, _inst), inst)
        # end

        push!(c.snapshots, inst)

        return inst
    end

end
export FMUSnapshot

function Base.show(io::IO, s::FMUSnapshot)
    print(io, "FMUSnapshot(t=$(s.t), x_c=$(s.x_c), x_d=$(s.x_d), fmuState=$(s.fmuState))")
end

"""
    FMUInputFunction(inputFunction, vrs)

Struct container for inplace input functions for FMUs.

# Arguments
- `inputFunction`: The input function (inplace) that gets called when new inputs are needed, must match one of the patterns described under *Input function patterns*.
- `vrs::AbstractVector`: A vector of value refernces to be set by the input function

## Input function patterns
Available input patterns are [`c`: current component, `u`: current state ,`t`: current time, returning array of values to be passed to `fmi2SetReal(..., inputValueReferences, inputFunction(...))` or `fmi3SetFloat64`]:
- `inputFunction(t::Real, u::AbstractVector{<:Real})`
- `inputFunction(c::Union{FMUInstance, Nothing}, t::Real, u::AbstractVector{<:Real})`
- `inputFunction(c::Union{FMUInstance, Nothing}, x::AbstractVector{<:Real}, u::AbstractVector{<:Real})`
- `inputFunction(x::AbstractVector{<:Real}, t::Real, u::AbstractVector{<:Real})`
- `inputFunction(c::Union{FMUInstance, Nothing}, x::AbstractVector{<:Real}, t::Real, u::AbstractVector{<:Real})`
"""
struct FMUInputFunction{F,T,V}
    fct!::F
    vrs::Vector{<:V}
    buffer::Vector{<:T}

    function FMUInputFunction{T}(fct, vrs::Vector{<:V}) where {T,V}
        buffer = zeros(T, length(vrs))

        _fct = nothing

        if hasmethod(fct, Tuple{T,AbstractVector{<:T}})
            _fct = (c, x, t, u) -> fct(t, u)
        elseif hasmethod(fct, Tuple{Union{FMUInstance,Nothing},T,AbstractVector{<:T}})
            _fct = (c, x, t, u) -> fct(c, t, u)
        elseif hasmethod(
            fct,
            Tuple{Union{FMUInstance,Nothing},AbstractVector{<:T},AbstractVector{<:T}},
        )
            _fct = (c, x, t, u) -> fct(c, x, u)
        elseif hasmethod(fct, Tuple{AbstractVector{<:T},T,AbstractVector{<:T}})
            _fct = (c, x, t, u) -> fct(x, t, u)
        else
            _fct = fct
        end
        @assert hasmethod(
            _fct,
            Tuple{FMU2Component,Union{AbstractArray{<:T,1},Nothing},T,AbstractArray{<:T,1}},
        ) "The given input function does not fit the needed input function pattern for FMUs, which are: \n- `inputFunction!(t::T, u::AbstractArray{<:T})`\n- `inputFunction!(comp::FMU2Component, t::T, u::AbstractArray{<:T})`\n- `inputFunction!(comp::FMU2Component, x::Union{AbstractArray{<:T,1}, Nothing}, u::AbstractArray{<:T})`\n- `inputFunction!(x::Union{AbstractArray{<:T,1}, Nothing}, t::T, u::AbstractArray{<:T})`\n- `inputFunction!(comp::FMU2Component, x::Union{AbstractArray{<:T,1}, Nothing}, t::T, u::AbstractArray{<:T})`\nwhere T=$(T)"

        return new{typeof(_fct),T,V}(_fct, vrs, buffer)
    end

    function FMUInputFunction(fct, vrs::Vector{<:V}) where {V}
        return FMUInputFunction{Float64}(fct, vrs)
    end
end
export FMUInputFunction

"""
    ToDo: Doc String 
"""
function eval!(ipf::FMUInputFunction, c, x, t)
    ipf.fct!(c, x, t, ipf.buffer)
    return ipf.buffer
end

"""
Container for event related information.
"""
struct FMUEvent{T}
    t::T                                        # event time point
    indicator::UInt                                 # index of event indicator ("0" for time events)

    x_left::Union{Array{T,1},Nothing}       # state before the event
    x_right::Union{Array{T,1},Nothing}      # state after the event (if discontinuous)

    indicatorValue::Union{T,Nothing}         # value of the event indicator that triggered the event (should be really close to zero)

    function FMUEvent(
        t::T,
        indicator::UInt = 0,
        x_left::Union{Array{T,1},Nothing} = nothing,
        x_right::Union{Array{T,1},Nothing} = nothing,
        indicatorValue::Union{T,Nothing} = nothing,
    ) where {T}
        inst = new{T}(t, indicator, x_left, x_right, indicatorValue)
        return inst
    end
end
export FMUEvent

# overload the Base.show() function for custom printing of the FMU2.
function Base.show(io::IO, e::FMUEvent)
    timeEvent = (e.indicator == 0)
    stateChange = (e.x_left != e.x_right)
    if timeEvent
        print(io, "Time-Event @ $(e.t)s (state-change: $(stateChange))")
    else
        print(io, "State-Event #$(e.indicator) @ $(e.t)s (state-change: $(stateChange))")
    end
end

""" 
The mutable struct representing a specific Solution of a FMI2 FMU.
"""
mutable struct FMUSolution{C}
    instance::C # FMU2Component
    snapshots::Vector{FMUSnapshot}
    success::Bool

    states::Any                                          # ToDo: ODESolution 

    values::Any                                          # ToDo: DataType
    valueReferences::Union{Array,Nothing}          # ToDo: Array{fmi2ValueReference}

    # record events
    events::Vector{FMUEvent}

    # record event indicators
    recordEventIndicators::Union{Vector{Int},Nothing}
    eventIndicators::Any                                 # ToDo: DataType

    # record eigenvalues 
    eigenvalues::Any                                     # ToDo: DataType

    evals_∂ẋ_∂x::Integer
    evals_∂y_∂x::Integer
    evals_∂e_∂x::Integer
    evals_∂ẋ_∂u::Integer
    evals_∂y_∂u::Integer
    evals_∂e_∂u::Integer
    evals_∂ẋ_∂t::Integer
    evals_∂y_∂t::Integer
    evals_∂e_∂t::Integer
    evals_∂ẋ_∂p::Integer
    evals_∂y_∂p::Integer
    evals_∂e_∂p::Integer
    evals_∂xr_∂xl::Integer

    evals_fx_inplace::Integer
    evals_fx_outofplace::Integer
    evals_condition::Integer
    evals_affect::Integer
    evals_stepcompleted::Integer
    evals_timechoice::Integer
    evals_savevalues::Integer
    evals_saveeventindicators::Integer
    evals_saveeigenvalues::Integer

    function FMUSolution{C}() where {C}
        inst = new{C}()

        inst.snapshots = Vector{FMUSnapshot}(undef, 0)
        inst.success = false
        inst.states = nothing
        inst.values = nothing
        inst.valueReferences = nothing

        inst.events = Vector{FMUEvent}(undef, 0)

        inst.recordEventIndicators = nothing
        inst.eigenvalues = nothing

        inst.evals_∂ẋ_∂x = 0
        inst.evals_∂y_∂x = 0
        inst.evals_∂e_∂x = 0
        inst.evals_∂ẋ_∂u = 0
        inst.evals_∂y_∂u = 0
        inst.evals_∂e_∂u = 0
        inst.evals_∂ẋ_∂t = 0
        inst.evals_∂y_∂t = 0
        inst.evals_∂e_∂t = 0
        inst.evals_∂ẋ_∂p = 0
        inst.evals_∂y_∂p = 0
        inst.evals_∂e_∂p = 0
        inst.evals_∂xr_∂xl = 0

        inst.evals_fx_inplace = 0
        inst.evals_fx_outofplace = 0
        inst.evals_condition = 0
        inst.evals_affect = 0
        inst.evals_stepcompleted = 0
        inst.evals_timechoice = 0
        inst.evals_savevalues = 0
        inst.evals_saveeventindicators = 0
        inst.evals_saveeigenvalues = 0

        return inst
    end

    function FMUSolution(instance::C) where {C}
        inst = FMUSolution{C}()
        inst.instance = instance

        return inst
    end
end
export FMUSolution

""" 
Overload the Base.show() function for custom printing of the FMU2.
"""
function Base.show(io::IO, sol::FMUSolution)
    print(
        io,
        "Model name:\n\t$(sol.instance.fmu.modelDescription.modelName)\nSuccess:\n\t$(sol.success)\n",
    )

    print(io, "f(x)-Evaluations:\n")
    print(io, "\tIn-place: $(sol.evals_fx_inplace)\n")
    print(io, "\tOut-of-place: $(sol.evals_fx_outofplace)\n")
    print(io, "Jacobian-Evaluations:\n")
    print(io, "\t∂ẋ_∂p: $(sol.evals_∂ẋ_∂p)\n")
    print(io, "\t∂ẋ_∂x: $(sol.evals_∂ẋ_∂x)\n")
    print(io, "\t∂ẋ_∂u: $(sol.evals_∂ẋ_∂u)\n")
    print(io, "\t∂y_∂p: $(sol.evals_∂y_∂p)\n")
    print(io, "\t∂y_∂x: $(sol.evals_∂y_∂x)\n")
    print(io, "\t∂y_∂u: $(sol.evals_∂y_∂u)\n")
    print(io, "\t∂e_∂p: $(sol.evals_∂e_∂p)\n")
    print(io, "\t∂e_∂x: $(sol.evals_∂e_∂x)\n")
    print(io, "\t∂e_∂u: $(sol.evals_∂e_∂u)\n")
    print(io, "\t∂xr_∂xl: $(sol.evals_∂xr_∂xl)\n")
    print(io, "Gradient-Evaluations:\n")
    print(io, "\t∂ẋ_∂t: $(sol.evals_∂ẋ_∂t)\n")
    print(io, "\t∂y_∂t: $(sol.evals_∂y_∂t)\n")
    print(io, "\t∂e_∂t: $(sol.evals_∂e_∂t)\n")
    print(io, "Callback-Evaluations:\n")
    print(io, "\tCondition (event-indicators): $(sol.evals_condition)\n")
    print(io, "\tTime-Choice (event-instances): $(sol.evals_timechoice)\n")
    print(io, "\tAffect (event-handling): $(sol.evals_affect)\n")
    print(io, "\tSave values: $(sol.evals_savevalues)\n")
    print(io, "\tSteps completed: $(sol.evals_stepcompleted)\n")

    if !isnothing(sol.states)
        print(io, "States [$(length(sol.states))]:\n")
        if length(sol.states.u) > 10
            for i = 1:9
                print(io, "\t$(sol.states.t[i])\t$(sol.states.u[i])\n")
            end
            print(io, "\t...\n\t$(sol.states.t[end])\t$(sol.states.u[end])\n")
        else
            for i = 1:length(sol.states)
                print(io, "\t$(sol.states.t[i])\t$(sol.states.u[i])\n")
            end
        end
    end

    if !isnothing(sol.values)
        print(io, "Values [$(length(sol.values.saveval))]:\n")
        if length(sol.values.saveval) > 10
            for i = 1:9
                print(io, "\t$(sol.values.t[i])\t$(sol.values.saveval[i])\n")
            end
            print(io, "\t...\n\t$(sol.values.t[end])\t$(sol.values.saveval[end])\n")
        else
            for i = 1:length(sol.values.saveval)
                print(io, "\t$(sol.values.t[i])\t$(sol.values.saveval[i])\n")
            end
        end
    end

    if !isnothing(sol.events)
        print(io, "Events [$(length(sol.events))]:\n")
        if length(sol.events) > 10
            for i = 1:9
                print(io, "\t$(sol.events[i])\n")
            end
            print(io, "\t...\n\t$(sol.events[end])\n")
        else
            for i = 1:length(sol.events)
                print(io, "\t$(sol.events[i])\n")
            end
        end
    end

end

"""
    ToDo: Doc String 
"""
function hasCurrentInstance(fmu::FMU)
    tid = Threads.threadid()
    return haskey(fmu.threadInstances, tid) && !isnothing(fmu.threadInstances[tid])
end
export hasCurrentInstance

"""
    ToDo: Doc String 
"""
function getCurrentInstance(fmu::FMU)
    tid = Threads.threadid()
    @assert hasCurrentInstance(fmu) [
        "No FMU instance allocated (in current thread with ID `$(tid)`), have you already called `fmiXInstantiate!`?",
    ]
    return fmu.threadInstances[tid]
end
export getCurrentInstance
