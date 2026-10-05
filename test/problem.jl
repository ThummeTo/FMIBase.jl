#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

function fmu_problem_fixture(type)
    fmu = FMU2()
    fmu.type = type
    fmu.isZeroState = false
    fmu.isDummyDiscrete = false

    md = fmi2ModelDescription()
    md.modelName = "ProblemFixture"
    md.numberOfEventIndicators = UInt32(0)
    md.defaultExperiment = FMIBase.FMICore.fmi2ModelDescriptionDefaultExperiment()
    md.defaultExperiment.startTime = 0.0
    md.defaultExperiment.stopTime = 1.0
    md.defaultExperiment.tolerance = 1e-6
    md.defaultExperiment.stepSize = 0.1
    md.stateValueReferences = fmi2ValueReference[1]
    md.derivativeValueReferences = fmi2ValueReference[2]
    md.discreteStateValueReferences = fmi2ValueReference[]

    if type == fmi2TypeModelExchange
        md.modelExchange = FMIBase.FMICore.fmi2ModelDescriptionModelExchange("me_fixture")
    elseif type == fmi2TypeCoSimulation
        md.coSimulation = FMIBase.FMICore.fmi2ModelDescriptionCoSimulation("cs_fixture")
    end

    fmu.modelDescription = md
    return fmu
end

@testset "FMUProblem interface" begin
    me = fmu_problem_fixture(fmi2TypeModelExchange)
    prob = FMUProblem(me; u0 = [1.0], saveat = 0.1)

    @test prob isa FMIBase.SciMLBase.AbstractODEProblem
    @test FMIBase.SciMLBase.isinplace(prob)
    @test prob.fmu === me
    @test prob.mode == :ME
    @test prob.tspan == (0.0, 1.0)
    @test prob.u0 == [1.0]
    @test prob.kwargs.saveat == 0.1
    @test prob.problem === nothing
    @test prob.callback === nothing

    remade = FMIBase.SciMLBase.remake(
        prob;
        u0 = [2.0],
        tspan = (1.0, 2.0),
        p = Dict("gain" => 3.0),
        saveat = 0.2,
    )
    @test remade !== prob
    @test remade.mode == :ME
    @test remade.u0 == [2.0]
    @test remade.tspan == (1.0, 2.0)
    @test remade.p == Dict("gain" => 3.0)
    @test remade.kwargs.parameters == Dict("gain" => 3.0)
    @test remade.kwargs.saveat == 0.2

    comp = FMU2Component(me)
    inst_prob = FMUProblem(comp, (0.0, 0.5); x0 = [0.5])
    @test inst_prob.fmu === me
    @test inst_prob.instance === comp
    @test inst_prob.u0 == [0.5]
    @test inst_prob.tspan == (0.0, 0.5)

    cs = fmu_problem_fixture(fmi2TypeCoSimulation)
    cs_prob = FMUProblem(cs)
    @test cs_prob.mode == :CS
    @test cs_prob.tspan == (0.0, 1.0)

    @test_throws ArgumentError FMUProblem(me; u0 = [1.0], x0 = [1.0])
    @test_throws ArgumentError FMUProblem(me; mode = :unknown)
    @test_throws ArgumentError FMIBase.SciMLBase.remake(prob; f = (du, u, p, t) -> du)
    @test_throws ArgumentError FMIBase.SciMLBase.solve(prob)
end
