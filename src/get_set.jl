#
# Copyright (c) 2021 Tobias Thummerer, Lars Mikelsons, Josef Kircher
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

"""
    getValue!(comp::FMU2Component, vrs::fmi2ValueReferenceFormat, dst::AbstractArray)

Retrieves values for the refernces `vrs` and stores them in `dst`

# Arguments
- `comp::FMU2Component`: Mutable struct represents an instantiated instance of an FMU in the FMI 2.0.2 Standard.
- `vrs::fmi2ValueReferenceFormat`: wildcards for how a user can pass a fmi[X]ValueReference
- `dst::AbstractArray`: The array of destinations, must match the data types of the value references.

# Returns
- `retcodes::Array{fmi2Status}`: Returns an array of length length(vrs) with Type `fmi2Status`. Type `fmi2Status` is an enumeration and indicates the success of the function call.
"""
function getValue!(comp::FMU2Component, vrs::fmi2ValueReferenceFormat, dstArray::AbstractArray) # [ToDo] implement via array views!
    vrs = prepareValueReference(comp, vrs)

    @assert length(vrs) == length(dstArray) "fmi2Get!(...): Number of value references doesn't match number of `dstArray` elements."

    retcodes = collect(fmi2StatusOK for i in 1:length(vrs)) 

    for i in 1:length(vrs)
        vr = vrs[i]
        mv = modelVariablesForValueReference(comp.fmu.modelDescription, vr)
        mv = mv[1]

        num = Csize_t(1)

        if !isnothing(mv.Real)
            #@assert isa(dstArray[i], Real) "fmi2Get!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Real`, is `$(typeof(dstArray[i]))`."
            values = zeros(fmi2Real, num)
            fmi2GetReal!(comp, [vr], num, values)
            dstArray[i] = values[1]
        elseif mv.Integer != nothing
            #@assert isa(dstArray[i], Union{Real, Integer}) "fmi2Get!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Integer`, is `$(typeof(dstArray[i]))`."
            values = zeros(fmi2Integer, num)
            fmi2GetInteger!(comp, [vr], num, values)
            dstArray[i] = values[1]
        elseif mv.Boolean != nothing
            #@assert isa(dstArray[i], Union{Real, Bool}) "fmi2Get!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Bool`, is `$(typeof(dstArray[i]))`."
            values = zeros(fmi2Boolean, num)
            fmi2GetBoolean(comp, [vr], num, values)
            dstArray[i] = values[1]
        elseif mv.String != nothing
            #@assert isa(dstArray[i], String) "fmi2Get!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `String`, is `$(typeof(dstArray[i]))`."
            values = zeros(fmi2String, num)
            fmi2GetString!(comp, [vr], num, values)
            dstArray[i] = values[1]
        elseif mv.Enumeration != nothing
            @warn "getValue!(...): Currently not implemented for fmi2Enum."
        else
            @assert isa(dstArray[i], Real) "fmi2Get!(...): Unknown data type for value reference `$(vr)` at index $(i), is `$(mv.datatype.datatype)`."
        end
    end

    return retcodes
end
function getValue!(inst::FMU3Instance, vrs::fmi3ValueReferenceFormat, dstArray::Array)
    vrs = prepareValueReference(inst, vrs)

    @assert length(vrs) == length(dstArray) "fmi3Get!(...): Number of value references doesn't match number of `dstArray` elements."

    retcodes = collect(fmi3StatusOK for i in 1:length(vrs))  

    for i in 1:length(vrs)
        vr = vrs[i]
        mv = modelVariablesForValueReference(inst.fmu.modelDescription, vr)
        mv = mv[1]

        num = Csize_t(1)

        # TODO change if dataytype is elimnated
        if isa(mv, FMICore.fmi3VariableFloat32) 
            #@assert isa(dstArray[i], Real) "fmi3Get!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Real`, is `$(typeof(dstArray[i]))`."
            values = zeros(fmi3Float32, num)
            fmi3GetFloat32!(inst, [vr], num, values, num)
            dstArray[i] = values[1]
        elseif isa(mv, FMICore.fmi3VariableFloat64) 
            #@assert isa(dstArray[i], Union{Real, Integer}) "fmi3Get!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Integer`, is `$(typeof(dstArray[i]))`."
            values = zeros(fmi3Float64, num)
            fmi3GetFloat64!(inst, [vr], num, values, num)
            dstArray[i] = values[1]
        elseif isa(mv, FMICore.fmi3VariableInt8) 
            #@assert isa(dstArray[i], Union{Real, Integer}) "fmi3Get!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Integer`, is `$(typeof(dstArray[i]))`."
            values = zeros(fmi3Int8, num)
            fmi3GetInt8!(inst, [vr], num, values, num)
            dstArray[i] = values[1]
        elseif isa(mv, FMICore.fmi3VariableInt16) 
            #@assert isa(dstArray[i], Union{Real, Integer}) "fmi3Get!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Integer`, is `$(typeof(dstArray[i]))`."
            values = zeros(fmi3Int16, num)
            fmi3GetInt16!(inst, [vr], num, values, num)
            dstArray[i] = values[1]
        elseif isa(mv, FMICore.fmi3VariableInt32) 
            #@assert isa(dstArray[i], Union{Real, Integer}) "fmi3Get!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Integer`, is `$(typeof(dstArray[i]))`."
            values = zeros(fmi3Int32, num)
            fmi3GetInt32!(inst, [vr], num, values, num)
            dstArray[i] = values[1]
        elseif isa(mv, FMICore.fmi3VariableInt64)  
            #@assert isa(dstArray[i], Union{Real, Integer}) "fmi3Get!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Integer`, is `$(typeof(dstArray[i]))`."
            values = zeros(fmi3Int64, num)
            fmi3GetInt64!(inst, [vr], num, values, num)
            dstArray[i] = values[1]
        elseif isa(mv, FMICore.fmi3VariableUInt8) 
            #@assert isa(dstArray[i], Union{Real, Integer}) "fmi3Get!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Integer`, is `$(typeof(dstArray[i]))`."
            values = zeros(fmi3UInt8, num)
            fmi3GetUInt8!(inst, [vr], num, values, num)
            dstArray[i] = values[1]
        elseif isa(mv, FMICore.fmi3VariableUInt16)
            #@assert isa(dstArray[i], Union{Real, Integer}) "fmi3Get!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Integer`, is `$(typeof(dstArray[i]))`."
            values = zeros(fmi3UInt16, num)
            fmi3GetUInt16!(inst, [vr], num, values, num)
            dstArray[i] = values[1]
        elseif isa(mv, FMICore.fmi3VariableUInt32)
            #@assert isa(dstArray[i], Union{Real, Integer}) "fmi3Get!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Integer`, is `$(typeof(dstArray[i]))`."
            values = zeros(fmi3UInt32, num)
            fmi3GetUInt32!(inst, [vr], num, values, num)
            dstArray[i] = values[1]
        elseif isa(mv, FMICore.fmi3VariableUInt64)
            #@assert isa(dstArray[i], Union{Real, Integer}) "fmi3Get!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Integer`, is `$(typeof(dstArray[i]))`."
            values = zeros(fmi3UInt64, num)
            fmi3GetUInt64!(inst, [vr], num, values, num)
            dstArray[i] = values[1]
        elseif isa(mv, FMICore.fmi3VariableBoolean) 
            #@assert isa(dstArray[i], Union{Real, Bool}) "fmi3Get!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Bool`, is `$(typeof(dstArray[i]))`."
            values = zeros(fmi3Boolean, num)
            fmi3GetBoolean!(inst, [vr], num, values, num)
            dstArray[i] = values[1]
        elseif isa(mv, FMICore.fmi3VariableString)
            #@assert isa(dstArray[i], String) "fmi3Get!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `String`, is `$(typeof(dstArray[i]))`."
            values = zeros(fmi3String, num)
            fmi3GetString!(inst, [vr], num, values, num)
            dstArray[i] = values[1]
        elseif isa(mv, FMICore.fmi3VariableBinary)
            #@assert isa(dstArray[i], String) "fmi3Get!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `String`, is `$(typeof(dstArray[i]))`."
            values = zeros(fmi3Binary, num)
            fmi3GetBinary!(inst, [vr], num, values, num)
            dstArray[i] = values[1]
        elseif isa(mv, FMICore.fmi3VariableEnumeration)
            @warn "fmi3Get!(...): Currently not implemented for fmi3Enum."
        else 
            @assert isa(dstArray[i], Real) "fmi3Get!(...): Unknown data type for value reference `$(vr)` at index $(i), is `$(mv.datatype.datatype)`."
        end
    end

    return retcodes
end
export getValue!

"""
    getValue(comp::FMU2Component, vrs::fmi2ValueReferenceFormat)

Returns the specific value of `fmi2ScalarVariable` containing the modelVariables with the identical fmi2ValueReference in an array.

# Arguments
- `comp::FMU2Component`: Mutable struct represents an instantiated instance of an FMU in the FMI 2.0.2 Standard.
- `vrs::fmi2ValueReferenceFormat`: wildcards for how a user can pass a fmi[X]ValueReference
More detailed: `fmi2ValueReferenceFormat = Union{Nothing, String, Array{String,1}, fmi2ValueReference, Array{fmi2ValueReference,1}, Int64, Array{Int64,1}, Symbol}`

# Returns
- `dstArray::Array{Any,1}(undef, length(vrs))`: Stores the specific value of `fmi2ScalarVariable` containing the modelVariables with the identical fmi2ValueReference to the input variable vr (vr = vrs[i]). `dstArray` is a 1-Dimensional Array that has the same length as `vrs`.
"""
function getValue(comp::FMUInstance, vrs::fmiValueReferenceFormat)
    vrs = prepareValueReference(comp, vrs)
    dstArray = Array{Any,1}(undef, length(vrs))
    getValue!(comp, vrs, dstArray)

    if length(dstArray) == 1
        return dstArray[1]
    else
        return dstArray
    end
end
export getValue

"""
    setValue(comp::FMU2Component,
                vrs::fmi2ValueReferenceFormat,
                srcArray::AbstractArray;
                filter=nothing)

Stores the specific value of `fmi2ScalarVariable` containing the modelVariables with the identical fmi2ValueReference and returns an array that indicates the Status.

# Arguments
- `comp::FMU2Component`: Mutable struct represents an instantiated instance of an FMU in the FMI 2.0.2 Standard.
- `vrs::fmi2ValueReferenceFormat`: wildcards for how a user can pass a fmi[X]ValueReference
- `srcArray::AbstractArray`: Stores the specific value of `fmi2ScalarVariable` containing the modelVariables with the identical fmi2ValueReference to the input variable vr (vr = vrs[i]). `srcArray` has the same length as `vrs`.

# Keywords
- `filter=nothing`: It is applied to each ModelVariable to determine if it should be updated.

# Returns
- `retcodes::Array{fmi2Status}`: Returns an array of length length(vrs) with Type `fmi2Status`. Type `fmi2Status` is an enumeration and indicates the success of the function call.
"""
function setValue(comp::FMU2Component, vrs::fmi2ValueReferenceFormat, srcArray::AbstractArray; filter=nothing)
    vrs = prepareValueReference(comp, vrs)

    @assert length(vrs) == length(srcArray) "setValue(...): Number of value references [$(length(vrs))] doesn't match number of `srcArray` elements [$(length(srcArray))]."

    retcodes = collect(fmi2StatusOK for i in 1:length(vrs))

    for i in 1:length(vrs)
        vr = vrs[i]
        mv = modelVariablesForValueReference(comp.fmu.modelDescription, vr)
        mv = mv[1]

        if isnothing(filter) || filter(mv)

            if !isnothing(mv.Real)

                @assert isa(srcArray[i], Real) "setValue(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Real`, is `$(typeof(srcArray[i]))`."
                retcodes[i] = fmi2SetReal(comp, vr, srcArray[i])
            elseif !isnothing(mv.Integer)

                @assert isa(srcArray[i], Union{Real, Integer}) "setValue(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Integer`, is `$(typeof(srcArray[i]))`."
                retcodes[i] = fmi2SetInteger(comp, vr, Integer(srcArray[i]))
            elseif !isnothing(mv.Boolean)

                @assert isa(srcArray[i], Union{Real, Bool}) "setValue(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Bool`, is `$(typeof(srcArray[i]))`."
                retcodes[i] = fmi2SetBoolean(comp, vr, Bool(srcArray[i]))
            elseif !isnothing(mv.String)

                @assert isa(srcArray[i], String) "setValue(...): Unknown data type for value reference `$(vr)` at index $(i), should be `String`, is `$(typeof(srcArray[i]))`."
                retcodes[i] = fmi2SetString(comp, vr, srcArray[i])
            elseif !isnothing(mv.Enumeration)

                @assert isa(srcArray[i], Union{Real, Integer}) "setValue(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Enumeration` (`Integer`), is `$(typeof(srcArray[i]))`."
                retcodes[i] = fmi2SetInteger(comp, vr, Integer(srcArray[i]))
            else
                @assert false "setValue(...): Unknown data type for value reference `$(vr)` at index $(i), is `$(mv.datatype.datatype)`."
            end

        end
    end

    return retcodes
end
function setValue(inst::FMU3Instance, vrs::fmi3ValueReferenceFormat, srcArray::Array; filter=nothing)

    vrs = prepareValueReference(inst, vrs)

    @assert length(vrs) == length(srcArray) "setValue(...): Number of value references doesn't match number of `srcArray` elements."

    retcodes = collect(fmi3StatusOK for i in 1:length(vrs))

    for i in 1:length(vrs)
       
        vr = vrs[i]
        mv = modelVariablesForValueReference(inst.fmu.modelDescription, vr)
        mv = mv[1]

        if isnothing(filter) || filter(mv)

            if isa(mv, FMICore.fmi3VariableFloat32) 
                #@assert isa(dstArray[i], Real) "fmi3Set!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Real`, is `$(typeof(dstArray[i]))`."
                fmi3SetFloat32(inst, vr, srcArray[i])
            elseif isa(mv, FMICore.fmi3VariableFloat64)
                #@assert isa(dstArray[i], Union{Real, Integer}) "fmi3Set!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Integer`, is `$(typeof(dstArray[i]))`."
                fmi3SetFloat64(inst, vr, srcArray[i])
            elseif isa(mv, FMICore.fmi3VariableInt8) 
                #@assert isa(dstArray[i], Union{Real, Integer}) "fmi3Set!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Integer`, is `$(typeof(dstArray[i]))`."
                fmi3SetInt8(inst, vr, Integer(srcArray[i]))
            elseif isa(mv, FMICore.fmi3VariableInt16) 
                #@assert isa(dstArray[i], Union{Real, Integer}) "fmi3Set!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Integer`, is `$(typeof(dstArray[i]))`."
                fmi3SetInt16(inst, vr, Integer(srcArray[i]))
            elseif isa(mv, FMICore.fmi3VariableInt32) 
                #@assert isa(dstArray[i], Union{Real, Integer}) "fmi3Set!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Integer`, is `$(typeof(dstArray[i]))`."
                fmi3SetInt32(inst, vr, Int32(srcArray[i]))
            elseif isa(mv, FMICore.fmi3VariableInt64) 
                #@assert isa(dstArray[i], Union{Real, Integer}) "fmi3Set!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Integer`, is `$(typeof(dstArray[i]))`."
                fmi3SetInt64(inst, vr, Integer(srcArray[i]))
            elseif isa(mv, FMICore.fmi3VariableUInt8) 
                #@assert isa(dstArray[i], Union{Real, Integer}) "fmi3Set!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Integer`, is `$(typeof(dstArray[i]))`."
                fmi3SetUInt8(inst, vr, Integer(srcArray[i]))
            elseif isa(mv, FMICore.fmi3VariableUInt16) 
                #@assert isa(dstArray[i], Union{Real, Integer}) "fmi3Set!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Integer`, is `$(typeof(dstArray[i]))`."
                fmi3SetUInt16(inst, vr, Integer(srcArray[i]))
            elseif isa(mv, FMICore.fmi3VariableUInt32) 
                #@assert isa(dstArray[i], Union{Real, Integer}) "fmi3Set!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Integer`, is `$(typeof(dstArray[i]))`."
                fmi3SetUInt32(inst, vr, Integer(srcArray[i]))
            elseif isa(mv, FMICore.fmi3VariableUInt64) 
                #@assert isa(dstArray[i], Union{Real, Integer}) "fmi3Set!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Integer`, is `$(typeof(dstArray[i]))`."
                fmi3SetUInt64(inst, vr, Integer(srcArray[i]))
            elseif isa(mv, FMICore.fmi3VariableBoolean) 
                #@assert isa(dstArray[i], Union{Real, Bool}) "fmi3Set!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `Bool`, is `$(typeof(dstArray[i]))`."
                fmi3SetBoolean(inst, vr, Bool(srcArray[i]))
            elseif isa(mv, FMICore.fmi3VariableString) 
                #@assert isa(dstArray[i], String) "fmi3Set!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `String`, is `$(typeof(dstArray[i]))`."
                fmi3SetString(inst, vr, srcArray[i])
            elseif isa(mv, FMICore.fmi3VariableBinary) 
                #@assert isa(dstArray[i], String) "fmi3Set!(...): Unknown data type for value reference `$(vr)` at index $(i), should be `String`, is `$(typeof(dstArray[i]))`."
                fmi3SetBinary(inst, vr, Csize_t(length(srcArray[i])), pointer(srcArray[i])) # TODO fix this
            elseif isa(mv, FMICore.fmi3VariableEnumeration)
                @warn "fmi3Set!(...): Currently not implemented for fmi3Enum."
            else 
                @assert false "setValue(...): Unknown data type for value reference `$(vr)` at index $(i), is `$(typeof(mv))`."
            end

        end
    end

    return retcodes
end
export setValue

"""
    setDiscreteStates(c::FMU2Component,
                                 x::Union{AbstractArray{Float32},AbstractArray{Float64}})

Set a new (discrete) state vector and reinitialize chaching of variables that depend on states.

# Arguments
[ToDo]
"""
function setDiscreteStates(c::FMU2Component, xd::AbstractArray{Union{fmi2Real, fmi2Integer, fmi2Boolean}})

    if length(c.fmu.modelDescription.discreteStateValueReferences) <= 0
        return fmi2StatusOK
    end

    status = fmi2Set(c, c.fmu.modelDescription.discreteStateValueReferences, xd)
    if status == fmi2StatusOK
        fast_copy!(c, :x_d, xd)
    end
    return status
end
export setDiscreteStates

"""
    getDiscreteStates!(c, xd)

Sets a new (discrete) state vector (in-place).

# Arguments
- `c::FMU2Component`
- `xd::AbstractArray{Union{fmi2Real, fmi2Integer, fmi2Boolean}}`
"""
function getDiscreteStates!(c::FMU2Component, xd::AbstractArray{Union{fmi2Real, fmi2Integer, fmi2Boolean}})

    if length(c.fmu.modelDescription.discreteStateValueReferences) <= 0
        return fmi2StatusOK
    end

    status = getValue!(c, c.fmu.modelDescription.discreteStateValueReferences, xd)
    if status == fmi2StatusOK
        fast_copy!(c, :x_d, xd)
    end
    return status
end
export getDiscreteStates!

"""
    getDiscreteStates(c)

Sets a new (discrete) state vector (out-of-place).

# Arguments
- `c::FMU2Component`
"""
function getDiscreteStates(c::FMU2Component)

    ndx = length(c.fmu.modelDescription.discreteStateValueReferences)
    xd = Vector{Union{fmi2Real, fmi2Integer, fmi2Boolean}}()
    getDiscreteStates!(c, xd)
    return xd
end
export getDiscreteStates