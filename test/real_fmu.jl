#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

# Integration smoke tests with a real FMI2 FMU from FMIZoo. Raw loading and
# component-level C-call shims are kept local so the assertions exercise FMIBase
# value access and snapshot behavior without taking a test dependency on FMIImport.

using Downloads
using Libdl

const BB_FMU_URL = "https://github.com/ThummeTo/FMIZoo.jl/raw/main/models/bin/Dymola/2023x/2.0/BouncingBallGravitySwitch1D.fmu"

function unzip_fmu(dlpath::AbstractString, fmuname::AbstractString)
    unpack_path = mktempdir(; prefix = "fmibase_", cleanup = true)
    unzipped_path = joinpath(unpack_path, fmuname)
    mkpath(unzipped_path)

    archive = FMIBase.ZipFile.Reader(dlpath)
    try
        for file in archive.files
            file_path = normpath(joinpath(unzipped_path, file.name))
            @assert startswith(file_path, unzipped_path) "Unsafe path in FMU archive: $(file.name)"
            if endswith(file.name, "/") || endswith(file.name, "\\")
                mkpath(file_path)
            else
                mkpath(dirname(file_path))
                write(file_path, read(file))
            end
        end
    finally
        close(archive)
    end

    return unzipped_path
end

function fmi2_demo_binary_paths()
    fmuname = "BouncingBallGravitySwitch1D"
    dlpath = Downloads.download(BB_FMU_URL)
    fmu_path = unzip_fmu(dlpath, fmuname)

    if Sys.WORD_SIZE != 64
        return nothing
    elseif Sys.islinux()
        binary_dir = joinpath(fmu_path, "binaries", "linux64")
        callback_url = "https://github.com/ThummeTo/FMIImport.jl/raw/main/src/FMI2/callbackFunctions/binaries/linux64/libcallbackFunctions.so"
    elseif Sys.iswindows()
        binary_dir = joinpath(fmu_path, "binaries", "win64")
        callback_url = "https://github.com/ThummeTo/FMIImport.jl/raw/main/src/FMI2/callbackFunctions/binaries/win64/callbackFunctions.dll"
    else
        return nothing
    end

    binary_candidates =
        [joinpath(binary_dir, fmuname), joinpath(binary_dir, fmuname * "." * Libdl.dlext)]
    binary_path = something(findfirst(isfile, binary_candidates), nothing)
    if isnothing(binary_path)
        matches =
            filter(name -> startswith(name, fmuname), readdir(binary_dir; join = true))
        binary_path = isempty(matches) ? "" : first(matches)
    else
        binary_path = binary_candidates[binary_path]
    end

    callback_path = Downloads.download(callback_url)
    if !Sys.iswindows()
        chmod(callback_path, 0o755)
    end

    return (; binary_path, callback_path)
end

function fmi2_callback_functions(callback_path::AbstractString)
    callback_lib = dlopen(callback_path)
    component_environment = FMU2ComponentEnvironment()
    callback_functions = fmi2CallbackFunctions(
        dlsym(callback_lib, :logger),
        C_NULL,
        C_NULL,
        C_NULL,
        Ptr{FMU2ComponentEnvironment}(pointer_from_objref(component_environment)),
    )
    return (; callback_lib, component_environment, callback_functions)
end

# FMIBase normally receives these component-level methods from FMIImport. For this
# integration test we provide the small subset needed to drive a real component.
function FMIBase.FMICore.fmi2GetReal!(
    c::FMU2Component,
    refs::AbstractArray{fmi2ValueReference},
    nrefs::Csize_t,
    values::AbstractArray{fmi2Real},
)
    return fmi2GetReal!(c.fmu.cGetReal, c.addr, refs, nrefs, values)
end

function FMIBase.FMICore.fmi2GetReal!(
    c::FMU2Component,
    refs::AbstractArray{fmi2ValueReference},
    values::AbstractArray{fmi2Real},
)
    return fmi2GetReal!(c, refs, Csize_t(length(refs)), values)
end

function FMIBase.FMICore.fmi2SetReal(
    c::FMU2Component,
    refs::AbstractArray{fmi2ValueReference},
    nrefs::Csize_t,
    values::AbstractArray{fmi2Real};
    kwargs...,
)
    return fmi2SetReal(c.fmu.cSetReal, c.addr, refs, nrefs, values)
end

function FMIBase.FMICore.fmi2SetReal(
    c::FMU2Component,
    refs::AbstractArray{fmi2ValueReference},
    values::AbstractArray{<:Real};
    kwargs...,
)
    return fmi2SetReal(c, refs, Csize_t(length(refs)), fmi2Real.(values))
end

function FMIBase.FMICore.fmi2SetReal(
    c::FMU2Component,
    ref::fmi2ValueReference,
    value::Real;
    kwargs...,
)
    return fmi2SetReal(c, [ref], Csize_t(1), fmi2Real[value])
end

function FMIBase.FMICore.fmi2GetContinuousStates!(
    c::FMU2Component,
    states::AbstractArray{fmi2Real},
    nstates::Csize_t,
)
    return fmi2GetContinuousStates!(c.fmu.cGetContinuousStates, c.addr, states, nstates)
end

function FMIBase.FMICore.fmi2SetContinuousStates(
    c::FMU2Component,
    states::AbstractArray{fmi2Real},
)
    return fmi2SetContinuousStates(
        c.fmu.cSetContinuousStates,
        c.addr,
        states,
        Csize_t(length(states)),
    )
end

function FMIBase.FMICore.fmi2SetTime(c::FMU2Component, t::fmi2Real; kwargs...)
    return fmi2SetTime(c.fmu.cSetTime, c.addr, t)
end

function minimal_real_fmu2(lib)
    fmu = FMU2()
    fmu.type = fmi2TypeModelExchange
    fmu.isZeroState = false
    fmu.isDummyDiscrete = false

    md = fmi2ModelDescription()
    md.modelName = "BouncingBallGravitySwitch1D"
    md.numberOfEventIndicators = UInt32(2)
    md.modelExchange =
        FMIBase.FMICore.fmi2ModelDescriptionModelExchange("BouncingBallGravitySwitch1D")
    md.modelExchange.canGetAndSetFMUstate = true
    md.modelExchange.canSerializeFMUstate = true

    gravity_attr = FMIBase.FMICore.fmi2RealAttributesExt()
    gravity_attr.start = 9.81
    gravity = fmi2ScalarVariable(
        "gravity",
        fmi2ValueReference(16777220),
        fmi2CausalityParameter,
        fmi2VariabilityFixed,
        fmi2InitialExact,
    )
    gravity.attribute = gravity_attr

    md.modelVariables = [gravity]
    md.valueReferences = fmi2ValueReference[16777220]
    md.parameterValueReferences = fmi2ValueReference[16777220]
    md.stateValueReferences = fmi2ValueReference[33554432, 33554433]
    md.discreteStateValueReferences = fmi2ValueReference[]
    md.stringValueReferences = Dict("gravity" => fmi2ValueReference(16777220))
    fmu.modelDescription = md

    fmu.executionConfig.snapshotDeltaTimeTolerance = 1e-9
    fmu.cGetReal = dlsym(lib, :fmi2GetReal)
    fmu.cSetReal = dlsym(lib, :fmi2SetReal)
    fmu.cSetTime = dlsym(lib, :fmi2SetTime)
    fmu.cGetContinuousStates = dlsym(lib, :fmi2GetContinuousStates)
    fmu.cSetContinuousStates = dlsym(lib, :fmi2SetContinuousStates)
    fmu.cGetFMUstate = dlsym(lib, :fmi2GetFMUstate)
    fmu.cSetFMUstate = dlsym(lib, :fmi2SetFMUstate)
    fmu.cFreeFMUstate = dlsym(lib, :fmi2FreeFMUstate)
    fmu.cFreeInstance = dlsym(lib, :fmi2FreeInstance)
    return fmu
end

@testset "real FMI2 FMU smoke test" begin
    paths = fmi2_demo_binary_paths()
    if isnothing(paths) || !isfile(paths.binary_path)
        @test_skip "No compatible demo FMI2 FMU binary for this platform."
    else
        lib = dlopen(paths.binary_path)
        callbacks = fmi2_callback_functions(paths.callback_path)
        component = fmi2Instantiate(
            dlsym(lib, :fmi2Instantiate),
            pointer("fmibase_real_fmu"),
            fmi2TypeModelExchange,
            pointer("{3c564ab6-a92a-48ca-ae7d-591f819b1d93}"),
            pointer("file:///"),
            Ptr{fmi2CallbackFunctions}(pointer_from_objref(callbacks.callback_functions)),
            fmi2False,
            fmi2False,
        )
        @test component != C_NULL

        fmu = minimal_real_fmu2(lib)
        comp = FMU2Component(component, fmu)
        fmu.threadInstances[Threads.threadid()] = comp

        try
            @test canGetSetFMUState(fmu)
            @test hasCurrentInstance(fmu)
            @test getCurrentInstance(fmu) === comp

            @test fmi2StatusOK == fmi2SetupExperiment(
                dlsym(lib, :fmi2SetupExperiment),
                component,
                fmi2False,
                fmi2Real(0.0),
                fmi2Real(0.0),
                fmi2False,
                fmi2Real(1.0),
            )
            @test fmi2StatusOK == fmi2EnterInitializationMode(
                dlsym(lib, :fmi2EnterInitializationMode),
                component,
            )

            @test setValue(comp, "gravity", [0.8]) == [fmi2StatusOK]
            @test getValue(comp, "gravity"; T = Float64) == 0.8

            @test fmi2StatusOK == fmi2ExitInitializationMode(
                dlsym(lib, :fmi2ExitInitializationMode),
                component,
            )
            @test fmi2StatusOK == fmi2NewDiscreteStates!(
                dlsym(lib, :fmi2NewDiscreteStates),
                component,
                Ptr{fmi2EventInfo}(pointer_from_objref(comp.eventInfo)),
            )
            @test fmi2StatusOK == fmi2EnterContinuousTimeMode(
                dlsym(lib, :fmi2EnterContinuousTimeMode),
                component,
            )
            comp.state = fmi2ComponentStateContinuousTimeMode
            comp.t = fmi2Real(0.0)
            comp.default_t = fmi2Real(0.0)

            state = FMIBase.getFMUState(comp)
            @test typeof(state) == fmi2FMUstate
            @test fmi2StatusOK == FMIBase.setFMUState!(comp, state)

            state_ref = Ref(state)
            FMIBase.freeFMUState!(comp, state_ref)
            @test state_ref[] == C_NULL

            sn = snapshot!(comp)
            @test sn.valid
            @test sn.t == 0.0
            @test length(sn.x_c) == 2
            @test getSnapshot(comp, 0.0) === sn
            @test snapshot_if_needed!(comp, 0.0) === sn
            comp.x = copy(sn.x_c)
            comp.x_d = copy(sn.x_d)

            sn2 = snapshot_or_update!(comp, 0.0)
            @test sn2 === sn
            @test sn2.valid

            apply!(comp, sn)
            @test comp.t == 0.0

            freeSnapshot!(sn)
            @test !sn.valid
            reused = snapshot!(comp)
            @test reused === sn
            @test reused.valid
        finally
            fmi2FreeInstance(fmu.cFreeInstance, component)
            dlclose(callbacks.callback_lib)
            dlclose(lib)
        end
    end
end
