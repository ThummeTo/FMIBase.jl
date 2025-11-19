#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

"""
ToDo
"""
function setReal(
    c::FMU2Component,
    refs::AbstractArray{<:fmi2ValueReference},
    vals::AbstractArray{<:fmi2Real};
    kwargs...,
)
    fmi2SetReal(c, refs, vals; kwargs...)
    return nothing
end
function setReal(
    c::FMU3Instance,
    refs::AbstractArray{<:fmi3ValueReference},
    vals::AbstractArray{<:fmi3Float64};
    kwargs...,
)
    fmi3SetFloat64(c, refs, vals; kwargs...)
    return nothing
end

"""
ToDo
"""
function getReal(c::FMU2Component, refs::AbstractArray{<:fmi2ValueReference})
    nv = Csize_t(length(refs))
    v = zeros(fmi2Real, nv)
    fmi2GetReal!(c, refs, nv, v)
    return v
end
function getReal(c::FMU3Instance, refs::AbstractArray{<:fmi3ValueReference})
    nv = Csize_t(length(refs))
    v = zeros(fmi3Float64, nv)
    fmi3GetFloat64!(c, refs, nv, v, nv)
    return v
end

"""
ToDo
"""
function getReal!(
    c::FMU2Component,
    refs::AbstractArray{<:fmi2ValueReference},
    vals::AbstractArray{<:fmi2Real},
)
    fmi2GetReal!(c, refs, vals)
    return nothing
end
function getReal!(
    c::FMU3Instance,
    refs::AbstractArray{<:fmi3ValueReference},
    vals::AbstractArray{<:fmi3Float64},
)
    fmi3GetFloat64!(c, refs, vals)
    return nothing
end

"""
ToDo
"""
function getContinuousStates(c::FMU2Component)
    x = nothing
    if !c.fmu.isZeroState
        nx = Csize_t(length(c.fmu.modelDescription.stateValueReferences))
        x = zeros(fmi2Real, nx)
        fmi2GetContinuousStates!(c, x, nx)
    else
        x = zeros(fmi2Real, 1)
    end

    return x
end
function getContinuousStates(c::FMU3Instance)
    if !c.fmu.isZeroState
        nx = Csize_t(length(c.fmu.modelDescription.stateValueReferences))
        x = zeros(fmi3Float64, nx)
        fmi3GetContinuousStates!(c, x, nx)
    else
        x = zeros(fmi3Float64, 1)
    end

    return x
end

function getStates(c::Union{FMU2Component,FMU3Instance})
    x_c = getContinuousStates(c)
    x_d = getDiscreteStates(c)
    return vcat(x_c, x_d)
end

"""
ToDo
"""
function getNominalsOfContinuousStates(c::FMU2Component)
    if !c.fmu.isZeroState
        nx = Csize_t(length(c.fmu.modelDescription.stateValueReferences))
        x = zeros(fmi2Real, nx)
        fmi2GetNominalsOfContinuousStates!(c, x, nx)
        return x
    else
        return zeros(fmi2Real, 1)
    end
end
function getNominalsOfContinuousStates(c::FMU3Instance)
    if !c.fmu.isZeroState
        nx = Csize_t(length(c.fmu.modelDescription.stateValueReferences))
        x = zeros(fmi3Float64, nx)
        fmi3GetNominalsOfContinuousStates!(c, x, nx)
        return x
    else
        return zeros(fmi3Float64, 1)
    end
end

"""
ToDo
"""
function getContinuousStates!(c::FMU2Component, x::AbstractArray{<:fmi2Real})
    if !c.fmu.isZeroState
        fmi2GetContinuousStates(c, x)
    end
    return nothing
end
function getContinuousStates!(c::FMU3Instance, x::AbstractArray{<:fmi3Float64})
    if !c.fmu.isZeroState
        fmi3GetContinuousStates(c, x)
    end
    return nothing
end

"""
ToDo
"""
function setContinuousStates(c::FMU2Component, x::AbstractArray{<:fmi2Real})
    if !c.fmu.isZeroState
        fmi2SetContinuousStates(c, x)
    end
    return nothing
end
function setContinuousStates(c::FMU3Instance, x::AbstractArray{<:fmi3Float64})
    if !c.fmu.isZeroState
        fmi3SetContinuousStates(c, x)
    end
    return nothing
end

"""
ToDo
"""
function setDiscreteStates(
    c::Union{FMU2Component,FMU3Instance},
    x_d::Vector{<:Real};
    kwargs...,
)

    c.x_d = x_d

    if !c.fmu.isDummyDiscrete
        setValue(c, c.fmu.modelDescription.discreteStateValueReferences, c.x_d; kwargs...)
    end

    return nothing
end

"""
ToDo
"""
function getDiscreteStates(c::FMU2Component; kwargs...)

    if !c.fmu.isDummyDiscrete
        if length(c.fmu.modelDescription.discreteStateValueReferences) <= 0
            c.x_d = Vector{fmi2Real}() # Union{fmi2Real,fmi2Integer,fmi2Boolean} 
        else
            c.x_d =
                getValue(c, c.fmu.modelDescription.discreteStateValueReferences; kwargs...)
        end
    end

    return c.x_d
end
function getDiscreteStates(c::FMU3Instance; kwargs...)

    if !c.fmu.isDummyDiscrete
        if length(c.fmu.modelDescription.discreteStateValueReferences) <= 0
            c.x_d = Vector{fmi3Float64}() # Union{fmi2Real,fmi2Integer,fmi2Boolean} 
        else
            c.x_d =
                getValue(c, c.fmu.modelDescription.discreteStateValueReferences; kwargs...)
        end
    end

    return c.x_d
end

"""
ToDo
"""
function setTime(c::FMU2Component, t::fmi2Real; kwargs...)
    fmi2SetTime(c, t; kwargs...)
    return nothing
end
function setTime(c::FMU3Instance, t::fmi3Float64; kwargs...)
    fmi3SetTime(c, t; kwargs...)
    return nothing
end

"""
ToDo
"""
# [ToDo] Allow for non-real inputs!
function setInputs(
    c::FMU2Component,
    u_refs::AbstractArray{<:fmi2ValueReference},
    u::AbstractArray{<:fmi2Real},
)
    setReal(c, u_refs, u)
    return nothing
end
function setInputs(
    c::FMU3Instance,
    u_refs::AbstractArray{<:fmi3ValueReference},
    u::AbstractArray{<:fmi3Float64},
)
    setReal(c, u_refs, u)
    return nothing
end

"""
ToDo
"""
# [ToDo] Allow for non-real parameter!
function setParameters(
    c::FMU2Component,
    p_refs::AbstractArray{<:fmi2ValueReference},
    p::AbstractArray{<:fmi2Real},
)
    setReal(c, p_refs, p)
    return nothing
end
function setParameters(
    c::FMU3Instance,
    p_refs::AbstractArray{<:fmi3ValueReference},
    p::AbstractArray{<:fmi3Float64},
)
    setReal(c, p_refs, p)
    return nothing
end

"""
ToDo
"""
# [ToDo] Implement dx_refs to grab only specific derivatives
function getDerivatives!(
    c::FMU2Component,
    dx::AbstractArray{<:fmi2Real},
    dx_refs::AbstractArray{<:fmi2ValueReference},
)
    @assert !c.fmu.isZeroState "getDerivatives! is not callable for zero state FMUs!"

    if c.fmu.isZeroState
        dx[1] = 1.0
    else
        status = fmi2GetDerivatives!(c, dx)
    end

    return nothing
end
function getDerivatives!(
    c::FMU3Instance,
    dx::AbstractArray{<:fmi3Float64},
    dx_refs::AbstractArray{<:fmi3ValueReference},
)
    @assert !c.fmu.isZeroState "getDerivatives! is not callable for zero state FMUs!"

    if c.fmu.isZeroState
        dx[1] = 1.0
    else
        fmi3GetContinuousStateDerivatives!(c, dx)
    end

    return nothing
end

"""
ToDo
"""
function getOutputs!(
    c::FMU2Component,
    y_refs::AbstractArray{<:fmi2ValueReference},
    y::AbstractArray{<:fmi2Real},
)
    getReal!(c, y_refs, y)
    return nothing
end
function getOutputs!(
    c::FMU3Instance,
    y_refs::AbstractArray{<:fmi3ValueReference},
    y::AbstractArray{<:fmi3Float64},
)
    getReal!(c, y_refs, y)
    return nothing
end

"""
ToDo
"""
function getEventIndicators(c::FMU2Component)
    ni = Csize_t(c.fmu.modelDescription.numberOfEventIndicators)
    n = zeros(fmi2Real, ni)
    fmi2GetEventIndicators!(c, n, ni)
    return n
end
function getEventIndicators(c::FMU3Instance)
    ni = Csize_t(c.fmu.modelDescription.numberOfEventIndicators)
    n = zeros(fmi3Float64, ni)
    fmi3GetEventIndicators!(c, n, ni)
    return n
end

"""
ToDo
"""
function getEventIndicators!(
    c::FMU2Component,
    ec::AbstractArray{<:fmi2Real},
    ec_idcs::AbstractArray{<:fmi2ValueReference},
)
    @assert length(ec_idcs) == 0 || length(ec) == length(ec_idcs) "Calling `getEventIndicators!` with length(ec) = $(length(ec)), but length(ec_idcs) = $(length(ec_idcs)).\nMust be the same length or length(ec_idcs) = 0 (to pick all event indicators)."

    if length(ec_idcs) == c.fmu.modelDescription.numberOfEventIndicators ||
       length(ec_idcs) == 0 # pick ALL event indicators
        fmi2GetEventIndicators!(c, ec)
    else # pick only some specific ones
        fmi2GetEventIndicators!(c, c.eventIndicatorBuffer)
        ec[:] = c.eventIndicatorBuffer[ec_idcs]
    end
    return nothing
end
function getEventIndicators!(
    c::FMU3Instance,
    ec::AbstractArray{<:fmi3Float64},
    ec_idcs::AbstractArray{<:fmi3ValueReference},
)
    @assert length(ec_idcs) == 0 || length(ec) == length(ec_idcs) "Calling `getEventIndicators!` with length(ec) = $(length(ec)), but length(ec_idcs) = $(length(ec_idcs)).\nMust be the same length or length(ec_idcs) = 0 (to pick all event indicators)."

    if length(ec_idcs) == c.fmu.modelDescription.numberOfEventIndicators ||
       length(ec_idcs) == 0 # pick ALL event indicators
        fmi3GetEventIndicators!(c, ec, c.fmu.modelDescription.numberOfEventIndicators)
    else # pick only some specific ones
        fmi3GetEventIndicators!(
            c,
            c.eventIndicatorBuffer,
            c.fmu.modelDescription.numberOfEventIndicators,
        )
        ec[:] = c.eventIndicatorBuffer[ec_idcs]
    end
    return nothing
end

"""
ToDo
"""
function getDirectionalDerivative(
    c::FMU2Component,
    ∂f_refs::AbstractArray{<:fmi2ValueReference},
    ∂x_refs::AbstractArray{<:fmi2ValueReference},
    seed,
)
    status = fmi2GetDirectionalDerivative(c, ∂f_refs, ∂x_refs, seed)
    return isStatusOK(c, status)
end
function getDirectionalDerivative(
    c::FMU3Instance,
    ∂f_refs::AbstractArray{<:fmi3ValueReference},
    ∂x_refs::AbstractArray{<:fmi3ValueReference},
    seed,
)
    status = fmi3GetDirectionalDerivative(c, ∂f_refs, ∂x_refs, seed)
    return isStatusOK(c, status)
end

"""
ToDo
"""
function getDirectionalDerivative!(
    c::FMU2Component,
    ∂f_refs::AbstractArray{<:fmi2ValueReference},
    ∂x_refs::AbstractArray{<:fmi2ValueReference},
    seed,
    jvp,
)
    status = fmi2GetDirectionalDerivative!(c, ∂f_refs, ∂x_refs, seed, jvp)
    return isStatusOK(c, status)
end
function getDirectionalDerivative!(
    c::FMU3Instance,
    ∂f_refs::AbstractArray{<:fmi3ValueReference},
    ∂x_refs::AbstractArray{<:fmi3ValueReference},
    seed,
    jvp,
)
    status = fmi3GetDirectionalDerivative!(c, ∂f_refs, ∂x_refs, seed, jvp)
    return isStatusOK(c, status)
end

function indicesForRefs(c, refs)
    indices = Integer[]
    vrs = c.fmu.modelDescription.stateValueReferences
    for i = 1:length(vrs)
        vr = vrs[i]
        if vr ∈ refs
            push!(indices, i)
        end
    end
    return indices
end

function sampleDirectionalDerivative!(c::FMUInstance, f_refs, x_refs, seed, res; Δx = 1e-12)

    x = getReal(c, x_refs)

    setReal(c, x_refs, x + Δx * seed)
    pos = getReal(c, f_refs)

    setReal(c, x_refs, x - Δx * seed)
    neg = getReal(c, f_refs)

    res[:] = (pos - neg) ./ (2*Δx)

    setReal(c, x_refs, x)

    nothing
end

"""
ToDo
"""
function getAdjointDerivative!(
    c::FMU2Component,
    ∂f_refs::AbstractArray{<:fmi2ValueReference},
    ∂x_refs::AbstractArray{<:fmi2ValueReference},
    seed,
    vjp,
)
    @assert false "No adjoint derivatives in FMI2!"
    return nothing
end
function getAdjointDerivative!(
    c::FMU3Instance,
    ∂f_refs::AbstractArray{<:fmi3ValueReference},
    ∂x_refs::AbstractArray{<:fmi3ValueReference},
    seed,
    vjp,
)
    status = fmi3GetAdjointDerivative!(c, ∂f_refs, ∂x_refs, vjp, seed)
    return isStatusOK(c, status)
end

# get/set FMU state 

"""
ToDo
"""
function getFMUState(c::FMU2Component)
    state = fmi2FMUstate()
    ref = Ref(state)
    getFMUState!(c, ref)
    #@info "snap state: $(state)"
    return ref[]
end
function getFMUState(c::FMU3Instance)
    state = fmi3FMUState()
    ref = Ref(state)
    getFMUState!(c, ref)
    #@info "snap state: $(state)"
    return ref[]
end

"""

    getFMUState!(inst, state)

Copies the current FMU-state of the instance `inst` (like a memory copy) to the address `state`.

# Arguments 
- `inst` ∈ (FMU2Component, FMI3Instance): the FMU instance
- `state` ∈ (Ref{fmi2FMUstate}, Ref{fmi3FMUState}): the FMU state reference
"""
function getFMUState!(c::FMU2Component, state::Ref{fmi2FMUstate})
    if (
        c.fmu.type == fmi2TypeModelExchange &&
        c.fmu.modelDescription.modelExchange.canGetAndSetFMUstate
    ) || (
        c.fmu.type == fmi2TypeCoSimulation &&
        c.fmu.modelDescription.coSimulation.canGetAndSetFMUstate
    )
        return fmi2GetFMUstate!(c.fmu.cGetFMUstate, c.addr, state)
    end
    return nothing
end
function getFMUState!(c::FMU3Instance, state::Ref{fmi3FMUState})
    if (
        c.fmu.type == fmi3TypeModelExchange &&
        c.fmu.modelDescription.modelExchange.canGetAndSetFMUState
    ) || (
        c.fmu.type == fmi3TypeCoSimulation &&
        c.fmu.modelDescription.coSimulation.canGetAndSetFMUState
    )
        return fmi3GetFMUState!(c.fmu.cGetFMUState, c.addr, state)
    end
    return nothing
end

"""
    setFMUState!(instance, state)

Sets a FMUState `state`.

# Arguments
- `instance`: the `FMUInstance` (`FMUComponent` or `FMU3Instance`)
- `state`: the FMU state reference (`fmi2FMUstate` or `fmi3FMUstate`)
"""
function setFMUState!(c::FMU2Component, state::fmi2FMUstate)
    if (
        c.fmu.type == fmi2TypeModelExchange &&
        c.fmu.modelDescription.modelExchange.canGetAndSetFMUstate
    ) || (
        c.fmu.type == fmi2TypeCoSimulation &&
        c.fmu.modelDescription.coSimulation.canGetAndSetFMUstate
    )
        return fmi2SetFMUstate(c.fmu.cSetFMUstate, c.addr, state)
    end
    return nothing
end
function setFMUState!(c::FMU3Instance, state::fmi3FMUState)
    if (
        c.fmu.type == fmi3TypeModelExchange &&
        c.fmu.modelDescription.modelExchange.canGetAndSetFMUState
    ) || (
        c.fmu.type == fmi3TypeCoSimulation &&
        c.fmu.modelDescription.coSimulation.canGetAndSetFMUState
    )
        return fmi3SetFMUState(c.fmu.cSetFMUState, c.addr, state)
    end
    return nothing
end

"""
ToDo
"""
function freeFMUState!(c::FMU2Component, state::Ref{fmi2FMUstate})
    if (
        c.fmu.type == fmi2TypeModelExchange &&
        c.fmu.modelDescription.modelExchange.canGetAndSetFMUstate
    ) || (
        c.fmu.type == fmi2TypeCoSimulation &&
        c.fmu.modelDescription.coSimulation.canGetAndSetFMUstate
    )
        fmi2FreeFMUstate(c.fmu.cFreeFMUstate, c.addr, state)
    end
    return nothing
end
function freeFMUState!(c::FMU3Instance, state::Ref{fmi3FMUState})
    if (
        c.fmu.type == fmi3TypeModelExchange &&
        c.fmu.modelDescription.modelExchange.canGetAndSetFMUState
    ) || (
        c.fmu.type == fmi3TypeCoSimulation &&
        c.fmu.modelDescription.coSimulation.canGetAndSetFMUState
    )
        fmi3FreeFMUState(c.fmu.cFreeFMUState, c.addr, state)
    end
    return nothing
end

"""
    doStep(inst, dt; kwargs...)

Performs a co-simulation step with the FMU.

# Arguments 
- `inst::FMUInstance`: The FMUInstance to work with.
- `dt::Real`: The time step to do.

# Keyword arguments 
- `currentCommunicationPoint::Real`: The current communication time point, current simulation time is assumed if not set.

# Returns
- FMI2 or FMI3 return code
"""
function doStep(c::FMU2Component, dt::Real; currentCommunicationPoint::Real = c.t)
    fmi2DoStep(c, dt; currentCommunicationPoint = currentCommunicationPoint)
end
function doStep(c::FMU3Instance, dt::Real; currentCommunicationPoint::Real = c.t)
    fmi3DoStep!(c, currentCommunicationPoint, dt)
end

"""
ToDo
"""
function getNextEventTime(c::FMU2Component)
    return c.eventInfo.nextEventTime
end
function getNextEventTime(c::FMU3Instance)
    return c.nextEventTime
end

"""
ToDo
"""
function enterEventMode(c::FMU2Component)
    return fmi2EnterEventMode(c)
end
function enterEventMode(c::FMU3Instance)
    return fmi3EnterEventMode(c)
end

"""
ToDo
"""
function enterContinuousTimeMode(c::FMU2Component)
    return fmi2EnterContinuousTimeMode(c)
end
function enterContinuousTimeMode(c::FMU3Instance)
    return fmi3EnterContinuousTimeMode(c)
end

function getEventInfo(c::FMU2Component)
    return deepcopy(c.eventInfo)
end

# in FMI3 there is no eventInfo, so we need to pack a named tuple instead
function getEventInfo(c::FMU3Instance)
    return (
        enterEventMode = c.enterEventMode,
        discreteStatesNeedUpdate = c.discreteStatesNeedUpdate,
        terminateSimulation = c.terminateSimulation,
        nominalsOfContinuousStatesChanged = c.nominalsOfContinuousStatesChanged,
        valuesOfContinuousStatesChanged = c.valuesOfContinuousStatesChanged,
        nextEventTimeDefined = c.nextEventTimeDefined,
        nextEventTime = c.nextEventTime,
    )
end

function setEventInfo!(c::FMU2Component, e::fmi2EventInfo)
    c.eventInfo = deepcopy(e)
    nothing
end

# in FMI3 there is no eventInfo, so we need to unpack a named tuple instead
function setEventInfo!(c::FMU3Instance, e::NamedTuple)
    c.enterEventMode = e.enterEventMode
    c.discreteStatesNeedUpdate = e.discreteStatesNeedUpdate
    c.terminateSimulation = e.terminateSimulation
    c.nominalsOfContinuousStatesChanged = e.nominalsOfContinuousStatesChanged
    c.valuesOfContinuousStatesChanged = e.valuesOfContinuousStatesChanged
    c.nextEventTimeDefined = e.nextEventTimeDefined
    c.nextEventTime = e.nextEventTime
    nothing
end
