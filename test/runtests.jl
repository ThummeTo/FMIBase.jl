#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

using FMIBase
using Test

# testing extensions
using CSV, DataFrames, ForwardDiff, JLD2, MAT, Plots, ReverseDiff

@testset "FMIBase.jl" begin
    include("convert.jl")
    include("valueRefs_md.jl")
    include("struct_solution.jl")
end
