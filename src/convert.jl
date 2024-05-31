#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

"""
    stringToDataType(modelDescription, typename)

Converts a typename to type, for example `"Float64"` (::String) to `fmi3Float64` (::DataType).
"""
function stringToDataType(::fmi3ModelDescription, typename::Union{String, SubString})
    if typename == "Float32"
        return fmi3Float32
    elseif typename == "Float64"
        return fmi3Float64
    elseif typename == "Int8"
        return fmi3Int8
    elseif typename == "UInt8"
        return fmi3UInt8
    elseif typename == "Int16"
        return fmi3Int16
    elseif typename == "UInt16"
        return fmi3UInt16
    elseif typename == "Int32"
        return fmi3Int32
    elseif typename == "UInt32"
        return fmi3UInt32
    elseif typename == "Int64"
        return fmi3Int64
    elseif typename == "UInt64"
        return fmi3UInt64
    elseif typename == "Boolean"
        return fmi3Boolean
    elseif typename == "String"
        return fmi3String
    elseif typename == "Clock"
        return fmi3Clock
    elseif typename == "Enumeration"
        return Int64
    else
        @assert false "Unknown datatype `$(typename)`."
    end
end
function stringToDataType(::fmi2ModelDescription, typename::Union{String, SubString})
    if typename == "Real"
        return fmi2Real
    elseif typename == "Integer"
        return fmi2Integer
    elseif typename == "Boolean"
        return fmi2Boolean
    elseif typename == "Enumeration"
        return fmi2Enumeration
    elseif typename == "String"
        return fmi2String 
    else
        @assert false "Unknown datatype `$(typename)`."
    end
end
export stringToDataType

"""
    stringToValueReference(obj, names)

Finds the value reference for a given `name`.

# Arguments
- `obj ∈ (fmi2ModelDescription, fmi3ModelDescription, FMU2, FMU3)` the FMI object
- `names ∈ (String, AbstractVector{String})` the value refernce name or multiple names

# Return
Returns a single or an array of `fmi2ValueReferences` (FMI2) or `fmi3ValueReferences` (FMI3) corresponding to the variable name(s).
"""
function stringToValueReference(md::fmiModelDescription, name::String)
    reference = nothing
    if haskey(md.stringValueReferences, name)
        reference = md.stringValueReferences[name]
    else
        @warn "No variable named '$name' found."
    end
    reference
end
stringToValueReference(md::fmiModelDescription, names::AbstractVector{String}) = broadcast(stringToValueReference, (md,), names)
stringToValueReference(fmu::FMU, name::Union{String, AbstractVector{String}}) = stringToValueReference(fmu.modelDescription, name)
export stringToValueReference

"""
    modelVariablesForValueReference(obj, vr)

where:

obj ∈ (fmi2ModelDescription, fmi3ModelDescription, FMU2, FMU3)
vr ∈ (fmi2ValueReference, fmi3ValueReference)

Returns the model variable(s) matching the value reference.
"""
function modelVariablesForValueReference(md::fmiModelDescription, vr::fmiValueReference)
    ar = []
    for modelVariable in md.modelVariables
        if modelVariable.valueReference == vr
            push!(ar, modelVariable)
        end
    end
    return ar
end
modelVariablesForValueReference(fmu::FMU, vr::fmiValueReference) = modelVariablesForValueReference(fmu.modelDescription, vr)
export modelVariablesForValueReference

# [ToDo]: check if this is needed in FMI3, too.
"""
    dataTypeForValueReference(obj, vr::fmi2ValueReference)

where:

obj ∈ (fmi2ModelDescription, FMU2)

Returns the fmi2DataType (`fmi2Real`, `fmi2Integer`, `fmi2Boolean`, `fmi2String`) for a given value reference `vr`.
"""
function dataTypeForValueReference(md::fmi2ModelDescription, vr::fmi2ValueReference)
    mv = modelVariablesForValueReference(md, vr)[1]
    if !isnothing(mv.Real)
        return fmi2Real
    elseif !isnothing(mv.Integer) || !isnothing(mv.Enumeration)
        return fmi2Integer
    elseif !isnothing(mv.Boolean)
        return fmi2Boolean
    elseif !isnothing(mv.String)
        return fmi2String
    else
        @assert false "fmi2TypeForValueReference(...): Unknown data type for value reference `$(vr)`."
    end
    return nothing
end
function dataTypeForValueReference(md::fmi3ModelDescription, vr::fmi3ValueReference)
    mv = modelVariablesForValueReference(md, vr)[1]
    if isa(mv, FMICore.fmi3VariableFloat32) 
        return fmi3Float32
    elseif isa(mv, FMICore.fmi3VariableFloat64) 
        return fmi3Float64
    elseif isa(mv, FMICore.fmi3VariableInt8) 
        return fmi3Int8
    elseif isa(mv, FMICore.fmi3VariableInt16) 
        return fmi3Int16
    elseif isa(mv, FMICore.fmi3VariableInt32) 
        return fmi3Int32
    elseif isa(mv, FMICore.fmi3VariableInt64)  
        return fmi3Int64
    elseif isa(mv, FMICore.fmi3VariableUInt8) 
        return fmi3UInt8
    elseif isa(mv, FMICore.fmi3VariableUInt16)
        return fmi3UInt16
    elseif isa(mv, FMICore.fmi3VariableUInt32)
        return fmi3UInt32
    elseif isa(mv, FMICore.fmi3VariableUInt64)
        return fmi3UInt64
    elseif isa(mv, FMICore.fmi3VariableBoolean) 
        return fmi3Boolean
    elseif isa(mv, FMICore.fmi3VariableString)
        return fmi3String
    elseif isa(mv, FMICore.fmi3VariableBinary)
        return fmi3Binary
    elseif isa(mv, FMICore.fmi3VariableEnumeration)
        @warn "dataTypeForValueReference(...): Currently not implemented for fmi3Enum."
    else 
        @assert false "dataTypeForValueReference(...): Unknown data type for value reference `$(vr)`."
    end
    return nothing
end
dataTypeForValueReference(fmu::FMU, vr::fmiValueReference) = dataTypeForValueReference(fmu.modelDescription, vr)
export dataTypeForValueReference

"""
    valueReferenceToString(obj, reference)

where: 

obj ∈ (fmi2ModelDescription, fmi3ModelDescription, FMU2, FMU3)
reference ∈ (fmi2ValueReference, fmi3ValueReference, Integer

Returns the string identifier for a give value reference.
"""
function valueReferenceToString(md::fmiModelDescription, reference::fmiValueReference)
    [k for (k,v) in md.stringValueReferences if v == reference]
end
valueReferenceToString(md::fmiModelDescription, reference::Integer) = valueReferenceToString(md, fmiValueReference(reference))
valueReferenceToString(fmu::FMU, reference::Union{fmiValueReference, Integer}) = valueReferenceToString(fmu.modelDescription, reference)
export valueReferenceToString

"""

    statusToString(::struct, status::Union{fmi2Status, Integer})

Converts `fmi2Status` `status` into a String ("OK", "Warning", "Discard", "Error", "Fatal", "Pending").
"""
function statusToString(::FMI2Struct, status::Union{fmi2Status, Integer})
    if status == fmi2StatusOK
        return "OK"
    elseif status == fmi2StatusWarning
        return "Warning"
    elseif status == fmi2StatusDiscard
        return "Discard"
    elseif status == fmi2StatusError
        return "Error"
    elseif status == fmi2StatusFatal
        return "Fatal"
    elseif status == fmi2StatusPending
        return "Pending"
    else
        @assert false "fmi2StatusToString($(status)): Unknown FMU status `$(status)`."
    end
end
function statusToString(::FMI3Struct, status::Union{fmi3Status, Integer})
    if status == fmi3StatusOK
        return "OK"
    elseif status == fmi3StatusWarning
        return "Warning"
    elseif status == fmi3StatusDiscard
        return "Discard"
    elseif status == fmi3StatusError
        return "Error"
    elseif status == fmi3StatusFatal
        return "Fatal"
    else
        return "Unknown"
    end
end
function statusToString(status::Integer)
    if status == fmi3StatusOK
        return "OK"
    elseif status == fmi3StatusWarning
        return "Warning"
    elseif status == fmi3StatusDiscard
        return "Discard"
    elseif status == fmi3StatusError
        return "Error"
    elseif status == fmi3StatusFatal
        return "Fatal"
    else
        return "Unknown"
    end
end
export statusToString

"""
    
    stringToStatus(s)

Converts a String `s` to fmi2Status.
"""
function stringToStatus(::FMI2Struct, s::AbstractString)
    if s == "OK"
        return fmi2StatusOK
    elseif s == "Warning"
        return fmi2StatusWarning
    elseif s == "Discard"
        return fmi2StatusDiscard
    elseif s == "Error"
        return fmi2StatusError
    elseif s == "Fatal"
        return fmi2StatusFatal
    elseif s == "Pending" 
        return fmi2StatusPending
    else
        @assert false "fmi2StatusToString($(s)): Unknown FMU status `$(s)`."
    end
end
function stringToStatus(::FMI3Struct, s::AbstractString)
    if s == "OK" 
        return fmi3StatusOK
    elseif s == "Warning"
        return fmi3StatusWarning
    elseif s == "Discard" 
        return fmi3StatusDiscard
    elseif s == "Error" 
        return fmi3StatusError
    elseif s == "Fatal"
        return fmi3StatusFatal
    else
        return "Unknown"
    end
end
export stringToStatus

"""

    causalityToString(c::fmi2Causality)

Converts [`fmi2Causality`](@ref) `c` to the corresponding String ("parameter", "calculatedParameter", "input", "output", "local", "independent").
"""
function causalityToString(::FMI2Struct, c::fmi2Causality)
    if c == fmi2CausalityParameter
        return "parameter"
    elseif c == fmi2CausalityCalculatedParameter
        return "calculatedParameter"
    elseif c == fmi2CausalityInput
        return "input"
    elseif c == fmi2CausalityOutput
        return "output"
    elseif c == fmi2CausalityLocal
        return "local"
    elseif c == fmi2CausalityIndependent
        return "independent"
    else 
        @assert false "fmi2CausalityToString($(c)): Unknown causality."
    end
end
function causalityToString(::FMI3Struct, c::fmi3Causality)
    if c == fmi3CausalityParameter
        return "parameter"
    elseif c == fmi3CausalityCalculatedParameter
        return "calculatedParameter"
    elseif c == fmi3CausalityInput
        return "input"
    elseif c == fmi3CausalityOutput
        return "output"
    elseif c == fmi3CausalityLocal
        return "local"
    elseif c == fmi3CausalityIndependent
        return "independent"
    elseif c == fmi3CausalityStructuralParameter
        return "structuralParameter"
    else 
        @assert false "fmi3CausalityToString(...): Unknown causality."
    end
end
export causalityToString

"""

    stringToCausality(s::AbstractString)

Converts `s` ("parameter", "calculatedParameter", "input", "output", "local", "independent") to the corresponding [`fmi2Causality`](@ref).
"""
function stringToCausality(::FMI2Struct, s::AbstractString)
    if s == "parameter"
        return fmi2CausalityParameter
    elseif s == "calculatedParameter"
        return fmi2CausalityCalculatedParameter
    elseif s == "input"
        return fmi2CausalityInput
    elseif s == "output"
        return fmi2CausalityOutput
    elseif s == "local"
        return fmi2CausalityLocal
    elseif s == "independent"
        return fmi2CausalityIndependent
    else 
        @assert false "fmi2StringToCausality($(s)): Unknown causality."
    end
end
function stringToCausality(::FMI3Struct, s::AbstractString)
    if s == "parameter"
        return fmi3CausalityParameter
    elseif s == "calculatedParameter"
        return fmi3CausalityCalculatedParameter
    elseif s == "input"
        return fmi3CausalityInput
    elseif s == "output"
        return fmi3CausalityOutput
    elseif s == "local"
        return fmi3CausalityLocal
    elseif s == "independent"
        return fmi3CausalityIndependent
    elseif s == "structuralParameter"
        return fmi3CausalityStructuralParameter
    else 
        @assert false "fmi3StringToCausality($(s)): Unknown causality."
    end
end
export stringToCausality

"""

    variabilityToString(c::fmi2Variability)

Converts [`fmi2Variability`](@ref) `c` to the corresponding String ("constant", "fixed", "tunable", "discrete", "continuous").
"""
function variabilityToString(::FMI2Struct, c::fmi2Variability)
    if c == fmi2VariabilityConstant
        return "constant"
    elseif c == fmi2VariabilityFixed
        return "fixed"
    elseif c == fmi2VariabilityTunable
        return "tunable"
    elseif c == fmi2VariabilityDiscrete
        return "discrete"
    elseif c == fmi2VariabilityContinuous
        return "continuous"
    else 
        @assert false "fmi2VariabilityToString($(c)): Unknown variability."
    end
end
function variabilityToString(::FMI3Struct, c::fmi3Variability)
    if c == fmi3VariabilityConstant
        return "constant"
    elseif c == fmi3VariabilityFixed
        return "fixed"
    elseif c == fmi3VariabilityTunable
        return "tunable"
    elseif c == fmi3VariabilityDiscrete
        return "discrete"
    elseif c == fmi3VariabilityContinuous
        return "continuous"
    else 
        @assert false "fmi3VariabilityToString(...): Unknown variability."
    end
end
export variabilityToString

"""

    stringToVariability(s::AbstractString)

Converts `s` ("constant", "fixed", "tunable", "discrete", "continuous") to the corresponding [`fmi2Variability`](@ref).
"""
function stringToVariability(::FMI2Struct, s::AbstractString)
    if s == "constant"
        return fmi2VariabilityConstant
    elseif s == "fixed"
        return fmi2VariabilityFixed
    elseif s == "tunable"
        return fmi2VariabilityTunable
    elseif s == "discrete"
        return fmi2VariabilityDiscrete
    elseif s == "continuous"
        return fmi2VariabilityContinuous
    else 
        @assert false "fmi2StringToVariability($(s)): Unknown variability."
    end
end
function stringToVariability(::FMI3Struct, s::AbstractString)
    if s == "constant"
        return fmi3VariabilityConstant
    elseif s == "fixed"
        return fmi3VariabilityFixed
    elseif s == "tunable"
        return fmi3VariabilityTunable
    elseif s == "discrete"
        return fmi3VariabilityDiscrete
    elseif s == "continuous"
        return fmi3VariabilityContinuous
    else 
        @assert false "fmi3StringToVariability($(s)): Unknown variability."
    end
end
export stringToVariability

"""

    fmi2InitialToString(c::fmi2Initial)

Converts [`fmi2Initial`](@ref) `c` to the corresponding String ("approx", "exact", "calculated").
"""
function initialToString(::FMI2Struct, c::fmi2Initial)
    if c == fmi2InitialApprox
        return "approx"
    elseif c == fmi2InitialExact
        return "exact"
    elseif c == fmi2InitialCalculated
        return "calculated"
    else 
        @assert false "fmi2InitialToString($(c)): Unknown initial."
    end
end
function initialToString(::FMI3Struct, c::fmi3Initial)
    if c == fmi3InitialApprox
        return "approx"
    elseif c == fmi3InitialExact
        return "exact"
    elseif c == fmi3InitialCalculated
        return "calculated"
    else 
        @assert false "fmi3InitialToString(...): Unknown initial."
    end
end
export initialToString

"""

    stringToInitial(s::AbstractString)

Converts `s` ("approx", "exact", "calculated") to the corresponding [`fmi2Initial`](@ref).
"""
function stringToInitial(::FMI2Struct, s::AbstractString)
    if s == "approx"
        return fmi2InitialApprox
    elseif s == "exact"
        return fmi2InitialExact
    elseif s == "calculated"
        return fmi2InitialCalculated
    else 
        @assert false "fmi2StringToInitial($(s)): Unknown initial."
    end
end
function stringToInitial(::FMI3Struct, s::AbstractString)
    if s == "approx"
        return fmi3InitialApprox
    elseif s == "exact"
        return fmi3InitialExact
    elseif s == "calculated"
        return fmi3InitialCalculated
    else 
        @assert false "fmi3StringToInitial($(s)): Unknown initial."
    end
end
export stringToInitial

"""

    dependencyKindToString(c::fmi2DependencyKind)

Converts [`fmi2DependencyKind`](@ref) `c` to the corresponding String ("dependent", "constant", "fixed", "tunable", "discrete")
"""
function dependencyKindToString(::FMI2Struct, dk::fmi2DependencyKind)
    if dk == fmi2DependencyKindDependent
        return "dependent"
    elseif dk == fmi2DependencyKindConstant
        return "constant"
    elseif dk == fmi2DependencyKindFixed
        return "fixed"
    elseif dk == fmi2DependencyKindTunable
        return "tunable"
    elseif dk == fmi2DependencyKindDiscrete
        return "discrete"
    else 
        @assert false "fmi2DependencyKindToString($(c)): Unknown dependency kind."
    end
end
function dependencyKindToString(::FMI3Struct, c::fmi3DependencyKind)
    if c == fmi3DependencyKindIndependent
        return "independent"
    elseif c == fmi3DependencyKindConstant
        return "constant"
    elseif c == fmi3DependencyKindFixed
        return "fixed"
    elseif c == fmi3DependencyKindTunable
        return "tunable"
    elseif c == fmi3DependencyKindDiscrete
        return "discrete"
    elseif c == fmi3DependencyKindDependent
        return "dependent"
    else 
        @assert false "fmi3DependencyKindToString(...): Unknown dependencyKind."
    end
end
export dependencyKindToString

"""

    stringToDependencyKind(s::AbstractString)

Converts `s` ("dependent", "constant", "fixed", "tunable", "discrete") to the corresponding [`fmi2DependencyKind`](@ref)
"""
function stringToDependencyKind(::FMI2Struct, s::AbstractString)
    if s == "dependent"
        return fmi2DependencyKindDependent
    elseif s == "constant"
        return fmi2DependencyKindConstant
    elseif s == "fixed"
        return fmi2DependencyKindFixed
    elseif s == "tunable"
        return fmi2DependencyKindTunable
    elseif s == "discrete"
        return fmi2DependencyKindDiscrete
    else 
        @assert false "fmi2StringToDependencyKind($(s)): Unknown dependency kind."
    end
end
function stringToDependencyKind(::FMI3Struct, s::AbstractString)
    if s == "independent"
        return fmi3DependencyKindIndependent
    elseif s == "constant"
        return fmi3DependencyKindConstant
    elseif s == "fixed"
        return fmi3DependencyKindFixed
    elseif s == "tunable"
        return fmi3DependencyKindTunable
    elseif s == "discrete"
        return fmi3DependencyKindDiscrete
    elseif s == "dependent"
        return fmi3DependencyKindDependent
    else 
        @assert false "fmi3StringToDependencyKind($(s)): Unknown dependencyKind."
    end
end
export stringToDependencyKind

"""
    variableNamingConventionToString(c::fmi3VariableNamingConvention)

Convert [`fmi3VariableNamingConvention`](@ref) `c` to the corresponding String ("flat", "structured").
"""
function variableNamingConventionToString(::FMI3Struct, c::fmi3VariableNamingConvention)
    if c == fmi3VariableNamingConventionFlat
        return "flat"
    elseif c == fmi3VariableNamingConventionStructured
        return "structured"
    else 
        @assert false "fmi3VariableNamingConventionToString(...): Unknown variableNamingConvention."
    end
end
export variableNamingConventionToString

"""
    stringToVariableNamingConvention(s::AbstractString)

Convert `s` ("flat", "structured") to the corresponding [`fmi3VariableNamingConvention`](@ref).
"""
function stringToVariableNamingConvention(::FMI3Struct, s::AbstractString)
    if s == "flat"
        return fmi3VariableNamingConventionFlat
    elseif s == "structured"
        return fmi3VariableNamingConventionStructured
    else 
        @assert false "stringToVariableNamingConvention($(s)): Unknown variableNamingConvention."
    end
end
export stringToVariableNamingConvention

"""
    typeToString(c::fmi3Type)

Convert [`fmi3Type`](@ref) `c` to the corresponding String ("coSimulation", "modelExchange", "scheduledExecution").
"""
function typeToString(::FMI3Struct, c::fmi3Type)
    if c == fmi3TypeCoSimulation
        return "coSimulation"
    elseif c == fmi3TypeModelExchange
        return "modelExchange"
    elseif c == fmi3TypeScheduledExecution
        return "scheduledExecution"
    else 
        @assert false "fmi3TypeToString(...): Unknown type."
    end
end
export typeToString

"""
    stringToType(s::AbstractString)

Convert `s` ("coSimulation", "modelExchange", "scheduledExecution") to the corresponding [`fmi3Type`](@ref).
"""
function stringToType(::FMI3Struct, s::AbstractString)
    if s == "coSimulation"
        return fmi3TypeCoSimulation
    elseif s == "modelExchange"
        return fmi3TypeModelExchange
    elseif s == "scheduledExecution"
        return fmi3TypeScheduledExecution
    else 
        @assert false "fmi3StringToInitial($(s)): Unknown type."
    end
end
export stringToType

"""
    intervalQualifierToString(c::fmi3IntervalQualifier)

Convert [`fmi3IntervalQualifier`](@ref) `c` to the corresponding String ("intervalNotYetKnown", "intervalUnchanged", "intervalChanged").
"""
function intervalQualifierToString(::FMI3Struct, c::fmi3IntervalQualifier)
    if c == fmi3IntervalQualifierIntervalNotYetKnown
        return "intervalNotYetKnown"
    elseif c == fmi3IntervalQualifierIntervalUnchanged
        return "intervalUnchanged"
    elseif c == fmi3IntervalQualifierIntervalChanged
        return "intervalChanged"
    else 
        @assert false "fmi3IntervalQualifierToString(...): Unknown intervalQualifier."
    end
end
export intervalQualifierToString

"""
    stringToIntervalQualifier(::FMI3Struct, s::AbstractString)

Convert `s` ("intervalNotYetKnown", "intervalUnchanged", "intervalChanged") to the corresponding [`fmi3IntervalQualifier`](@ref).
"""
function stringToIntervalQualifier(::FMI3Struct, s::AbstractString)
    if s == "intervalNotYetKnown"
        return fmi3IntervalQualifierIntervalNotYetKnown
    elseif s == "intervalUnchanged"
        return fmi3IntervalQualifierIntervalUnchanged
    elseif s == "intervalChanged"
        return fmi3IntervalQualifierIntervalChanged
    else 
        @assert false "fmi3StringToIntervalQualifier($(s)): Unknown intervalQualifier."
    end
end
export stringToIntervalQualifier