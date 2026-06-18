#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

# Tests lightweight struct behavior, solution accessors, and thread-local instance
# helpers without requiring a real FMU or an ODE/SciML solution object.

# Minimal stand-in for saved callback values. This keeps solution accessor tests
# focused on FMIBase behavior without loading additional solver dependencies.
struct FakeSavedValues
    t::Vector{Float64}
    saveval::Vector{Vector{Float64}}
end

Base.length(values::FakeSavedValues) = length(values.t)

@testset "struct defaults and solution helpers" begin
    cfg = FMUExecutionConfiguration()
    @test cfg.terminate
    @test cfg.reset
    @test cfg.setup
    @test !cfg.instantiate
    @test !cfg.freeInstance
    @test !cfg.loggingOn
    @test cfg.externalCallbacks
    @test cfg.rootSearchInterpolationPoints == 10
    @test cfg.sensitivity_strategy == :FMIDirectionalDerivative
    @test cfg.max_snapshots == UInt(1e4)

    @test FMU_EXECUTION_CONFIGURATION_RESET.reset
    @test !FMU_EXECUTION_CONFIGURATION_NO_RESET.reset
    @test FMU_EXECUTION_CONFIGURATION_NO_RESET.instantiate
    @test !FMU_EXECUTION_CONFIGURATION_NO_FREEING.freeInstance
    @test !FMU_EXECUTION_CONFIGURATION_NOTHING.setup
    @test length(FMU_EXECUTION_CONFIGURATIONS) == 4

    time_event = FMUEvent(1.25, UInt(0))
    state_event = FMUEvent(2.0, UInt(3), [1.0], [2.0], 0.0)
    @test sprint(show, time_event) == "Time-Event @ 1.25s (state-change: false)"
    @test sprint(show, state_event) == "State-Event #3 @ 2.0s (state-change: true)"

    sol = FMUSolution{Nothing}()
    @test !sol.success
    @test isempty(sol.snapshots)
    @test isempty(sol.events)
    @test sol.states === nothing
    @test sol.values === nothing
    @test sol.valueReferences === nothing
    @test sol.evals_fx_inplace == 0

    sol.values = FakeSavedValues([0.0, 1.0], [[10.0, 20.0], [11.0, 21.0]])
    sol.valueReferences = fmi2ValueReference[1, 2]
    @test getTime(sol) == [0.0, 1.0]
    @test getValue(sol, 1; isIndex = true) == [10.0, 11.0]
    @test getValue(sol, [1, 2]; isIndex = true) == [[10.0, 11.0], [20.0, 21.0]]

    empty_sol = FMUSolution{Nothing}()
    @test getTime(empty_sol) === nothing

    fmu = FMU2()
    @test !hasCurrentInstance(fmu)
    comp = FMU2Component{FMU2}()
    comp.fmu = fmu
    fmu.threadInstances[Threads.threadid()] = comp
    @test hasCurrentInstance(fmu)
    @test getCurrentInstance(fmu) === comp
end
