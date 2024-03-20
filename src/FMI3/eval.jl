#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

function setReal(c::FMU3Instance, refs::AbstractArray{<:fmi3ValueReference}, vals::AbstractArray{<:fmi3Float64}; kwargs...)
    fmi3SetFloat64(c, refs, vals; kwargs...)
    return nothing 
end

function getReal!(c::FMU3Instance, refs::AbstractArray{<:fmi3ValueReference}, vals::AbstractArray{<:fmi3Float64})
    fmi3GetFloat64!(c, refs, vals)
    return nothing
end

function setContinuousStates(c::FMU3Instance, x::AbstractArray{<:fmi3Float64})
    if !c.fmu.isZeroState
        fmi3SetContinuousStates(c, x)
    end
    return nothing
end

function setDiscreteStates(c::FMU3Instance, x_d::AbstractArray{<:fmi3Float64}; kwargs...)
    setReal(c, c.fmu.modelDescription.discreteStateValueReferences, x_d; kwargs...)
    return nothing
end

function setTime(c::FMU3Instance, t::fmi3Float64; kwargs...)
    fmi3SetTime(c, t; kwargs...)
    return nothing
end

# [ToDo] Allow for non-Float64 inputs!
function setInputs(c::FMU3Instance, u_refs::AbstractArray{<:fmi3ValueReference}, u::AbstractArray{<:fmi3Float64})
    setReal(c, u_refs, u)
    return nothing 
end

# [ToDo] Allow for non-Float64 parameters!
function setParameters(c::FMU3Instance, p_refs::AbstractArray{<:fmi3ValueReference}, p::AbstractArray{<:fmi3Float64})
    setReal(c, p_refs, p)
    return nothing 
end

# [ToDo] Implement dx_refs to grab only specific derivatives
function getDerivatives!(c::FMU3Instance, dx::AbstractArray{<:fmi3Float64}, dx_refs::AbstractArray{<:fmi3ValueReference})
    if c.fmu.isZeroState
        dx[:] = [1.0]
    else
        fmi3GetDerivatives!(c, dx)
    end
    return nothing
end

function getOutputs!(c::FMU3Instance, y_refs::AbstractArray{<:fmi3ValueReference}, y::AbstractArray{<:fmi3Float64})
    getReal!(c, y_refs, y)
    return nothing
end

function getEventIndicators!(c::FMU3Instance, ec::AbstractArray{<:fmi3Float64}, ec_idcs::AbstractArray{<:fmi3ValueReference})
    if length(ec_idcs) == c.fmu.modelDescription.numberOfEventIndicators || length(ec_idcs) == 0 # pick ALL event indicators
        fmi3GetEventIndicators!(c, ec)
    else # pick only some specific ones
        fmi3GetEventIndicators!(c, c.eventIndicatorBuffer)
        ec[:] = c.eventIndicatorBuffer[ec_idcs]
    end
    return nothing
end

function getDirectionalDerivative!(c::FMU3Instance, ∂f_refs::AbstractArray{<:fmi3ValueReference}, ∂x_refs::AbstractArray{<:fmi3ValueReference}, jvp, seed)
    fmi3GetDirectionalDerivative!(c, ∂f_refs, ∂x_refs, jvp, seed)
    return nothing
end

function getAdjointDerivative!(c::FMU3Instance, ∂f_refs::AbstractArray{<:fmi3ValueReference}, ∂x_refs::AbstractArray{<:fmi3ValueReference}, vjp, seed)
    fmi3GetAdjointDerivative!(c, ∂f_refs, ∂x_refs, vjp, seed)
    return nothing
end

# get/set FMU state 

function getFMUstate(c::FMU3Instance)
    @assert false, "Not implemented yet. Please open an issue." # [TODO]
end

function getFMUstate!(c::FMU3Instance, state::Ref{fmi3FMUState})
    @assert false, "Not implemented yet. Please open an issue." # [TODO]
end

function setFMUstate!(c::FMU3Instance, state::fmi2FMUstate)
    @assert false, "Not implemented yet. Please open an issue." # [TODO]
end

function freeFMUstate!(c::FMU3Instance, state::Ref{fmi3FMUState})
    @assert false, "Not implemented yet. Please open an issue." # [TODO]
end