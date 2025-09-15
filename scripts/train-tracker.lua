------------------------------------------------------------------------
-- Main train tracker
------------------------------------------------------------------------
assert(script)

local const = require('lib.constants')

-- load extended math lib
local math = require('stdlib.utils.math')

---@class tt.FreightItem
---@field type 'item'|'fluid'
---@field name string
---@field quality string?
---@field count integer

---@alias tt.Freight table<string, tt.FreightItem>

---@class tt.TrainInfo
---@field last_state defines.train_state?
---@field last_station LuaEntity?
---@field current_station LuaEntity?
---@field next_station (LuaEntity|string)?
---@field last_tick integer
---@field total_distance integer
---@field total_runtime integer
---@field total_waittime integer
---@field signal_waittime integer
---@field stop_waittime integer
---@field train_name string
---@field train_id integer
---@field current_freight tt.Freight?
---@field total_freight tt.Freight?

---@class tt.Storage
---@field trains table<integer, tt.TrainInfo>
---@field ships table<integer, tt.TrainInfo>

---@class tt.TrainTracker
---@field DEBUG_MODE boolean
local TrainTracker = {
    DEBUG_MODE = Framework.settings:startup_setting('debug_mode')
}

------------------------------------------------------------------------
-- helpers
------------------------------------------------------------------------

---@param station_name string the station name
---@param candidate_rails table<integer, boolean>
local function find_station(station_name, candidate_rails)
    local candidates = game.train_manager.get_train_stops {
        is_connected_to_rail = true,
        station_name = station_name
    }

    -- only one station exists, easy.
    if #candidates == 1 then return candidates[1] end

    -- that should never happen, but one never knows...
    if #candidates == 0 then return station_name end

    -- find the station where the rail is connected
    for _, station in pairs(candidates) do
        if station.connected_rail and candidate_rails[station.connected_rail.unit_number] then return station end
    end

    return station_name
end

---@param train LuaTrain
---@return (string|LuaEntity)? station
local function get_next_station(train)
    if not train.schedule then return nil end

    ---@type ScheduleRecord[]
    local records = train.schedule.records
    local index = train.schedule.current

    ---@type table<integer, boolean>
    local candidate_rails = {}

    if train.path_end_rail then candidate_rails[train.path_end_rail.unit_number] = true end

    if records[index].station and train.state ~= defines.train_state.wait_station then return find_station(records[index].station, candidate_rails) end

    local schedule_size = table_size(records)
    for i = 1, schedule_size - 1 do
        local rail = records[index].rail
        index = math.one_mod(index + 1, schedule_size)

        if records[index].station then
            if rail then candidate_rails[rail.unit_number] = true end
            return find_station(records[index].station, candidate_rails)
        end
    end

    return nil
end

---@param train LuaTrain
---@return tt.Freight
function TrainTracker:getFreightFromTrain(train)
    local freight = {}

    for _, item in pairs(train.get_contents()) do
        local quality = item.quality or 'normal'
        local freight_item = {
            type = 'item',
            name = item.name,
            quality = quality,
            count = item.count,
        }
        local key = const.getFreightSortKey(freight_item)
        freight[key] = freight_item
    end

    for k, v in pairs(train.get_fluid_contents()) do
        local freight_fluid = {
            type = 'fluid',
            name = k,
            count = v,
        }
        local key = const.getFreightSortKey(freight_fluid)
        freight[key] = freight_fluid
    end

    return freight
end

---@param train LuaTrain
---@return tt.TrainInfo
local function create_train_info(train)
    assert(train)

    script.register_on_object_destroyed(train)

    return {
        last_state = train and train.state,
        last_station = nil,
        current_station = train and train.station,
        next_station = train and get_next_station(train),
        last_tick = game.tick,
        total_distance = 0,
        total_runtime = 0,
        total_waittime = 0,
        stop_waittime = 0,
        signal_waittime = 0,
        train_name = const.getTrainName(train),
        train_id = train.id,
        total_freight = {},
    }
end

---@param train LuaTrain
---@return string entity_type
function TrainTracker:determineEntityType(train)
    if const.has_ships then
        local loco = const.getMainLocomotive(train)
        if loco and const.ship_names[loco.name] then return const.entity_types.ships end
    end
    return const.entity_types.trains
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
---@param train_id integer?
function TrainTracker:clearEntity(entity_type, train_id)
    if not train_id then return end
    self:entities(entity_type)[train_id] = nil
end

---@param train_id integer
function TrainTracker:destroyEntity(train_id)
    for _, entity_type in pairs(const.entity_types) do
        self:entities(entity_type)[train_id] = nil
    end
end

------------------------------------------------------------------------
-- event callbacks
------------------------------------------------------------------------

-- Called when the current state is defines.train_state.wait_station
---@param train LuaTrain
---@param event_tick integer
---@return tt.TrainInfo?
function TrainTracker:processStationArrival(train, event_tick)
    local entity_type = self:determineEntityType(train)
    if not entity_type then return nil end -- trains without engines are ignored

    local train_info = self:getOrCreateEntity(entity_type, train)

    -- last tick holds the time of the last runtime update
    train_info.total_runtime = train_info.total_runtime + (event_tick - train_info.last_tick)
    if train.station and train.station.valid then train_info.current_station = train.station end

    if self.DEBUG_MODE then
        game.print(('[font=debug-mono][train-tracker][Station Arrival]  [/font]Train Id: %d, Station Name: %s'):format(
            train.id, const.getStationName(train_info.current_station)), { sound = defines.print_sound.never })
    end

    train_info.next_station = get_next_station(train)
    train_info.current_freight = self:getFreightFromTrain(train)
    return train_info
end

-- Arriving at a signal. Just update the train_info state
---@param train LuaTrain
---@param event_tick integer
---@return tt.TrainInfo?
function TrainTracker:processSignalArrival(train, event_tick)
    local entity_type = self:determineEntityType(train)
    if not entity_type then return nil end -- trains without engines are ignored

    local train_info = self:getOrCreateEntity(entity_type, train)

    -- update the total runtime as the last_tick will be overwritten
    train_info.total_runtime = train_info.total_runtime + (event_tick - train_info.last_tick)
    return train_info
end

-- Called when the old state was wait_signal. We just left a signal
---@param train LuaTrain
---@param event_tick integer
---@return tt.TrainInfo?
function TrainTracker:processSignalDeparture(train, event_tick)
    local entity_type = self:determineEntityType(train)
    if not entity_type then return nil end -- trains without engines are ignored

    local train_info = self:getOrCreateEntity(entity_type, train)

    local wait_time = (event_tick - train_info.last_tick)
    train_info.total_waittime = train_info.total_waittime + wait_time
    train_info.signal_waittime = (train_info.signal_waittime or 0) + wait_time

    return train_info
end

-- Called when the old state was wait_station. We just left a station
---@param train LuaTrain
---@param event_tick integer
---@return tt.TrainInfo?
function TrainTracker:processStationDeparture(train, event_tick)
    local entity_type = self:determineEntityType(train)
    if not entity_type then return nil end -- trains without engines are ignored

    local train_info = self:getOrCreateEntity(entity_type, train)

    local wait_time = (event_tick - train_info.last_tick)
    train_info.total_waittime = train_info.total_waittime + wait_time
    train_info.stop_waittime = (train_info.stop_waittime or 0) + wait_time

    train_info.last_station = train_info.current_station
    train_info.current_station = nil
    train_info.next_station = get_next_station(train)

    local old_freight = train_info.current_freight
    if old_freight and table_size(old_freight) > 0 then
        -- calculate diff between old and new. diff is total freight transported
        local new_freight = self:getFreightFromTrain(train)
        for k, v in pairs(old_freight) do
            local diff = new_freight[k] and (v.count - new_freight[k].count) or v.count
            if diff > 0 then
                if train_info.total_freight[k] then
                    train_info.total_freight[k].count = train_info.total_freight[k].count + diff
                else
                    train_info.total_freight[k] = v
                    train_info.total_freight[k].count = diff
                end
            end
        end
    end
    train_info.current_freight = self:getFreightFromTrain(train)

    return train_info
end

------------------------------------------------------------------------

return TrainTracker
