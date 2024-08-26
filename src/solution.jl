#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

"""
    getState(solution::FMUSolution, vr::fmi2ValueReferenceFormat; isIndex::Bool=false)

Returns the Solution state.

# Arguments
- `solution::FMUSolution`: Struct contains information about the solution `value`, `success`, `state` and  `events` of a specific FMU.
- `vr::fmi2ValueReferenceFormat`: wildcards for how a user can pass a fmi[X]ValueReference (default = md.valueReferences)
More detailed: `fmi2ValueReferenceFormat = Union{Nothing, String, Array{String,1}, fmi2ValueReference, Array{fmi2ValueReference,1}, Int64, Array{Int64,1}, Symbol}`
- `isIndex::Bool=false`: Argument `isIndex` exists to check if `vr` ist the spezific solution element ("index") that equals the given fmi2ValueReferenceFormat

# Return
- If he length of the given referencees equals 1, each element u in the collection `solution.states.u`, it is selecting the element at the index represented by indices[1] and returns it.
 Thus, the collect() function is taking the generator expression and returning an array of the selected elements. 
- If more than one reference is given, the same process takes place as before. The difference is that now more than one indice is accessed.

# Source
- FMISpec2.0.2 Link: [https://fmi-standard.org/](https://fmi-standard.org/)
- FMISpec2.0.2[p.22]: 2.1.2 Platform Dependent Definitions (fmi2TypesPlatform.h)
"""
function getState(solution::FMUSolution, vrs::fmi2ValueReferenceFormat; isIndex::Bool=false)

    indices = []

    if isIndex
        if length(vrs) == 1
            indices = [vrs]
        else
            indices = vrs
        end
    else
        ignore_derivatives() do
            vrs = prepareValueReference(solution.component.fmu, vrs)

            if !isnothing(solution.states)
                for vr in vrs
                    found = false
                    for i in 1:length(solution.component.fmu.modelDescription.stateValueReferences)
                        if solution.component.fmu.modelDescription.stateValueReferences[i] == vr
                            push!(indices, i)
                            found = true 
                            break
                        end
                    end
                    @assert found "Couldn't find the index for value reference `$(vr)`! This is probaly because this value reference does not belong to a system state."
                end
            end

        end # ignore_derivatives
    end

    # found something
    if length(indices) == length(vrs)

        if length(vrs) == 1  # single value
            return collect(u[indices[1]] for u in solution.states.u)

        else # multi value
            return collect(collect(u[indices[i]] for u in solution.states.u) for i in 1:length(indices))

        end
    end

    return nothing
end
export getState

"""
    getDerivative(solution::FMUSolution, vr::fmi2ValueReferenceFormat; isIndex::Bool=false)

Returns the solution state derivative.

# Arguments
- `solution::FMUSolution`: Struct contains information about the solution `value`, `success`, `state` and  `events` of a specific FMU.
- `vr::fmi2ValueReferenceFormat`: wildcards for how a user can pass a fmi[X]ValueReference (default = md.valueReferences)
More detailed: `fmi2ValueReferenceFormat = Union{Nothing, String, Array{String,1}, fmi2ValueReference, Array{fmi2ValueReference,1}, Int64, Array{Int64,1}, Symbol}`
- `isIndex::Bool=false`: Argument `isIndex` exists to check if `vr` ist the spezific solution element ("index") that equals the given fmi2ValueReferenceFormat

# Return
- If the length of the given referencees equals 1, each element `myt` in the collection `solution.states.t` is selecting the derivative of the solution states represented by indices[1] in respect to time, at time `myt` and returns its it.
 Thus, the collect() function is taking the generator expression and returning an array of the selected derivatives. 
- If more than one reference is given, the same process takes place as before. The difference is that now more than one indice is accessed.

# Source
- FMISpec2.0.2 Link: [https://fmi-standard.org/](https://fmi-standard.org/)
- FMISpec2.0.2[p.22]: 2.1.2 Platform Dependent Definitions (fmi2TypesPlatform.h)
"""
function getDerivative(solution::FMUSolution, vrs::fmi2ValueReferenceFormat; isIndex::Bool=false, order::Integer=1)
    indices = []

    if isIndex
        if length(vrs) == 1
            indices = [vrs]
        else
            indices = vrs
        end
    else
        ignore_derivatives() do
            vrs = prepareValueReference(solution.component.fmu, vrs)

            if !isnothing(solution.states)
                for vr in vrs
                    found = false
                    for i in 1:length(solution.component.fmu.modelDescription.stateValueReferences)
                        if solution.component.fmu.modelDescription.stateValueReferences[i] == vr
                            push!(indices, i)
                            found = true 
                            break
                        end
                    end
                    @assert found "Couldn't find the index for value reference `$(vr)`! This is probaly because this value reference does not belong to a system state."
                end
            end

        end # ignore_derivatives
    end

    # found something
    if length(indices) == length(vrs)

        if length(vrs) == 1  # single value
            return collect(solution.states(t, Val{order})[indices[1]] for t in solution.states.t)

        else # multi value
            return collect(collect(solution.states(t, Val{order})[indices[i]] for t in solution.states.t) for i in 1:length(indices))
        end
    end

    return nothing
end
export getDerivative

"""
    getValue(solution::FMUSolution, vr::fmi2ValueReferenceFormat; isIndex::Bool=false)

Returns the Solution values.

# Arguments
- `solution::FMUSolution`: Struct contains information about the solution `value`, `success`, `state` and  `events` of a specific FMU.
- `vr::fmi2ValueReferenceFormat`: wildcards for how a user can pass a fmi[X]ValueReference (default = md.valueReferences)
More detailed: `fmi2ValueReferenceFormat = Union{Nothing, String, Array{String,1}, fmi2ValueReference, Array{fmi2ValueReference,1}, Int64, Array{Int64,1}, Symbol}`
- `isIndex::Bool=false`: Argument `isIndex` exists to check if `vr` ist the spezific solution element ("index") that equals the given fmi2ValueReferenceFormat

# Return
- If he length of the given referencees equals 1, each element u in the collection `solution.values.saveval` is selecting the element at the index represented by indices[1] and returns it.
 Thus, the collect() function is taking the generator expression and returning an array of the selected elements. 
- If more than one reference is given, the same process takes place as before. The difference is that now more than one indice is accessed.


# Source
- FMISpec2.0.2 Link: [https://fmi-standard.org/](https://fmi-standard.org/)
- FMISpec2.0.2[p.22]: 2.1.2 Platform Dependent Definitions (fmi2TypesPlatform.h)
"""
function getValue(solution::FMUSolution, vrs::fmi2ValueReferenceFormat; isIndex::Bool=false)

    indices = []

    if isIndex
        if length(vrs) == 1
            indices = [vrs]
        else
            indices = vrs
        end
    else
        ignore_derivatives() do
            vrs = prepareValueReference(solution.component.fmu, vrs)

            if !isnothing(solution.values)
                for vr in vrs
                    found = false
                    for i in 1:length(solution.valueReferences)
                        if solution.valueReferences[i] == vr
                            push!(indices, i)
                            found = true 
                            break
                        end
                    end
                    @assert found "Couldn't find the index for value reference `$(vr)`! This is probaly because this value reference does not exist for this system."
                end
            end

        end # ignore_derivatives
    end

    # found something
    if length(indices) == length(vrs)

        if length(vrs) == 1  # single value
            return collect(u[indices[1]] for u in solution.values.saveval)

        else # multi value
            return collect(collect(u[indices[i]] for u in solution.values.saveval) for i in 1:length(indices))

        end
    end

    return nothing
end
export getValue

"""
    getTime(solution::FMUSolution)

Returns the Solution time.

# Arguments
- `solution::FMUSolution`: Struct contains information about the solution `value`, `success`, `state` and  `events` of a specific FMU.

# Return
- `solution.states.t::tType`: `solution.state` is a struct `ODESolution` with attribute t. `t` is the time points corresponding to the saved values of the ODE solution.
- `solution.values.t::tType`: `solution.value` is a struct `ODESolution` with attribute t.`t` the time points corresponding to the saved values of the ODE solution.
- If no solution time is  found `nothing` is returned.

#Source
- using OrdinaryDiffEq: [ODESolution](https://github.com/SciML/SciMLBase.jl/blob/b10025c579bcdecb94b659aa3723fdd023096197/src/solutions/ode_solutions.jl)  (SciML/SciMLBase.jl)
- FMISpec2.0.2 Link: [https://fmi-standard.org/](https://fmi-standard.org/)
- FMISpec2.0.2[p.22]: 2.1.2 Platform Dependent Definitions (fmi2TypesPlatform.h)
"""
function getTime(solution::FMUSolution)
    if solution.states !== nothing
        return solution.states.t
    elseif solution.values !== nothing
        return solution.values.t
    else
        return nothing
    end
end
export getTime