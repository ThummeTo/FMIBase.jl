#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

"""
Prints a message with level `info` if the log level allows it.
"""
function logInfo(fmu::FMU, message, maxlog=typemax(Int))
    if fmu.logLevel <= FMULogLevelInfo
        if maxlog == 1 
            message *= "\n(This message is only printed once.)"
            @info message maxlog=1
        else
            @info message maxlog=maxlog
        end
    end
end
export logInfo

"""
Prints a message with level `warn` if the log level allows it.
"""
function logWarning(fmu::FMU, message, maxlog=typemax(Int))
    if fmu.logLevel <= FMULogLevelWarn
        if maxlog == 1 
            message *= "\n(This message is only printed once.)"
            @warn message maxlog=1
        else
            @warn message maxlog=maxlog
        end
    end
end
export logWarning

"""
Prints a message with level `error` if the log level allows it.
"""
function logError(fmu::FMU, message, maxlog=typemax(Int))
    if fmu.logLevel <= FMULogLevelError
        if maxlog == 1 
            message *= "\n(This message is only printed once.)"
            @error message maxlog=1
        else
            @error message maxlog=maxlog
        end
    end
end
export logError

