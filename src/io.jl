#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

mutable struct FMUEvaluationOutput{T} <: AbstractArray{Float64,1}
    dx::AbstractArray{T,1}
    y::AbstractArray{T,1}
    ec::AbstractArray{T,1}

    function FMUEvaluationOutput{T}(
        dx::AbstractArray,
        y::AbstractArray,
        ec::AbstractArray,
    ) where {T}
        return new{T}(dx, y, ec)
    end

    function FMUEvaluationOutput(
        dx::AbstractArray{T},
        y::AbstractArray{T},
        ec::AbstractArray{T},
    ) where {T}
        return FMUEvaluationOutput{T}(dx, y, ec)
    end

    function FMUEvaluationOutput{T}(; initType::DataType = T) where {T}
        return FMUEvaluationOutput{T}(
            Array{initType,1}(),
            Array{initType,1}(),
            Array{initType,1}(),
        )
    end

    function FMUEvaluationOutput()
        return FMUEvaluationOutput{fmi2Real}(EMPTY_fmi2Real, EMPTY_fmi2Real, EMPTY_fmi2Real)
    end
end

import ChainRulesCore: ZeroTangent, NoTangent

function Base.setproperty!(out::FMUEvaluationOutput, var::Symbol, value::ZeroTangent)
    return Base.setproperty!(out, var, EMPTY_fmi2Real)
end

function Base.setproperty!(out::FMUEvaluationOutput, var::Symbol, value::NoTangent)
    return Base.setproperty!(out, var, EMPTY_fmi2Real)
end

function Base.length(out::FMUEvaluationOutput)
    len_dx = length(out.dx)
    len_y = length(out.y)
    len_ec = length(out.ec)
    return len_dx + len_y + len_ec
end

function Base.getindex(out::FMUEvaluationOutput, ind::Int)
    @assert ind >= 1 "`getindex` for index $(ind) <= 0 not supported."

    len_dx = length(out.dx)
    if ind <= len_dx
        return out.dx[ind]
    end
    ind -= len_dx

    len_y = length(out.y)
    if ind <= len_y
        return out.y[ind]
    end
    ind -= len_y

    len_ec = length(out.ec)
    if ind <= len_ec
        return out.ec[ind]
    end
    ind -= len_ec

    @assert false "`getindex` for index $(ind+len_y+len_dx+len_ec) out of bounds [$(length(out))]."
end

function Base.getindex(out::FMUEvaluationOutput, ind::UnitRange)
    # [ToDo] Could be improved.
    return collect(Base.getindex(out, i) for i in ind)
end

function Base.setindex!(out::FMUEvaluationOutput, v, index::Int)

    @assert !isa(v, Int64) "setindex! on Int64 not allowed!"

    len_dx = length(out.dx)
    if index <= len_dx
        return setindex!(out.dx, v, index)
    end
    index -= len_dx

    len_y = length(out.y)
    if index <= len_y
        return setindex!(out.y, v, index)
    end
    index -= len_y

    len_ec = length(out.ec)
    if index <= len_ec
        return setindex!(out.ec, v, index)
    end
    index -= len_ec

    @assert false "`setindex!` for index $(ind+len_y+len_dx+len_ec) out of bounds [$(length(out))]."
end

function Base.size(out::FMUEvaluationOutput)
    return (length(out),)
end

function Base.IndexStyle(::FMUEvaluationOutput)
    return IndexLinear()
end

function Base.unaliascopy(out::FMUEvaluationOutput)
    return FMUEvaluationOutput(copy(out.dx), copy(out.y), copy(out.ec))
end

#####

mutable struct FMUADOutput{T} <: AbstractArray{Real,1}
    buffer::AbstractArray{<:T,1}

    len_dx::Int
    len_y::Int
    len_ec::Int

    show_dx::Bool
    show_y::Bool
    show_ec::Bool

    function FMUADOutput{T}(; initType::DataType = T) where {T}
        return new{T}(Array{initType,1}(), 0, 0, 0, true, true, false)
    end

    function FMUADOutput()
        return FMUADOutput{fmi2Real}()
    end
end

import ChainRulesCore: ZeroTangent, NoTangent

function Base.setproperty!(out::FMUADOutput, var::Symbol, value::ZeroTangent)
    return Base.setproperty!(out, var, EMPTY_fmi2Real)
end

function Base.setproperty!(out::FMUADOutput, var::Symbol, value::NoTangent)
    return Base.setproperty!(out, var, EMPTY_fmi2Real)
end

function Base.hasproperty(::FMUADOutput, var::Symbol)
    return var ∈ (:dx, :y, :ec, :buffer, :len_dx, :len_y, :len_ex, :ec_visible)
end

function Base.getproperty(out::FMUADOutput, var::Symbol)

    if var == :dx
        return @view(out.buffer[1:out.len_dx])
    elseif var == :y
        return @view(out.buffer[out.len_dx+1:out.len_dx+out.len_y])
    elseif var == :ec
        return @view(out.buffer[out.len_dx+out.len_y+1:end])
    else
        return Base.getfield(out, var)
    end
end

function Base.length(out::FMUADOutput)
    len_dx = out.show_dx ? out.len_dx : 0
    len_y = out.show_y ? out.len_y : 0
    len_ec = out.show_ec ? out.len_ec : 0
    return len_dx + len_y + len_ec
end

function Base.getindex(out::FMUADOutput, ind::Int)
    return getindex(out.buffer, ind)
end

function Base.getindex(out::FMUADOutput, ind::UnitRange)
    # [ToDo] Could be improved.
    return collect(Base.getindex(out, i) for i in ind)
end

function Base.setindex!(out::FMUADOutput, v, index::Int)
    return setindex!(out.buffer, v, index)
end

function Base.size(out::FMUADOutput)
    return (length(out),)
end

function Base.IndexStyle(::FMUADOutput)
    return IndexLinear()
end

function Base.unaliascopy(out::FMUADOutput)
    return FMUADOutput(
        copy(out.buffer),
        out.len_dx,
        out.len_y,
        out.len_ec,
        out.show_dx,
        out.show_y,
        out.show_ec,
    )
end

#####

mutable struct FMUEvaluationInput <: AbstractVector{Real}

    x::AbstractArray{<:Real}
    u::AbstractVector{<:Real}
    p::AbstractVector{<:Real}
    t::Real

    function FMUEvaluationInput(
        x::AbstractArray{<:Real},
        u::AbstractArray{<:Real},
        p::AbstractArray{<:Real},
        t::Real,
    )
        return new(x, u, p, t)
    end

    function FMUEvaluationInput()
        return FMUEvaluationInput(EMPTY_fmi2Real, EMPTY_fmi2Real, EMPTY_fmi2Real, 0.0)
    end
end
