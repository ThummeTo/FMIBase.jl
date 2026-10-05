#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

import SciMLBase: AbstractODEProblem

"""
    FMUProblem(fmu, tspan=nothing; kwargs...)
    FMUProblem(instance, tspan=nothing; kwargs...)

A SciML-style problem wrapper for simulating FMUs.

For Model Exchange FMUs, `solve(::FMUProblem)` prepares an internal `ODEProblem`
and returns the resulting SciML `ODESolution`. For Co-Simulation FMUs, `solve`
uses the FMU's own do-step interface instead of an ODE algorithm.

The simulation `mode` must be one of `:ME`, `:CS` or `:SE`. If no `mode` is given,
`:CS` is used if the FMU supports Co-Simulation, otherwise `:ME` (or `:SE` for FMI3
FMUs that only support Scheduled Execution).
"""
mutable struct FMUProblem{uType,tType,isinplace,F<:FMU} <:
    AbstractODEProblem{uType,tType,isinplace}
    f::Any
    u0::Any
    tspan::tType
    p::Any
    kwargs::NamedTuple
    problem_type::Any

    fmu::F
    instance::Any
    mode::Symbol
    problem::Any
    callback::Any
end
export FMUProblem

const FMU_PROBLEM_MODES = (:ME, :CS, :SE)

# Fall back to model-description support flags: prefer CS, then ME (then SE for FMI3).
function _default_fmu_problem_mode(fmu::FMU2)
    isCoSimulation(fmu) && return :CS
    isModelExchange(fmu) && return :ME

    throw(
        ArgumentError(
            "Could not infer FMUProblem mode for this FMI2 FMU. Pass `mode=:ME` or `mode=:CS`.",
        ),
    )
end

function _default_fmu_problem_mode(fmu::FMU3)
    isCoSimulation(fmu) && return :CS
    isModelExchange(fmu) && return :ME
    isScheduledExecution(fmu) && return :SE

    throw(
        ArgumentError(
            "Could not infer FMUProblem mode for this FMI3 FMU. Pass `mode=:ME`, `mode=:CS` or `mode=:SE`.",
        ),
    )
end

_fmu_problem_mode(fmu::FMU, ::Nothing) = _default_fmu_problem_mode(fmu)

function _fmu_problem_mode(fmu::FMU, mode)
    mode in FMU_PROBLEM_MODES || throw(
        ArgumentError(
            "Unknown FMUProblem mode `$(repr(mode))`. Supported modes are :ME, :CS and :SE.",
        ),
    )
    return mode
end

# Reuse the existing default-time/tolerance setup path, but only keep the normalized tspan.
function _normalize_fmu_problem_tspan(fmu::FMU, tspan)
    solver_kwargs = Dict{Symbol,Any}()
    normalized = setupSolver!(fmu, tspan, solver_kwargs)
    return (Float64(normalized[1]), Float64(normalized[2]))
end

function _normalize_fmu_problem_u0(u0, x0)
    if u0 !== nothing && x0 !== nothing
        throw(
            ArgumentError(
                "Pass only one of `u0` (Julia world) and `x0` (FMI world) to FMUProblem. They describe the same initial state.",
            ),
        )
    end
    return u0 === nothing ? x0 : u0
end

_is_null_parameters(p) = p isa SciMLBase.NullParameters

# Treat dictionary-valued SciML `p` as FMI initialization parameters by default.
function _normalize_fmu_problem_kwargs(kwargs::NamedTuple, p)
    if _is_null_parameters(p) && haskey(kwargs, :parameters)
        p = kwargs.parameters
    elseif !_is_null_parameters(p) && p isa AbstractDict && !haskey(kwargs, :parameters)
        kwargs = merge(kwargs, (; parameters=p))
    end

    return kwargs, p
end

function FMUProblem(
    fmu::F,
    tspan=nothing;
    instance=nothing,
    mode=nothing,
    u0=nothing,
    x0=nothing,
    p=SciMLBase.NullParameters(),
    problem=nothing,
    callback=nothing,
    kwargs...,
) where {F<:FMU}
    _mode = _fmu_problem_mode(fmu, mode)
    _tspan = _normalize_fmu_problem_tspan(fmu, tspan)
    _u0 = _normalize_fmu_problem_u0(u0, x0)

    # Preserve SciML's `p` field while also feeding FMI's existing `parameters` keyword.
    _kwargs, _p = _normalize_fmu_problem_kwargs((; kwargs...), p)

    uType = _u0 === nothing ? Any : typeof(_u0)
    tType = typeof(_tspan)

    return FMUProblem{uType,tType,true,F}(
        nothing,
        _u0,
        _tspan,
        _p,
        _kwargs,
        SciMLBase.StandardODEProblem(),
        fmu,
        instance,
        _mode,
        problem,
        callback,
    )
end

FMUProblem(instance::FMUInstance, tspan=nothing; kwargs...) =
    FMUProblem(instance.fmu, tspan; instance=instance, kwargs...)

"""
    solveFMUProblem!(prob, args...; kwargs...)

Backend hook for packages that provide executable FMU instances. FMIImport
extends this method with Model Exchange and Co-Simulation behavior.
"""
function solveFMUProblem!(prob, args...; kwargs...)
    throw(
        ArgumentError(
            "Solving an FMUProblem requires a package that implements FMU execution, such as FMIImport.jl. Load FMIImport and call `solve` again.",
        ),
    )
end
export solveFMUProblem!

function prepareSolveFMU(args...; kwargs...)
    throw(
        ArgumentError(
            "Preparing an FMU solve requires a package that implements FMU execution, such as FMIImport.jl.",
        ),
    )
end

function finishSolveFMU(args...; kwargs...)
    throw(
        ArgumentError(
            "Finishing an FMU solve requires a package that implements FMU execution, such as FMIImport.jl.",
        ),
    )
end
export prepareSolveFMU, finishSolveFMU

# Keep `solve(prob)` available from FMIBase, but let executable packages provide behavior.
function SciMLBase.solve(prob::FMUProblem, args...; kwargs...)
    return solveFMUProblem!(prob, args...; kwargs...)
end

function SciMLBase.remake(
    prob::FMUProblem;
    f=missing,
    u0=missing,
    x0=missing,
    tspan=missing,
    p=missing,
    kwargs=missing,
    instance=missing,
    mode=missing,
    problem=missing,
    callback=missing,
    _kwargs...,
)
    if f !== missing
        throw(
            ArgumentError(
                "`remake(::FMUProblem; f=...)` is not supported. The FMU defines the dynamics.",
            ),
        )
    end

    if u0 !== missing && x0 !== missing
        throw(ArgumentError("Pass only one of `u0` and `x0` to `remake(::FMUProblem)`."))
    end

    new_u0 = u0 !== missing ? u0 : (x0 !== missing ? x0 : prob.u0)
    new_tspan = tspan === missing ? prob.tspan : tspan
    new_p = p === missing ? prob.p : p

    # `kwargs=...` replaces stored solve keywords; extra keywords patch them.
    base_kwargs = kwargs === missing ? prob.kwargs : (; kwargs...)
    new_kwargs = merge(base_kwargs, (; _kwargs...))

    return FMUProblem(
        prob.fmu,
        new_tspan;
        instance=instance === missing ? prob.instance : instance,
        mode=mode === missing ? prob.mode : mode,
        u0=new_u0,
        p=new_p,
        problem=problem === missing ? nothing : problem,
        callback=callback === missing ? nothing : callback,
        new_kwargs...,
    )
end
