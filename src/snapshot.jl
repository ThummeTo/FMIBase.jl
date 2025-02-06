 #
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

function getFMUstate!(c::FMUInstance, s::Ref{Nothing})
    return nothing
end

function setFMUstate!(c::FMUInstance, state::Nothing)
    return nothing
end

function freeFMUstate!(c::FMUInstance, state::Ref{Nothing})
    return nothing
end

function snapshot!(c::FMUInstance)
    s = FMUSnapshot(c)
    # is automatically pushed to instance within `FMUSnapshot`
    return s
end
function snapshot!(sol::FMUSolution)
    s = snapshot!(sol.instance)
    push!(sol.snapshots, s)
    return s
end
export snapshot!

function snapshotDeltaTimeTolerance(inst::FMUInstance)
    return inst.fmu.executionConfig.snapshotDeltaTimeTolerance
end
function snapshotDeltaTimeTolerance(sol::FMUSolution)
    return snapshotDeltaTimeTolerance(sol.instance)
end

function snapshot_if_needed!(
    obj::Union{FMUInstance,FMUSolution},
    t::Real;
    atol = snapshotDeltaTimeTolerance(obj),
)
    if !hasSnapshot(obj, t; atol = atol)
        snapshot!(obj)
    end
end
export snapshot_if_needed!

function hasSnapshot(c::Union{FMUInstance,FMUSolution}, t::Float64; atol = 0.0)
    for snapshot in c.snapshots
        if abs(snapshot.t - t) <= atol
            return true
        end
    end
    return false
end

function getSnapshot(c::Union{FMUInstance,FMUSolution}, t::Float64; exact::Bool = false, atol = 0.0)
    # [Note] only take exact fit if we are at 0, otherwise take the next left, 
    #        because we are saving snapshots for the right root of events.

    #@assert t ∉ (-Inf, Inf) "t = $(t), this is not allowed for snapshot search!"
    # if t == Inf 
    #     if length(c.snapshots) > 0
    #         @warn "t = $(t), this is not allowed for snapshot search!\nFallback to left-most snapshot!"
    #         left = snapshots[1]
    #         for snapshot in c.snapshots
    #             if snapshot.t < left.t
    #                 left = snapshot
    #             end
    #         end
    #         return left
    #     else
    #         @warn "t = $(t), this is not allowed for snapshot search!\nNo snapshots available, returning nothing!"
    #         return nothing 
    #     end
    # end

    if t ∈ (-Inf, Inf)
        @warn "t = $(t), this is not allowed for snapshot search! Returning nothing!"
        return nothing
    end

    @assert length(c.snapshots) > 0 "No snapshots available!"

    left = c.snapshots[1]
    # right = c.snapshots[1]

    if exact
        for snapshot in c.snapshots
            if abs(snapshot.t - t) <= atol
                return snapshot
            end
        end
        return nothing
    else
        for snapshot in c.snapshots
            if snapshot.t < (t - atol) && snapshot.t > (left.t + atol)
                left = snapshot
            end
            # if snapshot.t > t && snapshot.t < right.t
            #     right = snapshot
            # end
        end
    end

    return left
end
export getSnapshot

function update!(c::FMUInstance, s::FMUSnapshot)
    s.t = c.t
    s.eventInfo = deepcopy(c.eventInfo)
    s.state = c.state
    s.instance = c

    @debug "Updating snapshot t=$(s.t) [$(s.fmuState)]"

    getFMUstate!(c, Ref(s.fmuState))

    @debug "... to t=$(s.t) [$(s.fmuState)]"

    s.x_c = isnothing(c.x) ? nothing : copy(c.x)
    s.x_d = isnothing(c.x_d) ? nothing : copy(c.x_d)
    return nothing
end
export update!

function apply!(
    c::FMUInstance,
    s::FMUSnapshot;
    t = s.t,
    x_c = s.x_c,
    x_d = s.x_d,
    fmuState = s.fmuState,
)

    # FMU state
    setFMUstate!(c, fmuState)
    c.eventInfo = deepcopy(s.eventInfo)
    c.state = s.state

    @debug "Applied snapshot $(s.t)"

    # continuous state
    if !isnothing(x_c)
        setContinuousStates(c, x_c)
        c.x = copy(x_c)
    end

    # discrete state
    if !isnothing(x_d)
        setDiscreteStates(c, x_d)
        c.x_d = copy(x_d)
    end

    # time
    setTime(c, t)
    c.t = t

    return nothing
end
export apply!

function freeSnapshot!(s::FMUSnapshot)
    #@async println("cleanup!")
    @debug "Freeing snapshot t=$(s.t) [$(s.fmuState)]"

    freeFMUstate!(s.instance, Ref(s.fmuState))
    s.fmuState = nothing

    ind = findall(x -> x == s, s.instance.snapshots)
    @assert length(ind) == 1 "freeSnapshot!: Freeing $(length(ind)) snapshots with one call, this is not allowed. Target was found $(length(ind)) times at indices $(ind)."
    deleteat!(s.instance.snapshots, ind)

    return nothing
end
export freeSnapshot!
