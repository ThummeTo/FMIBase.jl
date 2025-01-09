#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

module ForwardDiffExt

using FMIBase, ForwardDiff

# check if scalar/vector is ForwardDiff.Dual
function FMIBase.isdual(e::ForwardDiff.Dual{T,V,N}) where {T,V,N}
    return true
end
function FMIBase.isdual(e::AbstractVector{<:ForwardDiff.Dual{T,V,N}}) where {T,V,N}
    return true
end

# makes Reals from ForwardDiff.Dual scalar/vector
function FMIBase.undual(e::ForwardDiff.Dual)
    return ForwardDiff.value(e)
end

# makes Reals from ForwardDiff scalar/vector
function FMIBase.unsense(e::ForwardDiff.Dual)
    return ForwardDiff.value(e)
end

# set sensitive primitives (this is intentionally NO additional dispatch for `setindex!`) 
function FMIBase.sense_setindex!(A::Vector{Float64}, x::ForwardDiff.Dual, i::Int64)
    return setindex!(A, undual(x), i)
end

end # ForwardDiffExt
