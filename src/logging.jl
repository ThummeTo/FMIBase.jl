#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

function logInfo(component::FMU2Component, message, status::fmi2Status = fmi2StatusOK)
    if component.loggingOn == fmi2True
        ccall(
            component.callbackFunctions.logger,
            Cvoid,
            (fmi2ComponentEnvironment, fmi2String, fmi2Status, fmi2String, fmi2String),
            component.callbackFunctions.componentEnvironment,
            component.instanceName,
            status,
            "info",
            message * "\n",
        )
    end
end
function logInfo(component::FMU3Instance, message, status::fmi3Status = fmi3StatusOK)
    @assert false, "Not implemented yet. Please open an issue." # [TODO]
end
function logInfo(::Nothing, message, status::fmi2Status = fmi2StatusOK)
    @info "logInfo(nothing, $(message), $(status))"
end

function logWarning(
    component::FMU2Component,
    message,
    status::fmi2Status = fmi2StatusWarning,
)
    if component.loggingOn == fmi2True
        ccall(
            component.callbackFunctions.logger,
            Cvoid,
            (fmi2ComponentEnvironment, fmi2String, fmi2Status, fmi2String, fmi2String),
            component.callbackFunctions.componentEnvironment,
            component.instanceName,
            status,
            "warning",
            message * "\n",
        )
    end
end
function logWarning(
    component::FMU3Instance,
    message,
    status::fmi3Status = fmi3StatusWarning,
)
    @assert false, "Not implemented yet. Please open an issue." # [TODO]
end
function logWarning(::Nothing, message, status::fmi2Status = fmi2StatusOK)
    @warn "logWarning(nothing, $(message), $(status))"
end

function logError(component::FMU2Component, message, status::fmi2Status = fmi2StatusError)
    if component.loggingOn == fmi2True
        ccall(
            component.callbackFunctions.logger,
            Cvoid,
            (fmi2ComponentEnvironment, fmi2String, fmi2Status, fmi2String, fmi2String),
            component.callbackFunctions.componentEnvironment,
            component.instanceName,
            status,
            "error",
            message * "\n",
        )
    end
end
function logError(component::FMU3Instance, message, status::fmi3Status = fmi3StatusError)
    @assert false, "Not implemented yet. Please open an issue." # [TODO]
end
function logError(::Nothing, message, status::fmi2Status = fmi2StatusOK)
    @error "logError(nothing, $(message), $(status))"
end
