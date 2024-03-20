#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

"""
Converts a FMUSolution to DataFrame.
"""
function DataFrames.DataFrame(solution::FMUSolution) 
    df = DataFrames.DataFrame(time=solution.values.t)
    for i in 1:length(solution.values.saveval[1])
        df[!, Symbol(valueReferenceToString(solution.component.fmu, solution.valueReferences[i]))]=[val[i] for val in solution.values.saveval]
    end
    # [ToDo] add states!
    return df
end

"""
Converts a DataFrame to FMUSolution (if pattern matches).
"""
function FMIImport.FMIBase.FMUSolution(df::DataFrames.DataFrame)
    # [ToDo]
    @assert false, "Not implemented yet, please open an issue if this is needed."
end