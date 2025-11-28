--------------------------------------------------------------------------------
-- Space Exploration
--------------------------------------------------------------------------------

local SpaceExploration = {}
--------------------------------------------------------------------------------

---@class SETeleportStartedEvent
---@field train LuaTrain
---@field old_train_id_1 integer
---@field old_surface_index integer
---@field teleported LuaEntity

---@class SETeleportFinishedEvent
---@field train LuaTrain
---@field old_train_id_1 integer
---@field old_surface_index integer
---@field teleported LuaEntity

-- Starts space elevator teleport operation.
--
-- Starts train renaming, locking the old train info in place
-- Sets the current station as the space elevator
-- Processes station arrival at the space elevator station
--
---@param event SETeleportStartedEvent
local function se_teleport_started(event)
    local train = event.train
    local train_info = This.TrainTracker:startRename(train, event.old_train_id_1, false)
    if train_info then
        -- reached the space elevator station
        train_info.current_station = train_info.next_station

        This.TrainTracker:arrivalUpdate(train, train_info, game.tick - train_info.last_tick)
    end
end

-- Wraps up the teleporting by the space elevator.
--
-- Ends the rename operation, assigning the old train info to the final new train
-- Records the departure from the space elevator target station
--
---@param event SETeleportFinishedEvent
local function se_teleport_finished(event)
    local train = event.train
    local train_info = This.TrainTracker:endRename(train, event.old_train_id_1, true)
    if not train_info then return end

    -- update the train state
    train_info.current_is_temporary = false

    This.TrainTracker:departureUpdate(train, train_info, game.tick - train_info.last_tick)
end

---@param train LuaTrain?
local function blacklist_se_tug(train)
    if not (train and train.valid) then return true end
    if not (train.back_stock and train.back_stock.valid) then return false end
    if train.back_stock.type == 'locomotive' and train.back_stock.name == 'se-space-elevator-tug' then return true end
    return false
end

SpaceExploration.runtime = function()
    assert(script)

    local Event = require('stdlib.event.event')

    local se_init = function()
        if not remote.interfaces['space-exploration'] then return end

        assert(remote.interfaces['space-exploration']['get_on_train_teleport_started_event'], 'LTN present but no on_delivery_failed event')
        assert(remote.interfaces['space-exploration']['get_on_train_teleport_finished_event'], 'LTN present but no on_delivery_failed event')

        Event.on_event(remote.call('space-exploration', 'get_on_train_teleport_started_event'), se_teleport_started)
        Event.on_event(remote.call('space-exploration', 'get_on_train_teleport_finished_event'), se_teleport_finished)
    end

    Event.on_init(se_init)
    Event.on_load(se_init)

    This.TrainTracker:registerBlacklist(blacklist_se_tug)
end

return SpaceExploration
