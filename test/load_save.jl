#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

# Tests generic save/load dispatch, especially forwarding the caller-provided
# JLD2 keyword through the format-selecting wrapper functions.

function serializable_solution_fixture()
    sol = FMUSolution{Nothing}()
    sol.instance = nothing
    sol.success = true
    sol.eventIndicators = nothing
    return sol
end

@testset "load/save dispatch" begin
    filepath = joinpath(mktempdir(; cleanup = true), "solution.jld2")
    keyword = "custom_solution"
    sol = serializable_solution_fixture()

    FMIBase.saveSolution(sol, filepath; keyword = keyword)

    @test FMIBase.loadSolution(filepath; keyword = keyword).success
    @test !haskey(JLD2.load(filepath), "solution")
    @test JLD2.load(filepath, keyword).success
end
