#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

"""
    saveSolutionMAT(solution::FMUSolution, filepath::AbstractString) 

Saves a `solution` of an FMU under dictionary `keyword` in a MAT file at `filepath`. 
(requires package MAT.jl)
    
See also [`saveSolution`](@ref).
"""
function saveSolutionMAT(solution::FMUSolution, filepath::AbstractString) 
    # [ToDo]
    @assert false, "Not implemented yet, please open an issue if this is needed."
end
export saveSolutionMAT

"""
    loadSolutionMAT(solution::FMUSolution, filepath::AbstractString)

Loads a `solution` of an FMU in a MAT file at `filepath`. 
(requires package MAT.jl)

See also [`loadSolution`](@ref).
"""
function loadSolutionMAT(solution::FMUSolution, filepath::AbstractString) 
    # [ToDo]
    @assert false, "Not implemented yet, please open an issue if this is needed."
end
export loadSolutionMAT