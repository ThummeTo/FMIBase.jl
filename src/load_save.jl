#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

"""
    saveSolution(solution::FMUSolution, filepath::AbstractString [; keyword="solution"])

Saves a `solution` of an FMU simulation at `filepath`.

Currently .mat, .jld2 and .csv are supported for saving and selected by the ending of `filepath`.
For JLD2 the `keyword` is used as key.

See also [`saveSolutionCSV`](@ref), [`saveSolutionMAT`](@ref), [`saveSolutionJLD2`](@ref), [`loadSolutionJLD2`](@ref).
"""
function saveSolution(solution::FMUSolution, filepath::AbstractString; keyword = "solution")
    ending = split(filepath, ".")[2]
    if ending == "mat"
        saveSolutionMAT(solution, filepath)
    elseif ending == "jld2"
        saveSolutionJLD2(solution, filepath; keyword = "solution")
    elseif ending == "csv"
        saveSolutionCSV(solution, filepath)
    else
        @assert false "This file format is currently not supported, please use *.mat, *.csv, *.JLD2"
    end
end
export saveSolution

"""
    loadSolution(filepath::AbstractString; keyword="solution")

Loads a `solution` of an FMU simulation at `filepath`.

Currently only .jld2 is implemented for loading.
For JLD2 the `keyword` is used as key.

See also [`saveSolutionCSV`](@ref), [`saveSolutionMAT`](@ref), [`saveSolutionJLD2`](@ref), [`loadSolutionJLD2`](@ref).
"""
function loadSolution(filepath::AbstractString; keyword = "solution")
    ending = split(filepath, ".")[2]
    if ending == "mat"
        return loadSolutionMAT(filepath)
    elseif ending == "jld2"
        return loadSolutionJLD2(filepath; keyword = "solution")
    elseif ending == "csv"
        return loadSolutionCSV(filepath)
    else
        @warn "This file format is currently not supported, please use *.jld2"
        return nothing
    end
end
export loadSolution
