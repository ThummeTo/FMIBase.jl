#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

# FMUSolution 

function Base.setproperty!(obj::FMUSolution, var::Symbol, value)
    if var == :component
        @warn "`FMUSolution.component` is deprecated, use `FMUSolution.instance` instead." maxlog =
            3
        return Base.setfield!(obj, :instance, value)
    end
    return Base.setfield!(obj, var, value)
end

function Base.hasproperty(obj::FMUSolution, var::Symbol)
    if var == :component
        @warn "`FMUSolution.component` is deprecated, use `FMUSolution.instance` instead." maxlog =
            3
        return true
    end
    return Base.hasfield(obj, var)
end

function Base.getproperty(obj::FMUSolution, var::Symbol)
    if var == :component
        @warn "`FMUSolution.component` is deprecated, use `FMUSolution.instance` instead." maxlog =
            3
        return Base.getfield(obj, :instance)
    end
    return Base.getfield(obj, var)
end

function fmi2GetSolutionState(solution::FMUSolution, args...; kwargs...)
    @warn "`fmi2GetSolutionState` is deprecated, use `getState` instead." maxlog = 3
    return getState(solution, args...; kwargs...)
end
export fmi2GetSolutionState

function fmiGetSolutionState(solution::FMUSolution, args...; kwargs...)
    @warn "`fmiGetSolutionState` is deprecated, use `getState` instead." maxlog = 3
    return getState(solution, args...; kwargs...)
end
export fmiGetSolutionState

function fmi2GetSolutionDerivative(solution::FMUSolution, args...; kwargs...)
    @warn "`fmi2GetSolutionDerivative` is deprecated, use `getStateDerivative` instead." maxlog = 3
    return getStateDerivative(solution, args...; kwargs...)
end
export fmi2GetSolutionDerivative

function fmiGetSolutionDerivative(solution::FMUSolution, args...; kwargs...)
    @warn "`fmiGetSolutionDerivative` is deprecated, use `getStateDerivative` instead." maxlog = 3
    return getStateDerivative(solution, args...; kwargs...)
end
export fmiGetSolutionDerivative

function fmi2GetSolutionValue(solution::FMUSolution, args...; kwargs...)
    @warn "`fmi2GetSolutionValue` is deprecated, use `getValue` instead." maxlog = 3
    return getValue(solution, args...; kwargs...)
end
export fmi2GetSolutionValue

function fmiGetSolutionValue(solution::FMUSolution, args...; kwargs...)
    @warn "`fmiGetSolutionValue` is deprecated, use `getValue` instead." maxlog = 3
    return getValue(solution, args...; kwargs...)
end
export fmiGetSolutionValue

function fmi2GetSolutionTime(solution::FMUSolution)
    @warn "`fmi2GetSolutionTime` is deprecated, use `getTime` instead." maxlog = 3
    return getTime(solution)
end
export fmi2GetSolutionTime

function fmiGetSolutionTime(solution::FMUSolution)
    @warn "`fmiGetSolutionTime` is deprecated, use `getTime` instead." maxlog = 3
    return getTime(solution)
end
export fmiGetSolutionTime