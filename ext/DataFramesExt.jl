#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

module DataFramesExt

using FMIBase, DataFrames

"""
Converts a FMUSolution to DataFrame.
"""
function DataFrames.DataFrame(solution::FMUSolution)
    df = DataFrames.DataFrame(time = solution.values.t)
    for i = 1:length(solution.values.saveval[1])
        df[
            !,
            Symbol(
                valueReferenceToString(solution.instance.fmu, solution.valueReferences[i]),
            ),
        ] = [val[i] for val in solution.values.saveval]
    end
    # [ToDo] add states!
    return df
end

"""
Converts a DataFrame to FMUSolution (if pattern matches).
"""
function FMIBase.FMUSolution(df::DataFrames.DataFrame)
    # [ToDo]
    @assert false, "Not implemented yet, please open an issue if this is needed."
end

end # DataFramesExt
