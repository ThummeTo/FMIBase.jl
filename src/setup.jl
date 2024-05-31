#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

import SciMLBase: ODEFunction, ODEProblem, RightRootFind
import DiffEqCallbacks: FunctionCallingCallback, VectorContinuousCallback, IterativeCallback, SavedValues, SavingCallback

function setupSolver!(fmu::FMU, tspan, kwargs)

    t_start = tspan[1]
    t_stop = tspan[end]

    if isnothing(t_start)
        t_start = getDefaultStartTime(fmu)
        
        if isnothing(t_start)
            t_start = 0.0
            warn(fmu, "No `t_start` given, no `t_start` available in the FMU model description, auto-picked `t_start=0.0`.")
        end
    end
    
    if isnothing(t_stop)
        t_stop = getDefaultStopTime(fmu)

        if isnothing(t_stop)
            t_stop = 1.0
            warn(fmu, "No `t_stop` given, no `t_stop` available in the FMU model description, auto-picked `t_stop=1.0`.")
        end
    end

    tspan = (t_start, t_stop)

    if !haskey(kwargs, :reltol)
        kwargs[:reltol] = getDefaultTolerance(fmu)
        # if no tolerance is given, pick auto-setting from DifferentialEquations.jl 
    end

    if !haskey(kwargs, :dt)
        dt = getDefaultStepSize(fmu)
        if !isnothing(dt)
            kwargs[:dt] = dt 
        end
        # if no dt is given, pick auto-setting from DifferentialEquations.jl
    end

    if !haskey(kwargs, :dtmax)
        kwargs[:dtmax] = (t_stop-t_start)/100.0
    end

    return tspan 
end

# sets up the ODEProblem for simulating a ME-FMU
function setupODEProblem(c::FMUInstance, x0::AbstractVector{<:Real}, tspan::Tuple{Float64, Float64}; 
    p=(), 
    inputFunction::Union{FMUInputFunction, Nothing}=nothing)

    fx = (dx, x, p, t) -> f(c, dx, x, p, t, inputFunction)
    ff = ODEFunction{true}(fx) # , tgrad=nothing)
    return ODEProblem{true}(ff, x0, tspan, p)
end

function setupODEProblem!(args...; kwargs...)
    c.problem = setupODEProblem(args...; kwargs...)
    return nothing
end

function setupCallbacks(c::FMUInstance, recordValues, recordEventIndicators, recordEigenvalues, _inputFunction, inputValueReferences, progressMeter, t_start, t_stop, saveat)

    savingValues = (length(recordValues) > 0)
    savingEventIndicators = !isnothing(recordEventIndicators) 
    hasInputs = (length(inputValueReferences) > 0)
    showProgress = false # [ToDo]
    cbs = []
    
    if c.fmu.hasTimeEvents && c.fmu.executionConfig.handleTimeEvents
        timeEventCb = IterativeCallback((integrator) -> time_choice(c, integrator, t_start, t_stop),
                                        (integrator) -> affectFMU!(c, integrator, 0, _inputFunction), Float64; 
                                        initial_affect = (getNextEventTime(c) == t_start),
                                        save_positions=(false,false))
        push!(cbs, timeEventCb)
    end

    if c.fmu.hasStateEvents && c.fmu.executionConfig.handleStateEvents

        eventCb = VectorContinuousCallback((out, x, t, integrator) -> condition(c, out, x, t, integrator, _inputFunction),
                                           (integrator, idx) -> affectFMU!(c, integrator, idx, _inputFunction),
                                           Int64(c.fmu.modelDescription.numberOfEventIndicators);
                                           rootfind = RightRootFind,
                                           save_positions=(false,false),
                                           interp_points=c.fmu.executionConfig.rootSearchInterpolationPoints)
        push!(cbs, eventCb)
    end

    # use step callback always if we have inputs or need event handling (or just want to see our simulation progress)
    if hasInputs || c.fmu.hasStateEvents || c.fmu.hasTimeEvents || showProgress
        stepCb = FunctionCallingCallback((x, t, integrator) -> stepCompleted(c, x, t, integrator, _inputFunction, progressMeter, t_start, t_stop);
                                            func_everystep = true,
                                            func_start = true)
        push!(cbs, stepCb)
    end

    if savingValues 
        dtypes = collect(dataTypeForValueReference(c.fmu.modelDescription, vr) for vr in recordValues)
        c.solution.values = SavedValues(getRealType(c), Tuple{dtypes...})
        c.solution.valueReferences = copy(recordValues)

        savingCB = nothing
        if saveat === nothing
            savingCB = SavingCallback((u,t,integrator) -> saveValues(c, recordValues, u, t, integrator, _inputFunction), 
                c.solution.values)
        else
            savingCB = SavingCallback((u,t,integrator) -> saveValues(c, recordValues, u, t, integrator, _inputFunction), 
                c.solution.values, 
                saveat=saveat)
        end

        push!(cbs, savingCB)
    end

    if savingEventIndicators
        dtypes = collect(getRealType(c) for ei in recordEventIndicators)
        c.solution.eventIndicators = SavedValues(getRealType(c), Tuple{dtypes...})
        c.solution.recordEventIndicators = copy(recordEventIndicators)

        savingCB = nothing
        if saveat === nothing
            savingCB = SavingCallback((u,t,integrator) -> saveEventIndicators(c, recordEventIndicators, u, t, integrator, _inputFunction), 
                c.solution.eventIndicators)
        else
            savingCB = SavingCallback((u,t,integrator) -> saveEventIndicators(c, recordEventIndicators, u, t, integrator, _inputFunction), 
                c.solution.eventIndicators,
                saveat=saveat)
        end

        push!(cbs, savingCB)
    end

    if recordEigenvalues
        dtypes = collect(Float64 for _ in 1:2*length(c.fmu.modelDescription.stateValueReferences))
        c.solution.eigenvalues = SavedValues(getRealType(c), Tuple{dtypes...})
        
        savingCB = nothing
        if saveat === nothing
            savingCB = SavingCallback((u,t,integrator) -> saveEigenvalues(c, u, t, integrator, _inputFunction), 
            c.solution.eigenvalues)
        else
            savingCB = SavingCallback((u,t,integrator) -> saveEigenvalues(c, u, t, integrator, _inputFunction), 
                                    c.solution.eigenvalues, 
                                    saveat=saveat)
        end

        push!(cbs, savingCB)
    end

    return cbs
end