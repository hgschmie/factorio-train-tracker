------------------------------------------------------------------------
-- Main train tracker
------------------------------------------------------------------------
assert(script)

local const = require('lib.constants')


---@class tt.TrainInfo
---@field last_state defines.train_state?
---@field last_station LuaEntity?
---@field last_tick integer
---@field total_distance integer
---@field total_runtime integer
---@field total_waittime integer
---@field signal_waittime integer
---@field stop_waittime integer
---@field train_name string
---@field train_id integer

---@class tt.Storage
---@field trains table<integer, tt.TrainInfo>
---@field ships table<integer, tt.TrainInfo>

---@class tt.TrainTracker
---@field has_ships boolean
local TrainTracker = {
    has_ships = script.active_mods['cargo-ships'] and true or false,
}

------------------------------------------------------------------------
-- helpers
------------------------------------------------------------------------

---@param train LuaTrain
---@return LuaEntity? locomotive
function TrainTracker.getMainLocomotive(train)
    if not train.valid then return nil end
    return train.locomotives.front_movers and train.locomotives.front_movers[1] or train.locomotives.back_movers[1]
end

---@param train LuaTrain
---@return string? name
local function get_train_name(train)
    local loco = TrainTracker.getMainLocomotive(train)
    return loco and loco.backer_name or nil
end

---@param train LuaTrain
---@return tt.TrainInfo
local function create_train_info(train)
    assert(train)

    return {
        last_state = train and train.state,
        last_station = train and train.station,
        last_tick = game.tick,
        total_distance = 0,
        total_runtime = 0,
        total_waittime = 0,
        stop_waittime = 0,
        signal_waittime = 0,
        train_name = get_train_name(train),
        train_id = train.id
    }
end

---@param train LuaTrain
---@return string? entity_type
function TrainTracker:determineEntityType(train)
    if not self.has_ships then return 'trains' end
    local loco = self.getMainLocomotive(train)
    if not loco then return nil end
    if const.ship_names[loco.name] then return 'ships' end
    return 'trains'
end

------------------------------------------------------------------------
-- init setup
------------------------------------------------------------------------

--- Setup the global data structures
function TrainTracker:init()
    -- init data
    if not storage.tt_data then
        ---@type tt.Storage
        storage.tt_data = {
            trains = {},
            ships = {},
        }
    end
end

function TrainTracker:resync()
    -- load current train set
    local known_entities = {}
    local trains = game.train_manager.get_trains {}

    for _, train in pairs(trains) do
        local entity_type = self:determineEntityType(train)
        if entity_type then
            self:getOrCreateEntity(entity_type, train)
            known_entities[train.id] = entity_type
        end
    end

    for _, entity_type in pairs(const.entity_types) do
        for train_id in pairs(self:entities(entity_type)) do
            if known_entities[train_id] ~= entity_type then self:clearEntity(entity_type, train_id) end
        end
    end
end

------------------------------------------------------------------------
-- attribute getters/setters
------------------------------------------------------------------------

---@param entity_type string
---@return table<integer, tt.TrainInfo>
function TrainTracker:entities(entity_type)
    storage.tt_data[entity_type] = storage.tt_data[entity_type] or {}
    return assert(storage.tt_data[entity_type])
end

---@param entity_type string
---@param train_id integer
---@return tt.TrainInfo? Train information
function TrainTracker:getEntity(entity_type, train_id)
    return self:entities(entity_type)[train_id]
end

---@param entity_type string
---@param train LuaTrain
---@return tt.TrainInfo Train information
function TrainTracker:getOrCreateEntity(entity_type, train)
    local entities = self:entities(entity_type)
    if not entities[train.id] then entities[train.id] = create_train_info(train) end
    return entities[train.id]
end

---@param entity_type string
---@param train_id integer
---@param train_info tt.TrainInfo
function TrainTracker:setEntity(entity_type, train_id, train_info)
    self:entities(entity_type)[train_id] = assert(train_info)
end

---@param entity_type string
---@param train_id integer
function TrainTracker:clearEntity(entity_type, train_id)
    self:entities(entity_type)[train_id] = nil
end

------------------------------------------------------------------------
-- event callbacks
------------------------------------------------------------------------

---@param train LuaTrain
---@param old_state defines.train_state
---@param event_tick integer
function TrainTracker:trainArrived(train, old_state, event_tick)
    local entity_type = self:determineEntityType(train)
    if not entity_type then return end -- trains without engines are ignored

    local train_info = self:getOrCreateEntity(entity_type, train)

    if old_state == defines.train_state.arrive_station then -- "arrive at station" -> "wait at station"
        train_info.total_runtime = train_info.total_runtime + (event_tick - train_info.last_tick)

        if train_info.last_station and train_info.last_station.valid and train_info.last_station.connected_rail
            and train.station and train.station.valid and train.station.connected_rail then
            local path_result = game.train_manager.request_train_path {
                starts = {
                    {
                        rail = train_info.last_station.connected_rail,
                        direction = defines.rail_direction.front,
                    },
                    {
                        rail = train_info.last_station.connected_rail,
                        direction = defines.rail_direction.back,
                    },
                },
                goals = { train.station },
            }

            if path_result.found_path then
                train_info.total_distance = train_info.total_distance + path_result.total_length
            end
        end

        train_info.last_station = train.station
    elseif old_state == defines.train_state.arrive_signal then -- "arrive at signal" -> "wait at signal"
        train_info.total_runtime = train_info.total_runtime + (event_tick - train_info.last_tick)
    else
        return
    end

    train_info.last_state = train.state
    train_info.last_tick = event_tick
    train_info.train_name = get_train_name(train)
    train_info.train_id = train.id
end

---@param train LuaTrain
---@param old_state defines.train_state
---@param event_tick integer
function TrainTracker:trainDeparted(train, old_state, event_tick)
    local entity_type = self:determineEntityType(train)
    if not entity_type then return end -- trains without engines are ignored
    local train_info = self:getOrCreateEntity(entity_type, train)

    if old_state == defines.train_state.wait_station then -- "wait station" -> "on the path"
        if train_info.last_state == defines.train_state.wait_station then
            local wait_time = (event_tick - train_info.last_tick)
            train_info.total_waittime = train_info.total_waittime + wait_time
            train_info.stop_waittime = (train_info.stop_waittime or 0) + wait_time
        end
    elseif old_state == defines.train_state.wait_signal then -- "wait signal" -> "on the path"
        if train_info.last_state == defines.train_state.wait_signal then
            local wait_time = (event_tick - train_info.last_tick)
            train_info.total_waittime = train_info.total_waittime + wait_time
            train_info.signal_waittime = (train_info.signal_waittime or 0) + wait_time
        end
    else
        return
    end

    train_info.last_state = train.state
    train_info.last_tick = event_tick
    train_info.train_name = get_train_name(train)
    train_info.train_id = train.id
end

------------------------------------------------------------------------

return TrainTracker
