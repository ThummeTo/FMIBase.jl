#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

# Tests string/enum conversion helpers for FMI2 and FMI3, including roundtrips and
# intentionally different unknown-value behavior between the two standards.
@testset "conversion helpers" begin
    fmi2 = FMU2()
    fmi3 = FMU3()

    @testset "FMI2 roundtrips" begin
        for (status, str) in (
            fmi2StatusOK => "OK",
            fmi2StatusWarning => "Warning",
            fmi2StatusDiscard => "Discard",
            fmi2StatusError => "Error",
            fmi2StatusFatal => "Fatal",
            fmi2StatusPending => "Pending",
        )
            @test statusToString(fmi2, status) == str
            @test stringToStatus(fmi2, str) == status
        end

        for (causality, str) in (
            fmi2CausalityParameter => "parameter",
            fmi2CausalityCalculatedParameter => "calculatedParameter",
            fmi2CausalityInput => "input",
            fmi2CausalityOutput => "output",
            fmi2CausalityLocal => "local",
            fmi2CausalityIndependent => "independent",
        )
            @test causalityToString(fmi2, causality) == str
            @test stringToCausality(fmi2, str) == causality
        end

        for (variability, str) in (
            fmi2VariabilityConstant => "constant",
            fmi2VariabilityFixed => "fixed",
            fmi2VariabilityTunable => "tunable",
            fmi2VariabilityDiscrete => "discrete",
            fmi2VariabilityContinuous => "continuous",
        )
            @test variabilityToString(fmi2, variability) == str
            @test stringToVariability(fmi2, str) == variability
        end

        for (initial, str) in (
            fmi2InitialApprox => "approx",
            fmi2InitialExact => "exact",
            fmi2InitialCalculated => "calculated",
        )
            @test initialToString(fmi2, initial) == str
            @test stringToInitial(fmi2, str) == initial
        end

        for (kind, str) in (
            fmi2DependencyKindDependent => "dependent",
            fmi2DependencyKindConstant => "constant",
            fmi2DependencyKindFixed => "fixed",
            fmi2DependencyKindTunable => "tunable",
            fmi2DependencyKindDiscrete => "discrete",
        )
            @test dependencyKindToString(fmi2, kind) == str
            @test stringToDependencyKind(fmi2, str) == kind
        end

        @test_throws AssertionError statusToString(fmi2, typemax(Int32))
        @test_throws AssertionError stringToStatus(fmi2, "missing")
    end

    @testset "FMI3 roundtrips" begin
        for (status, str) in (
            fmi3StatusOK => "OK",
            fmi3StatusWarning => "Warning",
            fmi3StatusDiscard => "Discard",
            fmi3StatusError => "Error",
            fmi3StatusFatal => "Fatal",
        )
            @test statusToString(fmi3, status) == str
            @test stringToStatus(fmi3, str) == status
            @test statusToString(Int(status)) == str
        end

        @test statusToString(fmi3, typemax(Int32)) == "Unknown"
        @test stringToStatus(fmi3, "missing") == "Unknown"

        for (causality, str) in (
            fmi3CausalityParameter => "parameter",
            fmi3CausalityCalculatedParameter => "calculatedParameter",
            fmi3CausalityInput => "input",
            fmi3CausalityOutput => "output",
            fmi3CausalityLocal => "local",
            fmi3CausalityIndependent => "independent",
            fmi3CausalityStructuralParameter => "structuralParameter",
        )
            @test causalityToString(fmi3, causality) == str
            @test stringToCausality(fmi3, str) == causality
        end

        for (variability, str) in (
            fmi3VariabilityConstant => "constant",
            fmi3VariabilityFixed => "fixed",
            fmi3VariabilityTunable => "tunable",
            fmi3VariabilityDiscrete => "discrete",
            fmi3VariabilityContinuous => "continuous",
        )
            @test variabilityToString(fmi3, variability) == str
            @test stringToVariability(fmi3, str) == variability
        end

        for (initial, str) in (
            fmi3InitialApprox => "approx",
            fmi3InitialExact => "exact",
            fmi3InitialCalculated => "calculated",
        )
            @test initialToString(fmi3, initial) == str
            @test stringToInitial(fmi3, str) == initial
        end

        for (kind, str) in (
            fmi3DependencyKindIndependent => "independent",
            fmi3DependencyKindConstant => "constant",
            fmi3DependencyKindFixed => "fixed",
            fmi3DependencyKindTunable => "tunable",
            fmi3DependencyKindDiscrete => "discrete",
            fmi3DependencyKindDependent => "dependent",
        )
            @test dependencyKindToString(fmi3, kind) == str
            @test stringToDependencyKind(fmi3, str) == kind
        end

        @test variableNamingConventionToString(fmi3, fmi3VariableNamingConventionFlat) ==
              "flat"
        @test stringToVariableNamingConvention(fmi3, "structured") ==
              fmi3VariableNamingConventionStructured
        @test typeToString(fmi3, fmi3TypeCoSimulation) == "coSimulation"
        @test stringToType(fmi3, "scheduledExecution") == fmi3TypeScheduledExecution
        @test intervalQualifierToString(fmi3, fmi3IntervalQualifierIntervalChanged) ==
              "intervalChanged"
        @test stringToIntervalQualifier(fmi3, "intervalUnchanged") ==
              fmi3IntervalQualifierIntervalUnchanged
    end
end
