#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

# Tests value-reference normalization and model-description metadata helpers using
# small synthetic FMI2/FMI3 descriptions, without loading or instantiating FMUs.
const FC = FMIBase.FMICore

# Minimal scalar-variable constructor helper for readable metadata fixtures.
function fmi2_scalar(
    name,
    vr,
    causality,
    variability,
    initial,
    attribute;
    description = nothing,
)
    mv = fmi2ScalarVariable(name, UInt32(vr), causality, variability, initial)
    mv.description = description
    mv.attribute = attribute
    return mv
end

function fmi2_md_fixture()
    md = fmi2ModelDescription()
    md.modelName = "Fixture2"
    md.generationTool = "FMIBase tests"
    md.numberOfEventIndicators = UInt32(2)
    md.defaultExperiment = FC.fmi2ModelDescriptionDefaultExperiment()
    md.defaultExperiment.startTime = 0.0
    md.defaultExperiment.stopTime = 10.0
    md.defaultExperiment.tolerance = 1e-6
    md.defaultExperiment.stepSize = 0.1

    md.coSimulation = FC.fmi2ModelDescriptionCoSimulation("cs_fixture")
    md.coSimulation.canGetAndSetFMUstate = true
    md.coSimulation.canSerializeFMUstate = false
    md.coSimulation.providesDirectionalDerivative = true
    md.modelExchange = FC.fmi2ModelDescriptionModelExchange("me_fixture")

    real_attr = FC.fmi2RealAttributesExt()
    real_attr.unit = "m"
    real_attr.start = 1.5
    input_attr = FC.fmi2RealAttributesExt()
    input_attr.start = 2.5
    int_attr = FC.fmi2IntegerAttributesExt()
    int_attr.start = Int32(3)

    md.modelVariables = [
        fmi2_scalar(
            "x",
            1,
            fmi2CausalityLocal,
            fmi2VariabilityContinuous,
            fmi2InitialExact,
            real_attr;
            description = "state",
        ),
        fmi2_scalar(
            "der(x)",
            2,
            fmi2CausalityLocal,
            fmi2VariabilityContinuous,
            fmi2InitialCalculated,
            real_attr,
        ),
        fmi2_scalar(
            "u",
            3,
            fmi2CausalityInput,
            fmi2VariabilityContinuous,
            fmi2InitialApprox,
            input_attr,
        ),
        fmi2_scalar(
            "p",
            4,
            fmi2CausalityParameter,
            fmi2VariabilityFixed,
            fmi2InitialExact,
            int_attr,
        ),
        fmi2_scalar(
            "alias_x",
            1,
            fmi2CausalityOutput,
            fmi2VariabilityContinuous,
            fmi2InitialCalculated,
            real_attr,
        ),
    ]

    md.valueReferences = fmi2ValueReference[1, 2, 3, 4]
    md.stateValueReferences = fmi2ValueReference[1]
    md.derivativeValueReferences = fmi2ValueReference[2]
    md.inputValueReferences = fmi2ValueReference[3]
    md.outputValueReferences = fmi2ValueReference[1]
    md.parameterValueReferences = fmi2ValueReference[4]
    md.stringValueReferences = Dict(
        "x" => fmi2ValueReference(1),
        "der(x)" => fmi2ValueReference(2),
        "u" => fmi2ValueReference(3),
        "p" => fmi2ValueReference(4),
        "alias_x" => fmi2ValueReference(1),
    )
    md.unitDefinitions = [FC.fmi2Unit("m")]
    return md
end

# FMI3 fixture focused on Scheduled Execution and direct variable metadata.
function fmi3_md_fixture()
    md = fmi3ModelDescription()
    md.modelName = "Fixture3"
    md.instantiationToken = "token"
    md.defaultExperiment = FC.fmi3ModelDescriptionDefaultExperiment()
    md.defaultExperiment.startTime = 1.0
    md.defaultExperiment.stopTime = 2.0
    md.defaultExperiment.tolerance = 1e-4
    md.defaultExperiment.stepSize = 0.25
    md.scheduledExecution = FC.fmi3ModelDescriptionScheduledExecution("se_fixture")
    md.scheduledExecution.canGetAndSetFMUState = true
    md.scheduledExecution.canSerializeFMUState = true
    md.scheduledExecution.providesDirectionalDerivatives = true
    md.scheduledExecution.providesAdjointDerivatives = true
    md.coSimulation = nothing
    md.modelExchange = nothing

    x = FC.fmi3VariableFloat64("x3", UInt32(11))
    x.causality = fmi3CausalityOutput
    x.variability = fmi3VariabilityContinuous
    x.initial = fmi3InitialExact
    x.start = 4.0
    x.unit = "s"

    md.modelVariables = [x]
    md.valueReferences = fmi3ValueReference[11]
    md.outputValueReferences = fmi3ValueReference[11]
    md.stateValueReferences = fmi3ValueReference[]
    md.derivativeValueReferences = fmi3ValueReference[]
    md.inputValueReferences = fmi3ValueReference[]
    md.parameterValueReferences = fmi3ValueReference[]
    md.stringValueReferences = Dict("x3" => fmi3ValueReference(11))
    return md
end

@testset "value reference preparation and metadata helpers" begin
    md = fmi2_md_fixture()

    @test prepareValueReference(md, fmiValueReference(1)) == fmiValueReference[1]
    @test prepareValueReference(md, fmiValueReference[1, 2]) == fmiValueReference[1, 2]
    @test prepareValueReference(md, "u") == fmiValueReference[3]
    @test prepareValueReference(md, ["x", "p"]) == fmiValueReference[1, 4]
    @test prepareValueReference(md, nothing) == fmiValueReference[]
    @test prepareValueReference(md, 4) == fmiValueReference[4]
    @test prepareValueReference(md, [1, 3]) == fmiValueReference[1, 3]
    @test prepareValueReference(md, :states) == fmiValueReference[1]
    @test prepareValueReference(md, :derivatives) == fmiValueReference[2]
    @test prepareValueReference(md, :inputs) == fmiValueReference[3]
    @test prepareValueReference(md, :outputs) == fmiValueReference[1]
    @test prepareValueReference(md, :all) == fmiValueReference[1, 2, 3, 4]
    @test prepareValueReference(md, :none) == fmiValueReference[]
    @test_throws AssertionError prepareValueReference(md, :unknown)
    @test prepareValue(1.0) == [1.0]
    values = [1.0, 2.0]
    @test prepareValue(values) === values

    @test stringToValueReference(md, "x") == fmi2ValueReference(1)
    @test stringToValueReference(md, ["x", "u"]) == fmi2ValueReference[1, 3]
    @test modelVariablesForValueReference(md, fmi2ValueReference(1)) ==
          [md.modelVariables[1], md.modelVariables[5]]
    @test dataTypeForValueReference(md, fmi2ValueReference(1)) == fmi2Real
    @test dataTypeForValueReference(md, fmi2ValueReference(4)) == fmi2Integer
    @test valueReferenceToString(md, fmi2ValueReference(1)) == ["x", "alias_x"]

    @test getModelIdentifier(md) == "cs_fixture"
    @test getModelIdentifier(md; type = fmi2TypeModelExchange) == "me_fixture"
    @test getModelName(md) == "Fixture2"
    @test getDefaultStartTime(md) == 0.0
    @test getDefaultStopTime(md) == 10.0
    @test getDefaultTolerance(md) == 1e-6
    @test getDefaultStepSize(md) == 0.1
    @test getGenerationTool(md) == "FMIBase tests"
    @test getNumberOfEventIndicators(md) == 2
    @test getNumberOfStates(md) == 1
    @test isCoSimulation(md)
    @test isModelExchange(md)
    @test !isScheduledExecution(md)

    @test getNames(md; vrs = fmi2ValueReference[1], mode = :first) == ["x"]
    @test getNames(md; vrs = fmi2ValueReference[1], mode = :group) == [["x", "alias_x"]]
    @test getNames(md; vrs = fmi2ValueReference[1], mode = :flat) == ["x", "alias_x"]
    @test getInputNames(md) == ["u"]
    @test getOutputNames(md) == ["x"]
    @test getParameterNames(md) == ["p"]
    @test getStateNames(md) == ["x"]
    @test getDerivativeNames(md) == ["der(x)"]
    @test getModelVariableIndices(md; vrs = fmi2ValueReference[1]) == [1, 5]
    @test getInputValueReferencesAndNames(md) == Dict(fmi2ValueReference(3) => ["u"])
    @test getNamesAndDescriptions(md)["x"] == "state"
    @test getNamesAndUnits(md)["x"] == "m"
    @test getNamesAndInitials(md)["x"] == fmi2InitialExact
    @test getInputNamesAndStarts(md) == Dict("u" => 2.5)
    @test getStartValue(md, "x") == 1.5
    @test getStartValue(md, ["x", "p"]) == [1.5, Int32(3)]
    @test getUnit(md.modelVariables[1]) == "m"
    @test getUnit(md, md.modelVariables[1]) == md.unitDefinitions[1]
    @test getInitial(md.modelVariables[1]) == fmi2InitialExact
    @test canGetSetFMUState(md)
    @test !canSerializeFMUState(md)
    @test providesDirectionalDerivatives(md)
    @test !providesAdjointDerivatives(md)
    @test getInstantiationToken(md) === nothing

    no_defaults = fmi2ModelDescription()
    @test getDefaultStartTime(no_defaults) === nothing
    @test getDefaultStopTime(no_defaults) === nothing
    @test getDefaultTolerance(no_defaults) === nothing
    @test getDefaultStepSize(no_defaults) === nothing

    md3 = fmi3_md_fixture()
    @test stringToDataType(md3, "Float64") == fmi3Float64
    @test stringToDataType(md, "Real") == fmi2Real
    @test getModelIdentifier(md3) == "se_fixture"
    @test isScheduledExecution(md3)
    @test canGetSetFMUState(md3)
    @test canSerializeFMUState(md3)
    @test providesDirectionalDerivatives(md3)
    @test providesAdjointDerivatives(md3)
    @test getInstantiationToken(md3) == "token"
    @test getStartValue(md3, "x3") == 4.0
    @test getUnit(md3.modelVariables[1]) == "s"
    @test dataTypeForValueReference(md3, fmi3ValueReference(11)) == fmi3Float64
end
