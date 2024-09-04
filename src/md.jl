#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

"""
    getModelIdentifier(md::fmiModelDescription; type=nothing)

Returns the tag 'modelIdentifier' from CS or ME section.

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Keywords
- `type=nothing`: Defines whether a Co-Simulation or Model Exchange is present. (default = nothing)

# Returns
- `md.modelExchange.modelIdentifier::String`: Returns the tag `modelIdentifier` from ModelExchange section.
- `md.coSimulation.modelIdentifier::String`: Returns the tag `modelIdentifier` from CoSimulation section.
"""
function getModelIdentifier(md::fmi2ModelDescription; type = nothing)

    if isnothing(type)
        if isCoSimulation(md)
            return md.coSimulation.modelIdentifier
        elseif isModelExchange(md)
            return md.modelExchange.modelIdentifier
        else
            @assert false "getModelIdentifier(...): FMU does not support ME nor CS!"
        end
    elseif type == fmi2TypeCoSimulation
        return md.coSimulation.modelIdentifier
    elseif type == fmi2TypeModelExchange
        return md.modelExchange.modelIdentifier
    end
end
function getModelIdentifier(md::fmi3ModelDescription; type = nothing)

    if isnothing(type)
        if isCoSimulation(md)
            return md.coSimulation.modelIdentifier
        elseif isModelExchange(md)
            return md.modelExchange.modelIdentifier
        elseif isScheduledExecution(md)
            return md.scheduledExecution.modelIdentifier
        else
            @assert false "getModelIdentifier(...): FMU does not support ME nor CS nor SE!"
        end
    elseif type == fmi3TypeCoSimulation
        return md.coSimulation.modelIdentifier
    elseif type == fmi3TypeModelExchange
        return md.modelExchange.modelIdentifier
    elseif type == fmi3TypeScheduledExecution
        return md.scheduledExecution.modelIdentifier
    end
end
getModelIdentifier(fmu::FMU) = getModelIdentifier(fmu.modelDescription)
export getModelIdentifier

"""
    getModelName(md::fmi2ModelDescription)

Returns the tag 'modelName' from the model description.

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Returns
- `modelName::String`: Returns the tag 'modelName' from the model description.

"""
function getModelName(md::fmiModelDescription)
    md.modelName
end
getModelName(fmu::FMU) = getModelName(fmu.modelDescription)
export getModelName

"""
    getDefaultStartTime(md::fmi2ModelDescription)

Returns startTime from DefaultExperiment if defined else defaults to nothing.

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Returns
- `md.defaultExperiment.startTime::Union{Real,Nothing}`: Returns a real value `startTime` from the DefaultExperiment if defined else defaults to `nothing`.
"""
function getDefaultStartTime(md::fmiModelDescription)
    if isnothing(md.defaultExperiment)
        return nothing
    end
    return md.defaultExperiment.startTime
end
getDefaultStartTime(fmu::FMU) = getDefaultStartTime(fmu.modelDescription)
export getDefaultStartTime

"""
    getDefaultStopTime(md::fmi2ModelDescription)

Returns stopTime from DefaultExperiment if defined else defaults to nothing.

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Returns
- `md.defaultExperiment.stopTime::Union{Real,Nothing}`: Returns a real value `stopTime` from the DefaultExperiment if defined else defaults to `nothing`.

"""
function getDefaultStopTime(md::fmiModelDescription)
    if isnothing(md.defaultExperiment)
        return nothing
    end
    return md.defaultExperiment.stopTime
end
getDefaultStopTime(fmu::FMU) = getDefaultStopTime(fmu.modelDescription)
export getDefaultStopTime

"""
    getDefaultTolerance(md::fmi2ModelDescription)

Returns tolerance from DefaultExperiment if defined else defaults to nothing.

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Returns
- `md.defaultExperiment.tolerance::Union{Real,Nothing}`: Returns a real value `tolerance` from the DefaultExperiment if defined else defaults to `nothing`.

"""
function getDefaultTolerance(md::fmiModelDescription)
    if isnothing(md.defaultExperiment)
        return nothing
    end
    return md.defaultExperiment.tolerance
end
getDefaultTolerance(fmu::FMU) = getDefaultTolerance(fmu.modelDescription)
export getDefaultTolerance

"""
    getDefaultStepSize(md::fmi2ModelDescription)

Returns stepSize from DefaultExperiment if defined else defaults to nothing.

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Returns
- `md.defaultExperiment.stepSize::Union{Real,Nothing}`: Returns a real value `setpSize` from the DefaultExperiment if defined else defaults to `nothing`.

"""
function getDefaultStepSize(md::fmiModelDescription)
    if isnothing(md.defaultExperiment)
        return nothing
    end
    return md.defaultExperiment.stepSize
end
getDefaultStepSize(fmu::FMU) = getDefaultStepSize(fmu.modelDescription)
export getDefaultStepSize

"""
    getGenerationTool(md::fmi2ModelDescription)

Returns the tag 'generationtool' from the model description.

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Returns
- `md.generationTool::Union{String, Nothing}`: Returns the tag 'generationtool' from the model description.

"""
function getGenerationTool(md::fmiModelDescription)
    md.generationTool
end
getGenerationTool(fmu::FMU) = getGenerationTool(fmu.modelDescription)
export getGenerationTool

"""
    getGenerationDateAndTime(md::fmi2ModelDescription)

Returns the tag 'generationdateandtime' from the model description.

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Returns
- `md.generationDateAndTime::DateTime`: Returns the tag 'generationdateandtime' from the model description.

"""
function getGenerationDateAndTime(md::fmiModelDescription)
    md.generationDateAndTime
end
getGenerationDateAndTime(fmu::FMU) = getGenerationDateAndTime(fmu.modelDescription)
export getGenerationDateAndTime

"""
    getVariableNamingConvention(md::fmi2ModelDescription)

Returns the tag 'varaiblenamingconvention' from the model description.

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Returns
- `md.variableNamingConvention::Union{fmi2VariableNamingConvention, Nothing}`: Returns the tag 'variableNamingConvention' from the model description.

"""
function getVariableNamingConvention(md::fmiModelDescription)
    md.variableNamingConvention
end
getVariableNamingConvention(fmu::FMU) = getVariableNamingConvention(fmu.modelDescription)
export getVariableNamingConvention

"""
    getNumberOfEventIndicators(md::fmi2ModelDescription)

Returns the tag 'numberOfEventIndicators' from the model description.

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Returns
- `md.numberOfEventIndicators::Union{UInt, Nothing}`: Returns the tag 'numberOfEventIndicators' from the model description.

"""
function getNumberOfEventIndicators(md::fmiModelDescription)
    md.numberOfEventIndicators
end
getNumberOfEventIndicators(fmu::FMU) = getNumberOfEventIndicators(fmu.modelDescription)
export getNumberOfEventIndicators

"""
    getNumberOfStates(md::fmi2ModelDescription)

Returns the number of states of the FMU.

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Returns
- Returns the number of states of the FMU.

"""
function getNumberOfStates(md::fmiModelDescription)
    length(md.stateValueReferences)
end
getNumberOfStates(fmu::FMU) = getNumberOfStates(fmu.modelDescription)
export getNumberOfStates

"""
    isCoSimulation(md::fmi2ModelDescription)

Returns true, if the FMU supports co simulation

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Returns
- `::Bool`: Returns true, if the FMU supports co simulation

"""
function isCoSimulation(md::fmiModelDescription)
    return !isnothing(md.coSimulation)
end
isCoSimulation(fmu::FMU) = isCoSimulation(fmu.modelDescription)
export isCoSimulation

"""
    isModelExchange(md::fmi2ModelDescription)

Returns true, if the FMU supports model exchange

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Returns
- `::Bool`: Returns true, if the FMU supports model exchange

"""
function isModelExchange(md::fmiModelDescription)
    return !isnothing(md.modelExchange)
end
isModelExchange(fmu::FMU) = isModelExchange(fmu.modelDescription)
export isModelExchange

"""
Returns true, if the FMU supports scheduled execution
"""
function isScheduledExecution(md::fmi2ModelDescription)
    @warn "Scheduled Execution (SE) is only available in FMI3!"
    return false
end
function isScheduledExecution(md::fmi3ModelDescription)
    return !isnothing(md.scheduledExecution)
end
isScheduledExecution(fmu::FMU) = isScheduledExecution(fmu.modelDescription)
export isScheduledExecution

# additional functions 

"""
    getValueReferencesAndNames(obj; vrs=md.valueReferences)

with:

obj ∈ (fmi2ModelDescription, FMU2)

Returns a dictionary `Dict(fmi2ValueReference, Array{String})` of value references and their corresponding names.

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Keywords
- `vrs=md.valueReferences`: Additional attribute `valueReferences::Array{fmi2ValueReference}` of the Model Description that  is a handle to a (base type) variable value. Handle and base type uniquely identify the value of a variable. (default = `md.valueReferences::Array{fmi2ValueReference}`)

# Returns
- `dict::Dict{fmi2ValueReference, Array{String}}`: Returns a dictionary that constructs a hash table with keys of type fmi2ValueReference and values of type Array{String}.

"""
function getValueReferencesAndNames(md::fmi2ModelDescription; vrs = md.valueReferences)
    dict = Dict{fmi2ValueReference,Array{String}}()
    for vr in vrs
        dict[vr] = valueReferenceToString(md, vr)
    end
    return dict
end
getValueReferencesAndNames(fmu::FMU2) = getValueReferencesAndNames(fmu.modelDescription)
export getValueReferencesAndNames

"""
    getNames(md::fmi2ModelDescription; vrs=md.valueReferences, mode=:first)

Returns a array of names corresponding to value references `vrs`.

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Keywords
- `vrs=md.valueReferences`: Additional attribute `valueReferences::Array{fmi2ValueReference}` of the Model Description that  is a handle to a (base type) variable value. Handle and base type uniquely identify the value of a variable. (default = `md.valueReferences::Array{fmi2ValueReference}`)
- `mode=:first`: If there are multiple names per value reference, availabel modes are `:first` (default, pick only the first one), `:group` (pick all and group them into an array) and `:flat` (pick all, but flat them out into a 1D-array together with all other names)
# Returns
- `names::Array{String}`: Returns a array of names corresponding to value references `vrs`
"""
function getNames(md::fmi2ModelDescription; vrs = md.valueReferences, mode = :first)
    names = []
    for vr in vrs
        ns = valueReferenceToString(md, vr)

        if mode == :first
            push!(names, ns[1])
        elseif mode == :group
            push!(names, ns)
        elseif mode == :flat
            for n in ns
                push!(names, n)
            end
        else
            @assert false "fmi2GetNames(...) unknown mode `mode`, please choose between `:first`, `:group` and `:flat`."
        end
    end
    return mode == :group ? [string.(name) for name in names] : string.(names)
end
getNames(fmu::FMU2; kwargs...) = getNames(fmu.modelDescription; kwargs...)
export getNames

"""
    getModelVariableIndices(md::fmi2ModelDescription; vrs=md.valueReferences)

Returns a array of indices corresponding to value references `vrs`

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Keywords
- `vrs=md.valueReferences`: Additional attribute `valueReferences::Array{fmi2ValueReference}` of the Model Description that  is a handle to a (base type) variable value. Handle and base type uniquely identify the value of a variable. (default = `md.valueReferences::Array{fmi2ValueReference}`)

# Returns
- `names::Array{Integer}`: Returns a array of indices corresponding to value references `vrs`

"""
function getModelVariableIndices(md::fmi2ModelDescription; vrs = md.valueReferences)
    indices = []

    for i = 1:length(md.modelVariables)
        if md.modelVariables[i].valueReference in vrs
            push!(indices, i)
        end
    end

    return indices
end
getModelVariableIndices(fmu::FMU) = getModelVariableIndices(fmu.modelDescription)
export getModelVariableIndices

"""
    getInputValueReferencesAndNames(md::fmi2ModelDescription)

Returns a dict with (vrs, names of inputs).

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.
- `fmu::FMU2`: Mutable struct representing a FMU and all it instantiated instances in the FMI 2.0.2 Standard.


# Returns
- `dict::Dict{fmi2ValueReference, Array{String}}`: Returns a dictionary that constructs a hash table with keys of type fmi2ValueReference and values of type Array{String}. So returns a dict with (vrs, names of inputs)

"""
getInputValueReferencesAndNames(md::fmiModelDescription) =
    getValueReferencesAndNames(md; vrs = md.inputValueReferences)
getInputValueReferencesAndNames(fmu::FMU) =
    getInputValueReferencesAndNames(fmu.modelDescription)
export getInputValueReferencesAndNames

"""
    getInputNames(md::fmi2ModelDescription; vrs=md.inputvalueReferences, mode=:first)

Returns names of inputs.

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Keywords
- `vrs=md.inputvalueReferences`: Additional attribute `inputvalueReferences::Array{fmi2ValueReference}` of the Model Description that is a handle to a (base type) variable value. Handle and base type uniquely identify the value of a variable. (default = `md.valueReferences::Array{fmi2ValueReference}`)
- `mode=:first`: If there are multiple names per value reference, availabel modes are `:first` (default, pick only the first one), `:group` (pick all and group them into an array) and `:flat` (pick all, but flat them out into a 1D-array together with all other names)
# Returns
- `names::Array{String}`: Returns a array of names corresponding to value references `vrs`

"""
getInputNames(md::fmiModelDescription; kwargs...) =
    getNames(md; vrs = md.inputValueReferences, kwargs...)
getInputNames(fmu::FMU; kwargs...) = getInputNames(fmu.modelDescription; kwargs...)
export getInputNames

"""
    getOutputValueReferencesAndNames(md::fmi2ModelDescription)

Returns a dictionary `Dict(fmi2ValueReference, Array{String})` of value references and their corresponding names.

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Keywords
- `vrs=md.outputvalueReferences`: Additional attribute `outputvalueReferences::Array{fmi2ValueReference}` of the Model Description that is a handle to a (base type) variable value. Handle and base type uniquely identify the value of a variable. (default = `md.outputvalueReferences::Array{fmi2ValueReference}`)

# Returns
- `dict::Dict{fmi2ValueReference, Array{String}}`: Returns a dictionary that constructs a hash table with keys of type fmi2ValueReference and values of type Array{String}.So returns a dict with (vrs, names of outputs)

"""
getOutputValueReferencesAndNames(md::fmiModelDescription) =
    getValueReferencesAndNames(md; vrs = md.outputValueReferences)
getOutputValueReferencesAndNames(fmu::FMU) =
    getOutputValueReferencesAndNames(fmu.modelDescription)
export getOutputValueReferencesAndNames

"""
    fmi2GetOutputNames(md::fmi2ModelDescription; vrs=md.outputvalueReferences, mode=:first)

Returns names of outputs.

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Keywords
- `vrs=md.outputvalueReferences`: Additional attribute `outputvalueReferences::Array{fmi2ValueReference}` of the Model Description that is a handle to a (base type) variable value. Handle and base type uniquely identify the value of a variable. (default = `md.outputvalueReferences::Array{fmi2ValueReference}`)
- `mode=:first`: If there are multiple names per value reference, availabel modes are `:first` (default, pick only the first one), `:group` (pick all and group them into an array) and `:flat` (pick all, but flat them out into a 1D-array together with all other names)
# Returns
- `names::Array{String}`: Returns a array of names corresponding to value references `vrs`

"""
getOutputNames(md::fmiModelDescription; kwargs...) =
    getNames(md; vrs = md.outputValueReferences, kwargs...)
getOutputNames(fmu::FMU; kwargs...) = getOutputNames(fmu.modelDescription; kwargs...)
export getOutputNames

"""
    getParameterValueReferencesAndNames(md::fmi2ModelDescription)

Returns a dictionary `Dict(fmi2ValueReference, Array{String})` of parameterValueReferences and their corresponding names.

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Returns
- `dict::Dict{fmi2ValueReference, Array{String}}`: Returns a dictionary that constructs a hash table with keys of type fmi2ValueReference and values of type Array{String}. So returns a dict with (vrs, names of parameters).

See also [`getValueReferencesAndNames`](@ref).
"""
getParameterValueReferencesAndNames(md::fmiModelDescription) =
    getValueReferencesAndNames(md; vrs = md.parameterValueReferences)
getParameterValueReferencesAndNames(fmu::FMU) =
    getParameterValueReferencesAndNames(fmu.modelDescription)
export getParameterValueReferencesAndNames

"""
    fmi2GetParameterNames(md::fmi2ModelDescription; vrs=md.parameterValueReferences, mode=:first)

Returns names of parameters.

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Keywords
- `vrs=md.parameterValueReferences`: Additional attribute `parameterValueReferences::Array{fmi2ValueReference}` of the Model Description that  is a handle to a (base type) variable value. Handle and base type uniquely identify the value of a variable. (default = `md.parameterValueReferences::Array{fmi2ValueReference}`)
- `mode=:first`: If there are multiple names per value reference, availabel modes are `:first` (default, pick only the first one), `:group` (pick all and group them into an array) and `:flat` (pick all, but flat them out into a 1D-array together with all other names)
# Returns
- `names::Array{String}`: Returns a array of names corresponding to parameter value references `vrs`


"""
getParameterNames(md::fmiModelDescription; kwargs...) =
    getNames(md; vrs = md.parameterValueReferences, kwargs...)
getParameterNames(fmu::FMU; kwargs...) = getParameterNames(fmu.modelDescription; kwargs...)
export getParameterNames

"""
    fmi2GetStateValueReferencesAndNames(md::fmi2ModelDescription)

Returns a dictionary `Dict(fmi2ValueReference, Array{String})` of state value references and their corresponding names.

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Returns
- `dict::Dict{fmi2ValueReference, Array{String}}`: Returns a dictionary that constructs a hash table with keys of type fmi2ValueReference and values of type Array{String}. So returns a dict with (vrs, names of states)

"""
getStateValueReferencesAndNames(md::fmiModelDescription) =
    getValueReferencesAndNames(md; vrs = md.stateValueReferences)
getStateValueReferencesAndNames(fmu::FMU) =
    getStateValueReferencesAndNames(fmu.modelDescription)
export getStateValueReferencesAndNames

"""
    fmi2GetStateNames(fmu::FMU2; vrs=md.stateValueReferences, mode=:first)

Returns names of states.

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Keywords
- `vrs=md.stateValueReferences`: Additional attribute `parameterValueReferences::Array{fmi2ValueReference}` of the Model Description that  is a handle to a (base type) variable value. Handle and base type uniquely identify the value of a variable. (default = `md.stateValueReferences::Array{fmi2ValueReference}`)
- `mode=:first`: If there are multiple names per value reference, availabel modes are `:first` (default, pick only the first one), `:group` (pick all and group them into an array) and `:flat` (pick all, but flat them out into a 1D-array together with all other names)
# Returns
- `names::Array{String}`: Returns a array of names corresponding to parameter value references `vrs`


"""
getStateNames(md::fmiModelDescription; kwargs...) =
    getNames(md; vrs = md.stateValueReferences, kwargs...)
getStateNames(fmu::FMU; kwargs...) = getStateNames(fmu.modelDescription; kwargs...)
export getStateNames

"""
    fmi2GetDerivateValueReferencesAndNames(md::fmi2ModelDescription)

Returns a dictionary `Dict(fmi2ValueReference, Array{String})` of derivative value references and their corresponding names.

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Returns
- `dict::Dict{fmi2ValueReference, Array{String}}`: Returns a dictionary that constructs a hash table with keys of type fmi2ValueReference and values of type Array{String}. So returns a dict with (vrs, names of derivatives)
See also [`getValueReferencesAndNames`](@ref)
"""
getDerivateValueReferencesAndNames(md::fmiModelDescription) =
    getValueReferencesAndNames(md; vrs = md.derivativeValueReferences)
getDerivateValueReferencesAndNames(fmu::FMU) =
    getDerivateValueReferencesAndNames(fmu.modelDescription)
export getDerivateValueReferencesAndNames

"""
    fmi2GetDerivativeNames(md::fmi2ModelDescription; vrs=md.derivativeValueReferences, mode=:first)

Returns names of derivatives.

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Keywords
- `vrs=md.derivativeValueReferences`: Additional attribute `derivativeValueReferences::Array{fmi2ValueReference}` of the Model Description that  is a handle to a (base type) variable value. Handle and base type uniquely identify the value of a variable. (default = `md.derivativeValueReferences::Array{fmi2ValueReference}`)
- `mode=:first`: If there are multiple names per value reference, availabel modes are `:first` (default, pick only the first one), `:group` (pick all and group them into an array) and `:flat` (pick all, but flat them out into a 1D-array together with all other names)
# Returns
- `names::Array{String}`: Returns a array of names corresponding to parameter value references `vrs`


"""
getDerivativeNames(md::fmiModelDescription; kwargs...) =
    getNames(md; vrs = md.derivativeValueReferences, kwargs...)
getDerivativeNames(fmu::FMU; kwargs...) =
    getDerivativeNames(fmu.modelDescription; kwargs...)
export getDerivativeNames

"""
    getNamesAndDescriptions(md::fmi2ModelDescription)

Returns a dictionary of variables with their descriptions.

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Returns
- `dict::Dict{String, String}`: Returns a dictionary that constructs a hash table with keys of type String and values of type String. So returns a dict with ( `md.modelVariables[i].name::String`, `md.modelVariables[i].description::Union{String, Nothing}`). (Creates a tuple (name, description) for each i in 1:length(md.modelVariables))
"""
function getNamesAndDescriptions(md::fmiModelDescription)
    Dict(
        md.modelVariables[i].name => md.modelVariables[i].description for
        i = 1:length(md.modelVariables)
    )
end
getNamesAndDescriptions(fmu::FMU) = getNamesAndDescriptions(fmu.modelDescription)
export getNamesAndDescriptions

"""
    getNamesAndUnits(md::fmi2ModelDescription)

Returns a dictionary of variables with their units.

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Returns
- `dict::Dict{String, String}`: Returns a dictionary that constructs a hash table with keys of type String and values of type String. So returns a dict with ( `md.modelVariables[i].name::String`, `md.modelVariables[i]._Real.unit::Union{String, Nothing}`). (Creates a tuple (name, unit) for each i in 1:length(md.modelVariables))
See also [`getUnit`](@ref).
"""
function getNamesAndUnits(md::fmiModelDescription)
    Dict(
        md.modelVariables[i].name => getUnit(md.modelVariables[i]) for
        i = 1:length(md.modelVariables)
    )
end
getNamesAndUnits(fmu::FMU) = getNamesAndUnits(fmu.modelDescription)
export getNamesAndUnits

"""
    getNamesAndInitials(md::fmi2ModelDescription)

Returns a dictionary of variables with their initials.

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Returns
- `dict::Dict{String, Cuint}`: Returns a dictionary that constructs a hash table with keys of type String and values of type Cuint. So returns a dict with ( `md.modelVariables[i].name::String`, `md.modelVariables[i].inital::Union{fmi2Initial, Nothing}`). (Creates a tuple (name,initial) for each i in 1:length(md.modelVariables))
See also [`getInitial`](@ref).
"""
function getNamesAndInitials(md::fmiModelDescription)
    Dict(
        md.modelVariables[i].name => getInitial(md.modelVariables[i]) for
        i = 1:length(md.modelVariables)
    )
end
getNamesAndInitials(fmu::FMU) = getNamesAndInitials(fmu.modelDescription)
export getNamesAndInitials

"""
    getInputNamesAndStarts(md::fmi2ModelDescription)

Returns a dictionary of input variables with their starting values.

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Returns
- `dict::Dict{String, Array{fmi2ValueReferenceFormat}}`: Returns a dictionary that constructs a hash table with keys of type String and values of type fmi2ValueReferenceFormat. So returns a dict with ( `md.modelVariables[i].name::String`, `starts:: Array{fmi2ValueReferenceFormat}` ). (Creates a tuple (name, starts) for each i in inputIndices)
See also [`getStartValue`](@ref).
"""
function getInputNamesAndStarts(md::fmiModelDescription)
    inputIndices = getModelVariableIndices(md; vrs = md.inputValueReferences)
    Dict(
        md.modelVariables[i].name => getStartValue(md.modelVariables[i]) for
        i in inputIndices
    )
end
getInputNamesAndStarts(fmu::FMU) = getInputNamesAndStarts(fmu.modelDescription)
export getInputNamesAndStarts

"""
    getStartValue(md::fmi2ModelDescription, vrs::fmi2ValueReferenceFormat = md.valueReferences)

Returns the start/default value for a given value reference.

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.
- `vrs::fmi2ValueReferenceFormat = md.valueReferences`: wildcards for how a user can pass a fmi[X]ValueReference (default = md.valueReferences)
More detailed: `fmi2ValueReferenceFormat = Union{Nothing, String, Array{String,1}, fmi2ValueReference, Array{fmi2ValueReference,1}, Int64, Array{Int64,1}, Symbol}`

# Returns
- `starts::Array{fmi2ValueReferenceFormat}`: start/default value for a given value reference

# Source
- FMISpec2.0.2 Link: [https://fmi-standard.org/](https://fmi-standard.org/)
- FMISpec2.0.2: 2.2.7  Definition of Model Variables (ModelVariables)
"""
function getStartValue(
    md::fmi2ModelDescription,
    vrs::fmi2ValueReferenceFormat = md.valueReferences,
)

    vrs = prepareValueReference(md, vrs)

    starts = []

    for vr in vrs
        mvs = modelVariablesForValueReference(md, vr)

        if length(mvs) == 0
            @warn "getStartValue(...): Found no model variable with value reference $(vr)."
        end

        push!(starts, getStartValue(mvs[1]))
    end

    if length(vrs) == 1
        return starts[1]
    else
        return starts
    end
end
function getStartValue(
    fmu::FMU2,
    vrs::fmi2ValueReferenceFormat = fmu.modelDescription.valueReferences,
)
    getStartValue(fmu.modelDescription, vrs)
end
function getStartValue(
    md::fmi3ModelDescription,
    vrs::fmi3ValueReferenceFormat = md.valueReferences,
)

    vrs = prepareValueReference(md, vrs)

    starts = []

    for vr in vrs
        mvs = modelVariablesForValueReference(md, vr)

        if length(mvs) == 0
            @warn "getStartValue(...): Found no model variable with value reference $(vr)."
        end

        push!(starts, getStartValue(mvs[1]))
    end

    if length(vrs) == 1
        return starts[1]
    else
        return starts
    end
end
function getStartValue(
    fmu::FMU3,
    vrs::fmi3ValueReferenceFormat = fmu.modelDescription.valueReferences,
)
    getStartValue(fmu.modelDescription, vrs)
end
function getStartValue(
    c::FMU2Component,
    vrs::fmi2ValueReferenceFormat = c.fmu.modelDescription.valueReferences,
)

    vrs = prepareValueReference(c, vrs)

    starts = []

    for vr in vrs
        mvs = modelVariablesForValueReference(c.fmu.modelDescription, vr)

        if length(mvs) == 0
            @warn "fmi2GetStartValue(...): Found no model variable with value reference $(vr)."
        end

        if mvs[1].Real != nothing
            push!(starts, mvs[1].Real.start)
        elseif mvs[1].Integer != nothing
            push!(starts, mvs[1].Integer.start)
        elseif mvs[1].Boolean != nothing
            push!(starts, mvs[1].Boolean.start)
        elseif mvs[1].String != nothing
            push!(starts, mvs[1].String.start)
        elseif mvs[1].Enumeration != nothing
            push!(starts, mvs[1].Enumeration.start)
        else
            @assert false "fmi2GetStartValue(...): Value reference $(vr) has no data type."
        end
    end

    if length(vrs) == 1
        return starts[1]
    else
        return starts
    end
end
function getStartValue(mv::fmi2ScalarVariable)
    if mv.Real != nothing
        return mv.Real.start
    elseif mv.Integer != nothing
        return mv.Integer.start
    elseif mv.Boolean != nothing
        return mv.Boolean.start
    elseif mv.String != nothing
        return mv.String.start
    elseif mv.Enumeration != nothing
        return mv.Enumeration.start
    else
        @assert false "fmi2GetStartValue(...): Variable $(mv) has no data type."
    end
end
function getStartValue(
    c::FMU3Instance,
    vrs::fmi3ValueReferenceFormat = c.fmu.modelDescription.valueReferences,
)

    vrs = prepareValueReference(c, vrs)

    starts = []

    for vr in vrs
        mvs = modelVariablesForValueReference(c.fmu.modelDescription, vr)

        if length(mvs) == 0
            @warn "fmi3GetStartValue(...): Found no model variable with value reference $(vr)."
        end
        for mv in mvs
            if hasproperty(mv, :start)
                push!(starts, mv.start)
            end
        end
    end

    if length(vrs) == 1
        return starts[1]
    else
        return starts
    end
end
function getStartValue(mv::fmi3Variable)
    if hasproperty(mv, :start)
        return mv.start
    end
end
export getStartValue

"""
    getUnit(mv::fmi2ScalarVariable)

Returns the `unit` entry (a string) of the corresponding model variable.

# Arguments
- `fmi2GetStartValue(mv::fmi2ScalarVariable)`: The “ModelVariables” element consists of an ordered set of “ScalarVariable” elements. A “ScalarVariable” represents a variable of primitive type, like a real or integer variable.

# Returns
- `mv.Real.unit`: Returns the `unit` entry of the corresponding ScalarVariable representing a variable of the primitive type Real. Otherwise `nothing` is returned.
# Source
- FMISpec2.0.2 Link: [https://fmi-standard.org/](https://fmi-standard.org/)
- FMISpec2.0.2: 2.2.7  Definition of Model Variables (ModelVariables)
"""
function getUnit(mv::fmi2ScalarVariable)
    if !isnothing(mv.Real)
        return mv.Real.unit
    else
        return nothing
    end
end
function getUnit(mv::fmi3Variable)
    if mv._Float !== nothing
        return mv._Float.unit
    else
        return nothing
    end
end
function getUnit(st::fmi2SimpleType)
    if hasproperty(st, :Real)
        return st.Real.unit
    else
        return nothing
    end
end
function getUnit(md::fmi2ModelDescription, mv::Union{fmi2ScalarVariable,fmi2SimpleType}) # ToDo: Multiple Dispatch!
    unit_str = getUnit(mv)
    if !isnothing(unit_str)
        ui = findfirst(unit -> unit.name == unit_str, md.unitDefinitions)
        if !isnothing(ui)
            return md.unitDefinitions[ui]
        end
    end
    return nothing
end
export getUnit

"""
    getDeclaredType(md::fmi2ModelDescription, mv::fmi2ScalarVariable)

Returns the `fmi2SimpleType` of the corresponding model variable `mv` as defined in
`md.typeDefinitions`.
If `mv` does not have a declared type, return `nothing`.
If `mv` has a declared type, but it is not found, issue a warning and return `nothing`.

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.
- `mv::fmi2ScalarVariable`: The “ModelVariables” element consists of an ordered set of “ScalarVariable” elements. A “ScalarVariable” represents a variable of primitive type, like a real or integer variable.

# Source
- FMISpec2.0.3 Link: [https://fmi-standard.org/](https://fmi-standard.org/)
- FMISpec2.0.3: 2.2.7  Definition of Model Variables (ModelVariables)
"""
function getDeclaredType(md::fmi2ModelDescription, mv::fmi2ScalarVariable)
    if isdefined(mv.attribute, :declaredType)
        dt = mv.attribute.declaredType
        if !isnothing(dt)
            for simple_type in md.typeDefinitions
                if dt == simple_type.name
                    return simple_type
                end
            end
            @warn "`fmi2GetDeclaredType`: Could not find a type definition with name \"$(dt)\" in the `typeDefinitions` of $(md)."
        end
    end
    return nothing
end
export getDeclaredType

# TODO with the new `fmi2SimpleType` definition this function is superfluous...remove?
"""
    getSimpleTypeAttributeStruct(st::fmi2SimpleType)

Returns the attribute structure for the simple type `st`.
Depending on definition, this is either `st.Real`, `st.Integer`, `st.String`,
`st.Boolean` or `st.Enumeration`.

# Arguments
- `st::fmi2SimpleType`: Struct which provides the information on custom SimpleTypes.

# Source
- FMISpec2.0.3 Link: [https://fmi-standard.org/](https://fmi-standard.org/)
- FMISpec2.0.3[p.40]: 2.2.3 Definition of Types (TypeDefinitions)
"""
function getSimpleTypeAttributeStruct(st::fmi2SimpleType)
    return typeof(st.attribute)
end
export getSimpleTypeAttributeStruct

"""
    getInitial(mv::fmi2ScalarVariable)

Returns the `inital` entry of the corresponding model variable.

# Arguments
- `fmi2GetStartValue(mv::fmi2ScalarVariable)`: The “ModelVariables” element consists of an ordered set of “ScalarVariable” elements. A “ScalarVariable” represents a variable of primitive type, like a real or integer variable.

# Returns
- `mv.Real.unit`: Returns the `inital` entry of the corresponding ScalarVariable representing a variable of the primitive type Real. Otherwise `nothing` is returned.

# Source
- FMISpec2.0.2 Link: [https://fmi-standard.org/](https://fmi-standard.org/)
- FMISpec2.0.2: 2.2.7  Definition of Model Variables (ModelVariables)
"""
function getInitial(mv::fmi2ScalarVariable)
    return mv.initial
end
function getInitial(mv::fmi3Variable)
    return mv.initial
end
export getInitial

"""
    canGetSetFMUState(md::fmi2ModelDescription)

Returns true, if the FMU supports the getting/setting of states

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Returns
- `::Bool`: Returns true, if the FMU supports the getting/setting of states.

"""
function canGetSetFMUState(md::fmi2ModelDescription)
    if !isnothing(md.coSimulation)
        return md.coSimulation.canGetAndSetFMUstate
    elseif !isnothing(md.modelExchange)
        return md.modelExchange.canGetAndSetFMUstate
    end
end
function canGetSetFMUState(md::fmi3ModelDescription)
    if !isnothing(md.coSimulation)
        return md.coSimulation.canGetAndSetFMUState
    elseif !isnothing(md.modelExchange)
        return md.modelExchange.canGetAndSetFMUState
    elseif !isnothing(md.scheduledExecution)
        return md.scheduledExecution.canGetAndSetFMUState
    end
end
canGetSetFMUState(fmu::FMU) = canGetSetFMUState(fmu.modelDescription)
export canGetSetFMUState

"""
    canSerializeFMUState(md::fmi2ModelDescription)

Returns true, if the FMU state can be serialized

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Returns
- `::Bool`: Returns true, if the FMU state can be serialized

"""
function canSerializeFMUState(md::fmi2ModelDescription)
    if !isnothing(md.coSimulation)
        return md.coSimulation.canSerializeFMUstate
    elseif !isnothing(md.modelExchange)
        return md.modelExchange.canSerializeFMUstate
    end
end
function canSerializeFMUState(md::fmi3ModelDescription)
    if !isnothing(md.coSimulation)
        return md.coSimulation.canSerializeFMUState
    elseif !isnothing(md.modelExchange)
        return md.modelExchange.canSerializeFMUState
    elseif !isnothing(md.scheduledExecution)
        return md.scheduledExecution.canSerializeFMUState
    end
end
canSerializeFMUState(fmu::FMU) = canSerializeFMUState(fmu.modelDescription)
export canSerializeFMUState

"""
    providesDirectionalDerivative(md::fmi2ModelDescription)

Returns true, if the FMU provides directional derivatives

# Arguments
- `md::fmi2ModelDescription`: Struct which provides the static information of ModelVariables.

# Returns
- `::Bool`: Returns true, if the FMU provides directional derivatives

"""
function providesDirectionalDerivatives(md::fmi3ModelDescription)
    if !isnothing(md.coSimulation)
        return (md.coSimulation.providesDirectionalDerivatives == true)
    elseif !isnothing(md.modelExchange)
        return (md.modelExchange.providesDirectionalDerivatives == true)
    elseif !isnothing(md.scheduledExecution)
        return (md.scheduledExecution.providesDirectionalDerivatives == true)
    end

    return false
end
function providesDirectionalDerivatives(md::fmi2ModelDescription)
    if !isnothing(md.coSimulation)
        return (md.coSimulation.providesDirectionalDerivative == true)
    elseif !isnothing(md.modelExchange)
        return (md.modelExchange.providesDirectionalDerivative == true)
    end

    return false
end
providesDirectionalDerivatives(fmu::FMU) =
    providesDirectionalDerivatives(fmu.modelDescription)
export providesDirectionalDerivatives

"""
Returns true, if the FMU provides adjoint derivatives
"""
function providesAdjointDerivatives(md::fmi3ModelDescription)
    if !isnothing(md.coSimulation)
        return md.coSimulation.providesAdjointDerivatives
    elseif !isnothing(md.modelExchange)
        return md.modelExchange.providesAdjointDerivatives
    elseif !isnothing(md.scheduledExecution)
        return md.scheduledExecution.providesAdjointDerivatives
    end

    return false
end
function providesAdjointDerivatives(::fmi2ModelDescription)
    @warn "providesAdjointDerivatives is only available in FMI3!"
    return false
end
providesAdjointDerivatives(fmu::FMU) = providesAdjointDerivatives(fmu.modelDescription)
export providesAdjointDerivatives

"""
Returns the tag 'instantionToken' from the model description.
"""
function getInstantiationToken(md::fmi3ModelDescription)
    md.instantiationToken
end
function getInstantiationToken(md::fmi2ModelDescription)
    @warn "Instantiation token is only available in FMI3!"
    return nothing
end
getInstantiationToken(fmu::FMU) = getInstantiationToken(fmu.modelDescription)
export getInstantiationToken
