#
# Copyright (c) 2021 Tobias Thummerer, Lars Mikelsons, Josef Kircher
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

function setupSolver!(fmu::FMU, tspan, kwargs)

    t_start = tspan[1]
    t_stop = tspan[end]

    if isnothing(tstart)
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

    tspan[:] = (t_start, t_stop)

    if !haskey(kwargs, :reltol)
        kwargs[:reltol] = getDefaultTolerance(fmu)
        # if no tolerance is given, pick auto-setting from DifferentialEquations.jl 
    end

    if !haskey(kwargs, :dt)
        kwargs[:dt] = getDefaultStepSize(fmu)
        # if no dt is given, pick auto-setting from DifferentialEquations.jl
    end

    if !haskey(kwargs, :dtmax)
        kwargs[:dtmax] = (t_stop-t_start)/100.0
    end

    return nothing
end

# sets up the ODEProblem for simulating a ME-FMU
function setupODEProblem(c::FMUInstance, x0::AbstractArray{fmi2Real}, tspan::Union{Tuple{Float64, Float64}, Nothing}=nothing; 
    p=(), 
    inputFunction::Union{FMUInputFunction, Nothing}=nothing)
    
    callbacks = []
    
    fx = (dx, x, p, t) -> f(dx, x, p, t; inputFunction=inputFunction)
    ff = ODEFunction{true}(fx) # , tgrad=nothing)
    problem = ODEProblem{true}(ff, x0, tspan, p)

    return problem, callbacks
end

function setupODEProblem!(args...; kwargs...)
    c.problem, c.callbacks = setupODEProblem(args...; kwargs...)
    return nothing
end

function setupCallbacks(c::FMU)
    if c.fmu.hasTimeEvents && c.fmu.executionConfig.handleTimeEvents
        timeEventCb = IterativeCallback((integrator) -> time_choice(c, integrator, t_start, t_stop),
                                        (integrator) -> affectFMU!(c, integrator, 0, _inputFunction, fmusol), Float64; 
                                        initial_affect = (c.eventInfo.nextEventTime == t_start),
                                        save_positions=(false,false))
        push!(cbs, timeEventCb)
    end

    if c.fmu.hasStateEvents && c.fmu.executionConfig.handleStateEvents

        eventCb = VectorContinuousCallback((out, x, t, integrator) -> condition(c, out, x, t, integrator, _inputFunction),
                                           (integrator, idx) -> affectFMU!(c, integrator, idx, _inputFunction, fmusol),
                                           Int64(c.fmu.modelDescription.numberOfEventIndicators);
                                           rootfind = RightRootFind,
                                           save_positions=(false,false),
                                           interp_points=fmu.executionConfig.rootSearchInterpolationPoints)
        push!(cbs, eventCb)
    end

    # use step callback always if we have inputs or need event handling (or just want to see our simulation progress)
    if hasInputs || c.fmu.hasStateEvents || c.fmu.hasTimeEvents || showProgress
        stepCb = FunctionCallingCallback((x, t, integrator) -> stepCompleted(c, x, t, integrator, _inputFunction, progressMeter, t_start, t_stop, fmusol);
                                            func_everystep = true,
                                            func_start = true)
        push!(cbs, stepCb)
    end

    if savingValues 
        dtypes = collect(fmi2DataTypeForValueReference(c.fmu.modelDescription, vr) for vr in recordValues)
        fmusol.values = SavedValues(fmi2Real, Tuple{dtypes...})
        fmusol.valueReferences = copy(recordValues)

        savingCB = nothing
        if saveat === nothing
            savingCB = SavingCallback((u,t,integrator) -> saveValues(c, recordValues, u, t, integrator, _inputFunction), 
                                    fmusol.values)
        else
            savingCB = SavingCallback((u,t,integrator) -> saveValues(c, recordValues, u, t, integrator, _inputFunction), 
                                    fmusol.values, 
                                    saveat=saveat)
        end

        push!(cbs, savingCB)
    end

    if savingEventIndicators
        dtypes = collect(fmi2Real for ei in recordEventIndicators)
        fmusol.eventIndicators = SavedValues(fmi2Real, Tuple{dtypes...})
        fmusol.recordEventIndicators = copy(recordEventIndicators)

        savingCB = nothing
        if saveat === nothing
            savingCB = SavingCallback((u,t,integrator) -> saveEventIndicators(c, recordEventIndicators, u, t, integrator, _inputFunction), 
                                    fmusol.eventIndicators)
        else
            savingCB = SavingCallback((u,t,integrator) -> saveEventIndicators(c, recordEventIndicators, u, t, integrator, _inputFunction), 
                                    fmusol.eventIndicators, 
                                    saveat=saveat)
        end

        push!(cbs, savingCB)
    end

    if recordEigenvalues
        dtypes = collect(Float64 for _ in 1:2*length(c.fmu.modelDescription.stateValueReferences))
        fmusol.eigenvalues = SavedValues(fmi2Real, Tuple{dtypes...})
        
        savingCB = nothing
        if saveat === nothing
            savingCB = SavingCallback((u,t,integrator) -> saveEigenvalues(c, u, t, integrator, _inputFunction), 
                                    fmusol.eigenvalues)
        else
            savingCB = SavingCallback((u,t,integrator) -> saveEigenvalues(c, u, t, integrator, _inputFunction), 
                                    fmusol.eigenvalues, 
                                    saveat=saveat)
        end

        push!(cbs, savingCB)
    end
end