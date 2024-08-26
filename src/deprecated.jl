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

function fmi2GetSolutionState(solution::FMU2Solution, args...; kwargs...)
    @warn "`fmi2GetSolutionState` is deprecated, use `getState` instead." maxlog = 3
    return getState(solution, args...; kwargs...)
end
export fmi2GetSolutionState

function fmi2GetSolutionDerivative(solution::FMU2Solution, args...; kwargs...)
    @warn "`fmi2GetSolutionDerivative` is deprecated, use `getDerivative` instead." maxlog = 3
    return getDerivative(solution, args...; kwargs...)
end
export fmi2GetSolutionDerivative

function fmi2GetSolutionValue(solution::FMU2Solution, args...; kwargs...)
    @warn "`fmi2GetSolutionValue` is deprecated, use `getValue` instead." maxlog = 3
    return getValue(solution, args...; kwargs...)
end
export fmi2GetSolutionValue

function fmi2GetSolutionTime(solution::FMU2Solution)
    @warn "`fmi2GetSolutionTime` is deprecated, use `getTime` instead." maxlog = 3
    return getTime(solution)
end
export fmi2GetSolutionTime