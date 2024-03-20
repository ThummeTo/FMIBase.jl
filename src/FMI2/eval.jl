#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

function setReal(c::FMU2Component, refs::AbstractArray{<:fmi2ValueReference}, vals::AbstractArray{<:fmi2Real}; kwargs...)
    fmi2SetReal(c, refs, vals; kwargs...)
    return nothing 
end

function getReal!(c::FMU2Component, refs::AbstractArray{<:fmi2ValueReference}, vals::AbstractArray{<:fmi2Real})
    fmi2GetReal!(c, refs, vals)
    return nothing
end

function setContinuousStates(c::FMU2Component, x::AbstractArray{<:fmi2Real})
    if !c.fmu.isZeroState
        fmi2SetContinuousStates(c, x)
    end
    return nothing
end

function setDiscreteStates(c::FMU2Component, x_d::AbstractArray{<:fmi2Real}; kwargs...)
    setReal(c, c.fmu.modelDescription.discreteStateValueReferences, x_d; kwargs...)
    return nothing
end

function setTime(c::FMU2Component, t::fmi2Real; kwargs...)
    fmi2SetTime(c, t; kwargs...)
    return nothing
end

# [ToDo] Allow for non-real inputs!
function setInputs(c::FMU2Component, u_refs::AbstractArray{<:fmi2ValueReference}, u::AbstractArray{<:fmi2Real})
    setReal(c, u_refs, u)
    return nothing 
end

# [ToDo] Allow for non-real parameter!
function setParameters(c::FMU2Component, p_refs::AbstractArray{<:fmi2ValueReference}, p::AbstractArray{<:fmi2Real})
    setReal(c, p_refs, p)
    return nothing 
end

# [ToDo] Implement dx_refs to grab only specific derivatives
function getDerivatives!(c::FMU2Component, dx::AbstractArray{<:fmi2Real}, dx_refs::AbstractArray{<:fmi2ValueReference})
    if c.fmu.isZeroState
        dx[:] = [1.0]
    else
        fmi2GetDerivatives!(c, dx)
    end
    return nothing
end

function getOutputs!(c::FMU2Component, y_refs::AbstractArray{<:fmi2ValueReference}, y::AbstractArray{<:fmi2Real})
    getReal!(c, y_refs, y)
    return nothing
end

function getEventIndicators!(c::FMU2Component, ec::AbstractArray{<:fmi2Real}, ec_idcs::AbstractArray{<:fmi2ValueReference})
    if length(ec_idcs) == c.fmu.modelDescription.numberOfEventIndicators || length(ec_idcs) == 0 # pick ALL event indicators
        fmi2GetEventIndicators!(c, ec)
    else # pick only some specific ones
        fmi2GetEventIndicators!(c, c.eventIndicatorBuffer)
        ec[:] = c.eventIndicatorBuffer[ec_idcs]
    end
    return nothing
end

function getDirectionalDerivative!(c::FMU2Component, ∂f_refs::AbstractArray{<:fmi2ValueReference}, ∂x_refs::AbstractArray{<:fmi2ValueReference}, jvp, seed)
    fmi2GetDirectionalDerivative!(c, ∂f_refs, ∂x_refs, jvp, seed)
    return nothing
end

function getAdjointDerivative!(c::FMU2Component, ∂f_refs::AbstractArray{<:fmi2ValueReference}, ∂x_refs::AbstractArray{<:fmi2ValueReference}, vjp, seed)
    @assert false, "No adjoint derivatives in FMI2!"
    return nothing
end

# get/set FMU state 

function getFMUstate(c::FMU2Component)
    state = fmi2FMUstate()
    ref = Ref(state)
    getFMUstate!(c, ref)
    #@info "snap state: $(state)"
    return ref[]
end

function getFMUstate!(c::FMU2Component, state::Ref{fmi2FMUstate})
    if c.fmu.modelDescription.modelExchange.canGetAndSetFMUstate || c.fmu.modelDescription.coSimulation.canGetAndSetFMUstate
        return fmi2GetFMUstate!(c.fmu.cGetFMUstate, c.compAddr, state)
    end
    return nothing
end

function setFMUstate!(c::FMU2Component, state::fmi2FMUstate)
    if c.fmu.modelDescription.modelExchange.canGetAndSetFMUstate || c.fmu.modelDescription.coSimulation.canGetAndSetFMUstate
        return fmi2SetFMUstate(c.fmu.cSetFMUstate, c.compAddr, state)
    end
    return nothing
end

function freeFMUstate!(c::FMU2Component, state::Ref{fmi2FMUstate})
    fmi2FreeFMUstate!(c.fmu.cFreeFMUstate, c.compAddr, state)
    return nothing 
end