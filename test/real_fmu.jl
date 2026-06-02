#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

# Integration smoke tests with a real FMI2 FMU from FMIZoo. These intentionally
# stay at FMIBase-owned behavior: wrapping a real component and using FMIBase's
# FMU-state helpers, while raw loading/instantiation remains a small test fixture.

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

function minimal_real_fmu2(lib)
    fmu = FMU2()
    fmu.type = fmi2TypeCoSimulation
    fmu.isZeroState = false
    fmu.isDummyDiscrete = false

    md = fmi2ModelDescription()
    md.modelName = "BouncingBallGravitySwitch1D"
    md.numberOfEventIndicators = UInt32(2)
    md.coSimulation =
        FMIBase.FMICore.fmi2ModelDescriptionCoSimulation("BouncingBallGravitySwitch1D")
    md.coSimulation.canGetAndSetFMUstate = true
    md.coSimulation.canSerializeFMUstate = true
    fmu.modelDescription = md

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
            fmi2TypeCoSimulation,
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

            state = FMIBase.getFMUState(comp)
            @test typeof(state) == fmi2FMUstate
            @test fmi2StatusOK == FMIBase.setFMUState!(comp, state)

            state_ref = Ref(state)
            FMIBase.freeFMUState!(comp, state_ref)
            @test state_ref[] == C_NULL
        finally
            fmi2FreeInstance(fmu.cFreeInstance, component)
            dlclose(callbacks.callback_lib)
            dlclose(lib)
        end
    end
end
