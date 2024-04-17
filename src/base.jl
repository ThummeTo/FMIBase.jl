#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

FMI2Struct = Union{FMU2, fmi2ModelDescription, FMU2Component}
FMI3Struct = Union{FMU3, fmi3ModelDescription, FMU3Instance}
export FMI2Struct, FMI3Struct

# fortunately, fmi2ValueReference and fmi3ValueReference are the same, so we can define a wildcard:
const fmiValueReference = Union{fmi2ValueReference, fmi2ValueReference} # this will reduce to 
export fmiValueReference

# wildcards for how a user can pass a fmi2ValueReference | fmi3ValueReference
const fmi2ValueReferenceFormat = Union{Nothing, String, AbstractArray{String,1}, fmi2ValueReference, AbstractArray{fmi2ValueReference,1}, Int64, AbstractArray{Int64,1}, Symbol} 
const fmi3ValueReferenceFormat = Union{Nothing, String, AbstractArray{String,1}, fmi3ValueReference, AbstractArray{fmi3ValueReference,1}, Int64, AbstractArray{Int64,1}, Symbol} 
const fmiValueReferenceFormat = Union{fmi2ValueReferenceFormat, fmi3ValueReferenceFormat}
export fmiValueReferenceFormat, fmi2ValueReferenceFormat, fmi3ValueReferenceFormat

# default "empty" array values for function calls (to safe allocations)
const EMPTY_fmi2Real = zeros(fmi2Real, 0)
const EMPTY_fmi2ValueReference = zeros(fmi2ValueReference, 0)
getEmptyReal(::FMU2) = EMPTY_fmi2Real
getEmptyValueReference(::FMU2) = EMPTY_fmi2ValueReference
getEmptyReal(::FMU2Component) = EMPTY_fmi2Real
getEmptyValueReference(::FMU2Component) = EMPTY_fmi2ValueReference

const EMPTY_fmi3Float64 = zeros(fmi3Float64, 0)
const EMPTY_fmi3ValueReference = zeros(fmi3ValueReference, 0)
getEmptyReal(::FMU3) = EMPTY_fmi3Float64
getEmptyValueReference(::FMU3) = EMPTY_fmi3ValueReference
getEmptyReal(::FMU3Instance) = EMPTY_fmi3Float64
getEmptyValueReference(::FMU3Instance) = EMPTY_fmi3ValueReference

# wildcard for "no time set" 
const NO_fmi2Real = typemin(fmi2Real)
const NO_fmi3Float64 = typemin(fmi3Float64)
getNotSetReal(::FMU2) = NO_fmi2Real
getNotSetReal(::FMU3) = NO_fmi3Float64
isSetReal(::FMU2, val::fmi2Real) = (val != NO_fmi2Real)
isSetReal(::FMU3, val::fmi3Float64) = (val != NO_fmi3Float64)

# wildcard for "real type" 
getRealType(::FMU2) = fmi2Real
getRealType(::FMU3) = fmi3Float64
getRealType(::FMU2Component) = fmi2Real
getRealType(::FMU3Instance) = fmi3Float64

# check if is true 
isTrue(val::Bool) = val
isTrue(val::fmi2Boolean) = (val == fmi2True)
isTrue(val::fmi3Boolean) = (val == fmi3True)

# continuousTimeMode 
isContinuousTimeMode(c::FMU2Component) = (c.state == fmi2ComponentStateContinuousTimeMode)
isContinuousTimeMode(c::FMU3Instance)  = (c.state == fmi3InstanceStateContinuousTimeMode)