"""
    Layered Standard 
"""
mutable struct FMIModelDescriptionLSSA
    name::String
    version::String
    description::String

    previous::Dict{Union{fmi2ValueReference, fmi3ValueReference}, Union{fmi2ValueReference, fmi3ValueReference}}

    discreteStates::Vector{Union{fmi2ValueReference, fmi3ValueReference}}
    errorIndicators::Vector{Union{fmi2ValueReference, fmi3ValueReference}}

    function FMIModelDescriptionLSSA()
        inst = new()
        inst.name = ""
        inst.version = ""
        inst.description = ""
        inst.previous = Dict{Union{fmi2ValueReference, fmi3ValueReference}, Union{fmi2ValueReference, fmi3ValueReference}}()
        inst.discreteStates = Vector{Union{fmi2ValueReference, fmi3ValueReference}}()
        inst.errorIndicators = Vector{Union{fmi2ValueReference, fmi3ValueReference}}()
        return inst
    end
end
export FMIModelDescriptionLSSA