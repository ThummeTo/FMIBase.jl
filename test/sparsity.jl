#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

@testset "AbstractDependencyMatrix" begin
    @test isabstracttype(AbstractDependencyMatrix)
end

@testset "FMUExecutionConfiguration sparsity defaults" begin
    cfg = FMUExecutionConfiguration()
    @test cfg.load_dep_matrix == true
    @test cfg.use_jac_prototype == true
end

@testset "FMU2 sparsity fields" begin
    fmu = FMU2()
    @test isnothing(fmu.dependencyMatrix)
    @test isnothing(fmu.jac_prototype)
end

@testset "FMU3 sparsity fields" begin
    fmu = FMU3()
    @test isnothing(fmu.dependencyMatrix)
    @test isnothing(fmu.jac_prototype)
end
