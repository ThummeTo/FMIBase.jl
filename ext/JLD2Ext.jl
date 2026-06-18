#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

module JLD2Ext

using FMIBase, JLD2

"""
    saveSolutionJLD2(solution::FMUSolution, filepath::AbstractString; keyword="solution") 

Saves a `solution` of an FMU under dictionary `keyword` in a JLD2 file at `filepath`. 
(requires package JLD2.jl)

See also [`saveSolution`](@ref).
"""
function FMIBase.saveSolutionJLD2(
    solution::FMUSolution,
    filepath::AbstractString;
    keyword = "solution",
)
    return JLD2.jldopen(filepath, "w") do file
        file[keyword] = solution
    end
end
export saveSolutionJLD2

"""
    loadSolutionJLD2(filepath::AbstractString; keyword="solution")

Loads a `solution` of an FMU under dictionary `keyword` in a JLD2 file at `filepath`. 
(requires package JLD2.jl)

See also [`loadSolution`](@ref).
"""
function FMIBase.loadSolutionJLD2(filepath::AbstractString; keyword = "solution")
    return JLD2.jldopen(filepath, "r") do file
        file[keyword]
    end
end
export loadSolutionJLD2

end # JLD2Ext
