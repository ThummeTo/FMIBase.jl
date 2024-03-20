#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

"""
    prepareValueReference(obj, vrs)

where: 

obj ∈ (fmi2ModelDescription, fmi3ModelDescription, FMU2, FMU3, FMU2Component, FMU3Instance)
vrs ∈ (fmi2ValueReference, AbstractVector{fmi2ValueReference}, 
       fmi3ValueReference, AbstractVector{fmi3ValueReference}, 
       String, AbstractVector{String}, 
       Integer, AbstractVector{Integer},
       :states, :derivatives, :inputs, :outputs, :all, :none,
       Nothing)

Receives one or an array of value references in an arbitrary format (see fmi2ValueReferenceFormat) and converts it into an Array{fmi2ValueReference} (if not already).
"""
prepareValueReference(md::fmiModelDescription, vr::fmiValueReference) = [vr]
prepareValueReference(md::fmiModelDescription, vr::AbstractVector{fmiValueReference}) = vr
prepareValueReference(md::fmiModelDescription, vr::String) = [stringToValueReference(md, vr)]
prepareValueReference(md::fmiModelDescription, vr::AbstractVector{String}) = stringToValueReference(md, vr)
prepareValueReference(md::fmiModelDescription, vr::Nothing) = fmiValueReference[]
prepareValueReference(md::fmiModelDescription, vr::AbstractVector{<:Integer}) = fmiValueReference.(vr)
prepareValueReference(md::fmiModelDescription, vr::Integer) = [fmiValueReference(vr)]
prepareValueReference(fmu::FMU2, vr::fmi2ValueReferenceFormat) = prepareValueReference(fmu.modelDescription, vr)
prepareValueReference(comp::FMU2Component, vr::fmi2ValueReferenceFormat) = prepareValueReference(comp.fmu.modelDescription, vr)
prepareValueReference(fmu::FMU3, vr::fmi3ValueReferenceFormat) = prepareValueReference(fmu.modelDescription, vr)
prepareValueReference(comp::FMU3Instance, vr::fmi3ValueReferenceFormat) = prepareValueReference(comp.fmu.modelDescription, vr)
function prepareValueReference(md::fmiModelDescription, vr::Symbol)
    if vr == :states
        return md.stateValueReferences
    elseif vr == :derivatives
        return md.derivativeValueReferences
    elseif vr == :inputs
        return md.inputValueReferences
    elseif vr == :outputs
        return md.outputValueReferences
    elseif vr == :all
        return md.valueReferences
    elseif vr == :none
        return Array{fmiValueReference,1}()
    else
        @assert false "Unknwon symbol `$vr`, can't convert to value reference."
    end
end
export prepareValueReference

prepareValue(value) = [value]
prepareValue(value::AbstractVector) = value
export prepareValue