#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

"""
    saveSolutionJLD2(solution::FMUSolution, filepath::AbstractString; keyword="solution") 

Saves a `solution` of an FMU under dictionary `keyword` in a JLD2 file at `filepath`. 
(requires package JLD2.jl)

See also [`saveSolution`](@ref).
"""
function saveSolutionJLD2(solution::FMUSolution, filepath::AbstractString; keyword="solution") 
    return JLD2.save(filepath, Dict(keyword=>solution))
end
export saveSolutionJLD2

"""
    loadSolutionJLD2(filepath::AbstractString; keyword="solution")

Loads a `solution` of an FMU under dictionary `keyword` in a JLD2 file at `filepath`. 
(requires package JLD2.jl)

See also [`loadSolution`](@ref).
"""
function loadSolutionJLD2(filepath::AbstractString; keyword="solution")
    return JLD2.load(filepath, keyword)
end
export loadSolutionJLD2