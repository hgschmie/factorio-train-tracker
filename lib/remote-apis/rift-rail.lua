--------------------------------------------------------------------------------
-- Rift Rail
--------------------------------------------------------------------------------

local Event = require('stdlib.event.event')

---@class RRTrainDepartingEvent
---@field train LuaTrain
---@field train_id integer
---@field source_teleporter LuaEntity
---@field source_teleporter_id integer
---@field source_surface LuaSurface
---@field source_surface_index integer

---@class RRTrainArrivedEvent
---@field train LuaTrain
---@field train_id integer
---@field old_train_id integer
---@field source_surface LuaSurface
---@field source_surface_index integer
---@field destination_teleporter LuaEntity
---@field destination_teleporter_id integer
---@field destination_surface LuaSurface
---@field destination_surface_index integer
---@field entry_unit_number integer
---@field exit_unit_number integer

-- Starts teleport operation by RiftRail.
--
-- Locks the old train info in place to prevent deletion.
-- Updates runtime and distance before entering the portal.
--
---@param event RRTrainDepartingEvent
local function rr_teleport_started(event)
    local train = event.train
    local train_info = This.TrainTracker:beginClone(train, event.train_id)
    if train_info then
        train_info.current_station = train_info.next_station
        This.TrainTracker:arrivalUpdate(train, train_info, game.tick - train_info.last_tick)
    end
end

-- Completes teleport operation by RiftRail.
--
-- Re-assigns the old train info to the rebuilt train entity at the exit portal.
-- Updates departure state and prepares distance tracking for the next path.
--
---@param event RRTrainArrivedEvent
local function rr_teleport_finished(event)
    local train = event.train
    local train_info = This.TrainTracker:commitClone(train, event.old_train_id)
    if not train_info then return end

    train_info.current_is_temporary = false
    This.TrainTracker:departureUpdate(train, train_info, game.tick - train_info.last_tick)
end

--- Suppresses tracking for temporary leader train entities.
---@param train LuaTrain?
local function blacklist_rift_rail_leader(train)
    if not (train and train.valid) then return true end
    if not (train.back_stock and train.back_stock.valid) then return false end
    if train.back_stock.type == 'locomotive' and train.back_stock.name == 'rift-rail-leader-train' then return true end
    return false
end

local function rr_init()
    if not remote.interfaces['RiftRail'] then return end

    assert(remote.interfaces['RiftRail']['get_train_departing_event'], 'RiftRail present but no get_train_departing_event interface')
    assert(remote.interfaces['RiftRail']['get_train_arrived_event'], 'RiftRail present but no get_train_arrived_event interface')

    Event.on_event(remote.call('RiftRail', 'get_train_departing_event'), rr_teleport_started)
    Event.on_event(remote.call('RiftRail', 'get_train_arrived_event'), rr_teleport_finished)

    This.TrainTracker:registerBlacklist(blacklist_rift_rail_leader)
end

local RiftRail = {
    on_init = rr_init,
    on_load = rr_init,
}

return RiftRail
