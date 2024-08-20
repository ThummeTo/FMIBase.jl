#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

"""
Log levels for non-standard printing of infos, warnings and errors.
"""
const FMULogLevel = Cuint
const FMULogLevelNone = Cuint(0)
const FMULogLevelInfo = Cuint(1)
const FMULogLevelWarn = Cuint(2)
const FMULogLevelError = Cuint(3)
export FMULogLevel, FMULogLevelNone, FMULogLevelInfo, FMULogLevelWarn, FMULogLevelError
