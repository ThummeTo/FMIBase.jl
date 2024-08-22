#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

# FMUSolution 

function Base.setproperty!(obj::FMUSolution, var::Symbol, value)
    if var == :component 
        @warn "`FMUSolution.component` is deprecated, use `FMUSolution.instance` instead." maxlog=3
        return Base.setfield!(obj, :instance, value)
    end
    return Base.setfield!(obj, var, value)
end

function Base.hasproperty(obj::FMUSolution, var::Symbol)
    if var == :component 
        @warn "`FMUSolution.component` is deprecated, use `FMUSolution.instance` instead." maxlog=3
        return true
    end
    return Base.hasfield(obj, var)
end

function Base.getproperty(obj::FMUSolution, var::Symbol)
    if var == :component
        @warn "`FMUSolution.component` is deprecated, use `FMUSolution.instance` instead." maxlog=3
        return Base.getfield(obj, :instance)
    end 
    return Base.getfield(obj, var)
end