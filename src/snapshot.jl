#
# Copyright (c) 2024 Tobias Thummerer, Lars Mikelsons
# Licensed under the MIT license. See LICENSE file in the project root for details.
#

function getFMUState!(c::FMUInstance, s::Ref{Nothing})
    return nothing
end

function setFMUState!(c::FMUInstance, state::Nothing)
    return nothing
end

function freeFMUState!(c::FMUInstance, state::Ref{Nothing})
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

"""
    Does a snapshot if there is no snapshot available for `t` (with tolerance `atol`).
"""
function snapshot_if_needed!(
    obj::Union{FMUInstance,FMUSolution},
    t::Real;
    atol = snapshotDeltaTimeTolerance(obj),
)
    sn = getSnapshot(obj, t; atol = atol)

    if !isnothing(sn)
        return sn 
    end
    
    return snapshot!(obj)
end
export snapshot_if_needed!

"""
    Checks for a snapshot available for `t` (with tolerance `atol`).
"""
function hasSnapshot(c::Union{FMUInstance,FMUSolution}, t::Float64; atol = snapshotDeltaTimeTolerance(obj))
    for snapshot in c.snapshots
        if abs(snapshot.t - t) <= atol
            return true
        end
    end
    return false
end

"""
    Searches the closest snapshot for given `t` within the component `c`. If no snapshot is found, `nothing` is returned.
"""
function getSnapshot(
    c::Union{FMUInstance,FMUSolution},
    t::Float64;
    atol = snapshotDeltaTimeTolerance(c),
)
    if length(c.snapshots) <= 0
        return nothing
    end

    if t ∈ (-Inf, Inf)
        @warn "t = $(t), this is not allowed for snapshot search! Returning nothing!"
        return nothing
    end

    for snapshot in c.snapshots
        if abs(snapshot.t - t) <= atol
            return snapshot
        end
    end

    return nothing
end
export getSnapshot

function getPreviousSnapshot(
    c::Union{FMUInstance,FMUSolution},
    t::Float64;
    atol = snapshotDeltaTimeTolerance(c),
)
    if length(c.snapshots) <= 0
        return nothing
    end

    if t == -Inf
        @warn "t = $(t), this is not allowed for snapshot search! Returning nothing!"
        return nothing
    end

    if t == Inf
        @warn "t = $(t), returning max snapshot!"
        max_snapshot = c.snapshots[1]
        for snapshot in c.snapshots
            if snapshot.t > max_snapshot.t
                max_snapshot = snapshot
            end
        end
        return max_snapshot
    end

    left = nothing

    for snapshot in c.snapshots

        # it's required to NOT be a perfect match
        if abs(snapshot.t - t) > atol

            # only if we are really left
            if snapshot.t < t 
                
                # if we didn't find something until now or
                # or we find a closer left snapshot
                if isnothing(left) || abs(t-snapshot.t) < abs(t-left.t)
                    left = snapshot
                end
            end
        end
    end

    return left
end
export getPreviousSnapshot

function update!(c::FMUInstance, s::FMUSnapshot; suppressWarning::Bool=false)

    @debug "Updating snapshot t=$(s.t) [$(s.fmuState)]"

    if c != s.instance 
        if !suppressWarning
            @warn "Snapshot is updated to snapshot of other instant $(c.address) != $(s.instance.address).\nThis might fail depending on the FMU implementation."
        end
    end

    if s.t != c.t 
        if !suppressWarning
            @warn "Updating snapshot with time $(s.t) (default_t=$(s.default_t)) to a snapshot with different time $(c.t) (default_t=$(c.default_t)).\nIf this is intended, use keyword `suppressWarning=true`."
        end
    end

    s.t = c.t
    s.default_t = c.default_t
    s.eventInfo = getEventInfo(c)
    s.state = c.state
    s.instance = c
    getFMUState!(c, Ref(s.fmuState))

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
    default_t = s.default_t,
    x_c = s.x_c,
    x_d = s.x_d,
    fmuState = s.fmuState,
)

    if c != s.instance 
        @warn "Snapshot is applied to snapshot of other instant $(c.address) != $(s.instance.address).\nThis might fail depending on the FMU implementation."
    end

    @debug "Applied snapshot $(s.t) @ $(c.t)"

    # FMU state
    setFMUState!(c, fmuState)
    setEventInfo!(c, s.eventInfo)
    c.state = s.state
    
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
    c.default_t = default_t

    return nothing
end
export apply!

function freeSnapshot!(s::FMUSnapshot)
    #@async println("cleanup!")
    @debug "Freeing snapshot t=$(s.t) [$(s.fmuState)]"

    freeFMUState!(s.instance, Ref(s.fmuState))
    s.fmuState = nothing

    ind = findall(x -> x == s, s.instance.snapshots)
    @assert length(ind) == 1 "freeSnapshot!: Freeing $(length(ind)) snapshots with one call, this is not allowed.\nTarget was found $(length(ind)) times at indices $(ind)."
    deleteat!(s.instance.snapshots, ind)

    return nothing
end
export freeSnapshot!

function startSampling(c::FMUInstance)
    if isnothing(c.sampleSnapshot)
        # Info: snapshot! stores this snapshot in a vector, so all (including this) snapshot are release when calling fmi2FreeInstance.
        c.sampleSnapshot = snapshot!(c)
    else
        update!(c, c.sampleSnapshot; suppressWarning=true)
    end
    return c.sampleSnapshot
end

function stopSampling(c::FMUInstance)
    @assert !isnothing(c.sampleSnapshot) "`stopSampling` called BEFORE `startSampling`, this is not allowed."
    return apply!(c, c.sampleSnapshot)
end
