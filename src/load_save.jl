#
# Copyright (c) 2021 Tobias Thummerer, Lars Mikelsons, Josef Kircher
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

"""
    fmiSaveSolution(solution::FMUSolution, filepath::AbstractString [; keyword="solution"])

Save a `solution` of an FMU simulation at `filepath`.

Currently .mat, .jld2 and .csv are supported for saving and selected by the ending of `filepath`.
For JLD2 the `keyword` is used as key.
Loading a FMUSolution into FMI.jl is currently only possible for .jld2 files.

See also [`fmiSaveSolutionCSV`](@ref), [`fmiSaveSolutionMAT`](@ref), [`fmiSaveSolutionJLD2`](@ref), [`fmiLoadSolutionJLD2`](@ref).
"""
function fmiSaveSolution(solution::FMUSolution, filepath::AbstractString; keyword="solution")
    ending = split(filepath, ".")[2]
    if ending == "mat"
        fmiSaveSolutionMAT(solution, filepath)
    elseif ending == "jld2"
        fmiSaveSolutionJLD2(solution, filepath; keyword="solution")
    elseif ending == "csv"
        fmiSaveSolutionCSV(solution, filepath)
    else
        @assert false "This file format is currently not supported, please use *.mat, *.csv, *.JLD2"
    end
end
export fmiSaveSolution

"""
    fmiLoadSolution(filepath::AbstractString; keyword="solution")

Wrapper for [`fmiLoadSolutionJLD2`](@ref).
"""
function fmiLoadSolution(filepath::AbstractString; keyword="solution")
    ending = split(filepath, ".")[2]
    if ending == "jld2"
        fmiLoadSolutionJLD2(filepath; keyword="solution")
    else
        @warn "This file format is currently not supported, please use *.jld2"
    end
end
export fmiLoadSolution