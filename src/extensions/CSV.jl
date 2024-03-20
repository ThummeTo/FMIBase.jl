#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

"""
    saveSolutionCSV(solution::FMUSolution, filepath::AbstractString)

Saves a `solution` of an FMU in a CSV file at `filepath`. 
(requires package CSV.jl and Dataframes.jl)

See also [`saveSolution`](@ref).
"""
function saveSolutionCSV(solution::FMUSolution, filepath::AbstractString) 
    df = DataFrames.DataFrame(solution)
    CSV.write(filepath, df)
end
export saveSolutionCSV

"""
    loadSolutionCSV(solution::FMUSolution, filepath::AbstractString)

Loads a `solution` of an FMU in a CSV file at `filepath`. 
(requires package CSV.jl and Dataframes.jl)

See also [`loadSolution`](@ref).
"""
function loadSolutionCSV(solution::FMUSolution, filepath::AbstractString) 
    # [ToDo]
    @assert false, "Not implemented yet, please open an issue if this is needed."
end
export loadSolutionCSV
