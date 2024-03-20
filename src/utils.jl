#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

# checks if integrator has NaNs (that is not good...)
function assert_integrator_valid(integrator)
    @assert !isnan(integrator.opts.internalnorm(integrator.u, integrator.t)) "NaN in `integrator.u` @ $(integrator.t)."
end

# copy only if field can't be overwritten
function fast_copy!(str, dst::Symbol, src)
    @assert false "fast_copy! not implemented for src of type $(typeof(src))"
end
function fast_copy!(str, dst::Symbol, src::Nothing)
    setfield!(str, dst, nothing)
end
function fast_copy!(str, dst::Symbol, src::AbstractArray)
    tmp = getfield(str, dst)
    if isnothing(tmp) || length(tmp) != length(src)
        setfield!(str, dst, copy(src))
    else
        tmp[:] = src
    end
end