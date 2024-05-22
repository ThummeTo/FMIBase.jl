#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

import ProgressMeter
using SciMLBase: u_modified!

# returns the event indicators for an FMU
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
function time_choice(c::FMU2Component, integrator, tStart, tStop) 
    
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
function time_choice(c::FMU3Instance, integrator, tStart, tStop) 
    
    c.solution.evals_timechoice += 1

    if isTrue(c.nextEventTimeDefined)

        if c.nextEventTime >= tStart && c.nextEventTime <= tStop
            return c.nextEventTime
        else
            # the time event is outside the simulation range!
            @debug "Next time event @$(c.nextEventTime)s is outside simulation time range ($(tStart), $(tStop)), skipping."
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


# Does one step in the simulation.
function stepCompleted(c::FMU2Component, x, t, integrator, inputFunction, progressMeter, tStart, tStop)

    @assert isContinuousTimeMode(c) "stepCompleted(...):\n" * ERR_MSG_CONT_TIME_MODE
    
    c.solution.evals_stepcompleted += 1

    if !isnothing(progressMeter)
        stat = 1000.0*(t-tStart)/(tStop-tStart)
        if !isnan(stat)
            stat = floor(Integer, stat)
            ProgressMeter.update!(progressMeter, stat)
        end
    end

    noSetFMUStatePriorToCurrentPoint = fmi2True
    status = fmi2CompletedIntegratorStep!(c,
        noSetFMUStatePriorToCurrentPoint,
        c._ptr_enterEventMode,
        c._ptr_terminateSimulation)
    
    if isTrue(c.terminateSimulation)
        @error "stepCompleted(...): FMU requested termination!"
    end

    if isTrue(c.enterEventMode)
        affectFMU!(c, integrator, -1, inputFunction)
    else
        if !isnothing(inputFunction)
            u = eval!(inputFunction, c, x, t)
            u_refs = inputFunction.vrs
            fmi2SetReal(c, u_refs, u) # [ToDo] other input types
        end
    end
end
function stepCompleted(c::FMU3Instance, x, t, integrator, inputFunction, progressMeter, tStart, tStop)

    @assert isContinuousTimeMode(c) "stepCompleted(...):\n" * ERR_MSG_CONT_TIME_MODE
    
    c.solution.evals_stepcompleted += 1

    if !isnothing(progressMeter)
        stat = 1000.0*(t-tStart)/(tStop-tStart)
        if !isnan(stat)
            stat = floor(Integer, stat)
            ProgressMeter.update!(progressMeter, stat)
        end
    end

    noSetFMUStatePriorToCurrentPoint = fmi3True
    status = fmi3CompletedIntegratorStep!(c,
        noSetFMUStatePriorToCurrentPoint,
        c._ptr_enterEventMode,
        c._ptr_terminateSimulation)
    
    if isTrue(c.terminateSimulation)
        @error "stepCompleted(...): FMU requested termination!"
    end

    if isTrue(c.enterEventMode)
        affectFMU!(c, integrator, -1, inputFunction)
    else
        if !isnothing(inputFunction)
            u = eval!(inputFunction, c, x, t)
            u_refs = inputFunction.vrs
            fmi3SetFloat64(c, u_refs, u) # [ToDo] other input types
        end
    end
end

function affectFMU!(c::FMU2Component, integrator, idx, inputFunction)

    @assert isContinuousTimeMode(c) "affectFMU!(...):\n" * ERR_MSG_CONT_TIME_MODE

    c.solution.evals_affect += 1

    # there are fx-evaluations before the event is handled, reset the FMU state to the current integrator step
    f_set(c, integrator.u, integrator.t, inputFunction; force=true)

    fmi2EnterEventMode(c)

    # Event found - handle it
    handleEvents(c)

    left_x = nothing 
    right_x = nothing

    if isTrue(c.eventInfo.valuesOfContinuousStatesChanged)
        left_x = integrator.u
        right_x = fmi2GetContinuousStates(c)
        @debug "affectFMU!(...): Handled event at t=$(integrator.t), new state is $(right_x)"
        integrator.u = right_x

        u_modified!(integrator, true)
    else 
        u_modified!(integrator, false)
        @debug "affectFMU!(...): Handled event at t=$(integrator.t), no new state."
    end

    if isTrue(c.eventInfo.nominalsOfContinuousStatesChanged)
        x_nom = fmi2GetNominalsOfContinuousStates(c)
    end

    ignore_derivatives() do 
        if idx != -1 # -1 no event, 0, time event, >=1 state event with indicator
            e = FMUEvent(integrator.t, UInt64(idx), left_x, right_x)
            push!(c.solution.events, e)
        end
    end 

    #fmi2EnterContinuousTimeMode(c)
end
function affectFMU!(c::FMU3Instance, integrator, idx, inputFunction)
    
    @assert isContinuousTimeMode(c) "affectFMU!(...): Must be in continuous time mode!"
    
    # there are fx-evaluations before the event is handled, reset the FMU state to the current integrator step
    f_set(c, integrator.u, integrator.t, inputFunction; force=true)

    fmi3EnterEventMode(c, c.stepEvent, c.stateEvent, c.rootsFound, Csize_t(c.fmu.modelDescription.numberOfEventIndicators), c.timeEvent) # [todo] this is actually not an inplace operation!
    
    # Event found - handle it
    handleEvents(c)

    left_x = nothing 
    right_x = nothing

    if c.valuesOfContinuousStatesChanged == fmi3True
        left_x = integrator.u
        right_x = fmi3GetContinuousStates(c)
        @debug "affectFMU!(...): Handled event at t=$(integrator.t), new state is $(new_u)"
        integrator.u = right_x

        u_modified!(integrator, true)
        #set_proposed_dt!(integrator, 1e-10)
    else 
        u_modified!(integrator, false)
        @debug "affectFMU!(...): Handled event at t=$(integrator.t), no new state."
    end

    if c.nominalsOfContinuousStatesChanged == fmi3True
        x_nom = fmi3GetNominalsOfContinuousStates(c)
    end

    ignore_derivatives() do 
        if idx != -1 # -1 no event, 0, time event, >=1 state event with indicator
            e = FMUEvent(integrator.t, UInt64(idx), left_x, right_x)
            push!(c.solution.events, e)
        end
    end 

    #fmi3EnterContinuousTimeMode(c)
end


# Handles events and returns the values and nominals of the changed continuous states.
function handleEvents(c::FMU2Component)

    @assert isEventMode(c) "handleEvents(...): Must be in event mode!"

    # invalidate all cached jacobians/gradients 
    invalidate!(c.∂ẋ_∂x) 
    invalidate!(c.∂ẋ_∂u)
    invalidate!(c.∂ẋ_∂p)  
    invalidate!(c.∂y_∂x) 
    invalidate!(c.∂y_∂u)
    invalidate!(c.∂y_∂p)
    invalidate!(c.∂e_∂x) 
    invalidate!(c.∂e_∂u)
    invalidate!(c.∂e_∂p)
    invalidate!(c.∂ẋ_∂t)
    invalidate!(c.∂y_∂t)
    invalidate!(c.∂e_∂t)

    #@debug "Handle Events..."

    # trigger the loop
    c.eventInfo.newDiscreteStatesNeeded = fmi2True

    valuesOfContinuousStatesChanged = fmi2False
    nominalsOfContinuousStatesChanged = fmi2False
    nextEventTimeDefined = fmi2False
    nextEventTime = 0.0

    numCalls = 0
    while c.eventInfo.newDiscreteStatesNeeded == fmi2True
        numCalls += 1
        fmi2NewDiscreteStates!(c, c.eventInfo)

        if c.eventInfo.valuesOfContinuousStatesChanged == fmi2True
            valuesOfContinuousStatesChanged = fmi2True
        end

        if c.eventInfo.nominalsOfContinuousStatesChanged == fmi2True
            nominalsOfContinuousStatesChanged = fmi2True
        end

        if c.eventInfo.nextEventTimeDefined == fmi2True
            nextEventTimeDefined = fmi2True
            nextEventTime = c.eventInfo.nextEventTime
        end

        if c.eventInfo.terminateSimulation == fmi2True
            @error "handleEvents(...): FMU throws `terminateSimulation`!"
        end

        @assert numCalls <= c.fmu.executionConfig.maxNewDiscreteStateCalls "handleEvents(...): `fmi2NewDiscreteStates!` exceeded $(c.fmu.executionConfig.maxNewDiscreteStateCalls) calls, this may be an error in the FMU. If not, you can change the max value for this FMU in `fmu.executionConfig.maxNewDiscreteStateCalls`."
    end

    c.eventInfo.valuesOfContinuousStatesChanged = valuesOfContinuousStatesChanged
    c.eventInfo.nominalsOfContinuousStatesChanged = nominalsOfContinuousStatesChanged
    c.eventInfo.nextEventTimeDefined = nextEventTimeDefined
    c.eventInfo.nextEventTime = nextEventTime

    @assert fmi2EnterContinuousTimeMode(c) == fmi2StatusOK "FMU is not in state continuous time after event handling."

    return nothing
end
function handleEvents(c::FMU3Instance)

    @assert isEventMode(c) "handleEvents(...): Must be in event mode!"

    # invalidate all cached jacobians/gradients 
    invalidate!(c.∂ẋ_∂x) 
    invalidate!(c.∂ẋ_∂u)
    invalidate!(c.∂ẋ_∂p)  
    invalidate!(c.∂y_∂x) 
    invalidate!(c.∂y_∂u)
    invalidate!(c.∂y_∂p)
    invalidate!(c.∂e_∂x) 
    invalidate!(c.∂e_∂u)
    invalidate!(c.∂e_∂p)
    invalidate!(c.∂ẋ_∂t)
    invalidate!(c.∂y_∂t)
    invalidate!(c.∂e_∂t)

    #@debug "Handle Events..."

    # trigger the loop
    c.discreteStatesNeedUpdate = fmi3True

    numCalls = 0
    while isTrue(c.discreteStatesNeedUpdate)
        numCalls += 1
        fmi3UpdateDiscreteStates(c,
            c._ptr_discreteStatesNeedUpdate, 
            c._ptr_terminateSimulation, 
            c._ptr_nominalsOfContinuousStatesChanged, 
            c._ptr_valuesOfContinuousStatesChanged, 
            c._ptr_nextEventTimeDefined, 
            c._ptr_nextEventTime)

        if isTrue(c.terminateSimulation)
            @error "handleEvents(...): FMU throws `terminateSimulation`!"
        end

        @assert numCalls <= c.fmu.executionConfig.maxNewDiscreteStateCalls "handleEvents(...): Exceeded $(c.fmu.executionConfig.maxNewDiscreteStateCalls) calls, this may be an error in the FMU. If not, you can change the max value for this FMU in `fmu.executionConfig.maxNewDiscreteStateCalls`."
    end

    @assert isStatusOK(c, fmi3EnterContinuousTimeMode(c)) "FMU is not in state continuous time after event handling."

    return nothing
end