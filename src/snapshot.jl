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
    for snapshot in c.snapshots 
        # reuse existing allocated snapshot
        if !snapshot.valid
            update!(c, snapshot)
            return snapshot
        end
    end 

    #@assert length(c.snapshots) < c.fmu.executionConfig.max_snapshots "Reached max snapshots ($(c.fmu.executionConfig.max_snapshots)) for lazy unloading, if needed increase value for `fmu.executionConfig.max_snapshots`."
    if length(c.snapshots) > c.fmu.executionConfig.max_snapshots
        @warn "Exceeded max snapshots $(length(c.snapshots)) > $(c.fmu.executionConfig.max_snapshots) for lazy unloading at t=$(c.t)."
    end

    snapshot = FMUSnapshot(c)
    # is automatically pushed to instance within `FMUSnapshot`
    return snapshot
end
# function snapshot!(sol::FMUSolution)
#     s = snapshot!(sol.instance)
#     push!(sol.snapshots, s)
#     return s
# end
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

function snapshot_or_update!(
    obj::Union{FMUInstance,FMUSolution},
    t::Real;
    atol = snapshotDeltaTimeTolerance(obj),
)
    sn = getSnapshot(obj, t; atol = atol)

    if isnothing(sn)
        sn = snapshot!(obj)
    else
        update!(obj, sn)
    end
    
    return sn
end
export snapshot_or_update!

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
    Searches the snapshot for given `t` within the component `c`. Tolerance is `atol`. 
    If no snapshot is found, `nothing` is returned.
"""
function getSnapshot(
    c::Union{FMUInstance,FMUSolution},
    t::Float64;
    atol = snapshotDeltaTimeTolerance(c)
)
    if length(c.snapshots) <= 0
        return nothing
    end

    if t ∈ (-Inf, Inf)
        @warn "t = $(t), this is not allowed for snapshot search! Returning nothing!"
        return nothing
    end

    for snapshot in c.snapshots
        if snapshot.valid
            #if snapshot.t.index == index
                if abs(snapshot.t - t) <= atol
                    return snapshot
                end
            #end
        end
    end

    return nothing
end
export getSnapshot

function getSnapshotForDiscreteState(
    c::Union{FMUInstance,FMUSolution},
    x_d::Vector
)
    if length(c.snapshots) <= 0
        return nothing
    end

    for i in 1:length(c.snapshots)
        snapshot = c.snapshots[i]
        if snapshot.valid
            if snapshot.x_d == x_d
                return snapshot
            end
        end
    end

    return nothing
end
export getSnapshotForDiscreteState

"""
    Searches the snapshot left from a given `t` within the component `c`.
    This excludes fitting snapshots within `atol`.
    If no snapshot is found, `nothing` is returned.
"""
# function getPreviousSnapshot(
#     c::Union{FMUInstance,FMUSolution},
#     t::Float64;
#     atol = snapshotDeltaTimeTolerance(c),
#     index::Integer=0
# )
#     if length(c.snapshots) <= 0
#         return nothing
#     end

#     if t == -Inf
#         @warn "t = $(t), this is not allowed for snapshot search! Returning nothing!"
#         return nothing
#     end

#     if t == Inf
#         @warn "t = $(t), returning max snapshot!"
#         max_snapshot = c.snapshots[1]
#         for snapshot in c.snapshots
#             #if snapshot.t.index == index
#                 if snapshot.t > max_snapshot.t
#                     max_snapshot = snapshot
#                 end
#             #end
#         end
#         return max_snapshot
#     end

#     left = nothing

#     for snapshot in c.snapshots

#         # it's required to NOT be a perfect match
#         if isapprox(snapshot.t, t, index; atol=atol)
            
#             # only if we are really left
#             if snapshot.t.t < t 
                
#                 # if we didn't find something until now or
#                 # or we find a closer left snapshot
#                 if isnothing(left) || abs(snapshot.t.t - t) < abs(left.t.t - t)
#                     left = snapshot
#                 end
#             end
#         end
#     end

#     return left
# end
# export getPreviousSnapshot

# function getSnapshotOrPrevious(c::Union{FMUInstance,FMUSolution},
#     t::Float64;
#     atol = snapshotDeltaTimeTolerance(c),
#     index::Integer=0
# )
#     sn = getSnapshot(c, t; atol=atol, index=index)
#     if isnothing(sn)
#         sn = getPreviousSnapshot(c, t; atol=atol, index=index)
#     end
#     return sn
# end
# export getSnapshotOrPrevious

function update!(c::FMUInstance, s::FMUSnapshot; suppressWarning::Bool=false)

    @debug "Updating snapshot t=$(s.t) [$(s.fmuState)]"

    if s.valid
        if c != s.instance 
            if !suppressWarning
                @warn "Snapshot is updated to snapshot of other instant $(c.addr) != $(s.instance.addr).\nThis might fail depending on the FMU implementation."
            end
        end
    end

    if s.valid
        if s.t != c.t
            if !suppressWarning
                @warn "Updating snapshot with time $(s.t) (default_t=$(s.default_t)) to a snapshot with different time $(c.t) (default_t=$(c.default_t)).\nIf this is intended, use keyword `suppressWarning=true`."
            end
        end
    end

    # in case the snapshot was invalid
    s.valid = true

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

function autoApply!(c::FMUInstance, t::Real; atol = snapshotDeltaTimeTolerance(c))
    left = nothing
    for snapshot in c.snapshots
        if snapshot.valid 
            if snapshot.t <= t
                if isnothing(left) || snapshot.t > left.t
                    left = snapshot
                end
            end
        end
    end

    @assert !isnothing(left) "!!!"
    return apply!(c, left)
end
export autoApply!

function apply!(
    c::FMUInstance,
    s::FMUSnapshot;
    t = s.t,
    default_t = s.default_t,
    x_c = s.x_c,
    x_d = s.x_d,
    fmuState = s.fmuState,
)

    @assert s.valid "Try to apply invalid snapshot!"

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

function freeSnapshot!(s::FMUSnapshot; lazy::Bool=true)

    # We use lazy unloading here, because some FMUs are not compatible with excessive creation/freeing of snapshots (memory leaks).
    # That's why we just invalidate the memory copy here, and re-use it later if new snapshots are needed.
    if lazy 
        @assert s.valid "Trying to (lazy) free an already invald snapshot at $(s.t)."

        s.valid = false 
        return nothing 
    end

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
    # if isnothing(c.sampleSnapshot)
    #     # Info: snapshot! stores this snapshot in a vector, so all (including this) snapshot are release when calling fmi2FreeInstance.
    #     c.sampleSnapshot = snapshot!(c)
    # else
    #     update!(c, c.sampleSnapshot; suppressWarning=true)
    # end
    # return c.sampleSnapshot

    # with lazy unloading we can just "allocate"
    @assert isnothing(c.sampleSnapshot) "Sampling already running, called `startSampling` two times ..."
    c.sampleSnapshot = snapshot!(c)
    return c.sampleSnapshot
end

function stopSampling(c::FMUInstance)
    @assert !isnothing(c.sampleSnapshot) "`stopSampling` called BEFORE `startSampling`, this is not allowed."
    # return apply!(c, c.sampleSnapshot)

    # with lazy unloading we can just "free"
    freeSnapshot!(c.sampleSnapshot)
    c.sampleSnapshot = nothing
    return nothing
end
