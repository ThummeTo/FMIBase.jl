#!
# Copyright (c) 2021 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

# returns the event indicators for an FMU.
function condition(c::FMUInstance, out, x, t, integrator, inputFunction) 
    condition!(c, out, x, t, inputFunction)
    return nothing
end

function condition!(c::FMUInstance, 
    ec,
    x::AbstractArray{<:Real}, 
    t::Real,
    inputFunction::Union{Nothing, FMUInputFunction})

    c.solution.evals_condition += 1

    u = getEmptyReal(c)
    u_refs = getEmptyValueReference(c)
    if !isnothing(inputFunction)
        u = eval!(inputFunction, c, x, t)
        u_refs = inputFunction.vrs
    end

    c(;x=x, u=u, u_refs=u_refs, t=t, ec=ec)
    
    return nothing
end

# Read next time event from FMU and provide it to the integrator 
function time_choice(c::FMUInstance, integrator, tStart, tStop) 
    
    c.solution.evals_timechoice += 1

    if isTrue(c.eventInfo.nextEventTimeDefined)

        if c.eventInfo.nextEventTime >= tStart && c.eventInfo.nextEventTime <= tStop
            return c.eventInfo.nextEventTime
        else
            # the time event is outside the simulation range!
            @debug "Next time event @$(c.eventInfo.nextEventTime)s is outside simulation time range ($(tStart), $(tStop)), skipping."
            return nothing 
        end
    else
        return nothing
    end
end

# f evaluation (IP)
function f(c::FMUInstance, 
    dx::AbstractArray{<:Real},
    x::AbstractArray{<:Real}, 
    p::Tuple,
    t::Real,
    inputFunction::Union{Nothing, FMUInputFunction})

    c.solution.evals_fx_inplace += 1

    u = getEmptyReal(c)
    u_refs = getEmptyValueReference(c)
    if !isnothing(inputFunction)
        u = eval!(inputFunction, c, x, t)
        u_refs = inputFunction.vrs
    end

    c(;dx=dx, x=x, u=u, u_refs=u_refs, t=t)
    
    return nothing
end

# f evaluation (OOP)
function f(c::FMUInstance, 
    x::AbstractArray{<:Real}, 
    p::Tuple,
    t::Real,
    inputFunction::Union{Nothing, FMUInputFunction})

    c.solution.evals_fx_outofplace += 1

    dx = zeros(getRealType(c), length(x))

    f(c, dx, x, p, t)

    # correct statisitics, because fx-call above -> this was in fact an out-of-place evaluation
    c.solution.evals_fx_inplace -= 1 

    return dx
end

# just set state, time, etc. no getter
function f_set(c::FMUInstance, 
    x::AbstractArray{<:Real}, 
    t::Real,
    inputFunction::Union{Nothing, FMUInputFunction}; force::Bool=false)

    u = getEmptyReal(c)
    u_refs = getEmptyValueReference(c)
    if !isnothing(inputFunction)
        u = eval!(inputFunction, c, x, t)
        u_refs = inputFunction.vrs
    end

    oldForce = c.force
    c.force = force

    c(;x=x, u=u, u_refs=u_refs, t=t)

    c.force = oldForce

    return nothing
end

# save FMU values 
function saveValues(c::FMUInstance, recordValues, x, t, integrator, inputFunction)

    @assert isContinuousTimeMode(c) "saveValues(...):\n" * ERR_MSG_CONT_TIME_MODE

    c.solution.evals_savevalues += 1

    f_set(c, x, t, inputFunction)
    
    # ToDo: Replace by inplace statement!
    return (getValue(c, recordValues)...,)
end

function saveEventIndicators(c::FMUInstance, recordEventIndicators, x, t, integrator, inputFunction)

    @assert isContinuousTimeMode(c) "saveEventIndicators(...):\n" * ERR_MSG_CONT_TIME_MODE

    c.solution.evals_saveeventindicators += 1

    out = zeros(getRealType(c), c.fmu.modelDescription.numberOfEventIndicators)
    condition!(c, out, x, t, inputFunction)

    # ToDo: Replace by inplace statement!
    return (out[recordEventIndicators]...,)
end

function saveEigenvalues(c::FMUInstance, x, t, integrator, inputFunction)

    @assert isContinuousTimeMode(c) "saveEigenvalues(...):\n" * ERR_MSG_CONT_TIME_MODE

    c.solution.evals_saveeigenvalues += 1

    f_set(c, x, t, inputFunction)

    # ToDo: Replace this by an directional derivative call!
    A = ReverseDiff.jacobian(_x -> FMI.f(c, _x, [], t), x)
    eigs = eigvals(A)

    vals = []
    for e in eigs 
        push!(vals, real(e))
        push!(vals, imag(e))
    end
    
    # ToDo: Replace by inplace statement!
    return (vals...,)
end