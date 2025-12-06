--------------------------------------------------------------------------------
-- event setup for the mod
--------------------------------------------------------------------------------
assert(script)

local Event = require('stdlib.event.event')
local Player = require('stdlib.event.player')

local const = require('lib.constants')

--------------------------------------------------------------------------------
-- event code
--------------------------------------------------------------------------------

local TICK_RATE = 31

local last_change_state = 0

---@param event EventData.on_train_changed_state
local function on_train_changed_state(event)
    local train = event and event.train
    if not train then return end

    -- only run for a single train ever
    if This.TrainTracker.DEBUG_TRAIN_ID then
        This.TrainTracker:debugPrint(train, 'Event Change', function()
            if last_change_state == 0 then last_change = event.tick end

            return ('Train now %s, Time in old state %s: %s'):format(
                const.state_names[train.state],
                const.state_names[event.old_state],
                const.formatTime(event.tick - last_change_state))
        end)

        This.TrainTracker:debugPrint(train, 'Event Info', function()
            last_change_state = event.tick

            if train.station then
                return ('Station: %s, Path Length: %s, Path Travelled: %s'):format(
                    const.getStationName(train.station, '<unknown>'),
                    train.path and const.formatDistance(train.path.total_distance) or '-',
                    train.path and const.formatDistance(train.path.travelled_distance) or '-')
            else
                return ('Temporary Stop: %s'):format(train.path_end_rail and train.path_end_rail.gps_tag or '<unknown>')
            end
        end)
    end

    local train_info = This.TrainTracker:findEntity(train)
    if not train_info then return end

    -- time spent in event.old_state
    local current_interval = event.tick - train_info.last_tick

    local update_train_info = function()
        train_info.last_state = train.state
        train_info.train_name = const.getTrainName(train)
        train_info.train_id = train.id

        -- only change the last tick when the state changes
        if train_info.last_tick_state == train.state then return false end

        local old_state = train_info.last_tick_state

        train_info.last_tick_state = train.state
        train_info.last_tick = event.tick

        This.TrainTracker:debugPrint(train, 'Train Info Change', function()
            return ('New State: %s, Record time for state %s: %s'):format(
                const.state_names[train_info.last_tick_state],
                old_state and const.state_names[old_state] or '<unknown>',
                const.formatTime(current_interval))
        end)

        return true
    end

    local process_old_state = function()
        if event.old_state == defines.train_state.wait_station then
            -- station departure
            return This.TrainTracker:processStationDeparture(train, train_info, current_interval)
        elseif event.old_state == defines.train_state.wait_signal then
            -- signal departure
            return This.TrainTracker:processSignalDeparture(train, train_info, current_interval)
        end
        return false
    end

    if process_old_state() then
        This.TrainTracker:debugPrint(train, 'Old State', function() return 'Old State processed!' end)
        if not update_train_info() then return end
        current_interval = event.tick - train_info.last_tick
    end

    local process_train_state = function()
        if train.state == defines.train_state.on_the_path then
            -- if train was in an invalid state (e.g. no_path), recompute path length
            if train_info.current_distance == 0
                and (train.path and train.path.valid) then
                train_info.current_distance = (train_info.current_distance or 0) + train.path.total_distance
            end
        elseif train.state == defines.train_state.wait_station then
            -- station arrival. Housekeep all the run information
            return This.TrainTracker:processStationArrival(train, train_info, current_interval)
        elseif train.state == defines.train_state.wait_signal then
            -- signal arrival
            return This.TrainTracker:processSignalArrival(train, train_info, current_interval)
        end
        return false
    end

    if process_train_state() then
        This.TrainTracker:debugPrint(train, 'Train State', function() return 'Train State processed!' end)

        if not update_train_info() then return end
    end
end

---@param event EventData.on_train_created
local function on_train_created(event)
    if not (event.train and event.train.valid) then return end

    This.TrainTracker:findEntity(event.train)
end

---@param event EventData.on_object_destroyed
local function on_object_destroyed(event)
    if event.type ~= defines.target_type.train then return end
    This.TrainTracker:destroyEntity(event.useful_id)
end

--------------------------------------------------------------------------------
-- translations
--------------------------------------------------------------------------------

---@param player LuaPlayer
local function register_translations(player)
    local keys = {}

    for _, entity_type in pairs(const.entity_types) do
        for i = 0, 9 do
            table.insert(keys, const:locale(const.trainStateKey(i, entity_type)))
        end
    end

    Framework.translation_manager:registerTranslation(player, keys)
end

--------------------------------------------------------------------------------
-- Configuration changes (startup)
--------------------------------------------------------------------------------

local function on_configuration_changed()
    This.TrainTracker:init()
    This.TrainTracker:resync()

    for player_index, player in pairs(game.players) do
        This.Gui.closeGui(player)

        ---@type tt.PlayerStorage?
        local player_data = Player.pdata(player_index)
        if player_data then
            player_data.tab_state = nil
            player_data.tab = nil
        end
    end
end

---@params event EventData.on_player_joined
local function on_player_joined(event)
    local player = Player.get(event.player_index)
    if not player then return end

    register_translations(player)
end

local function on_singleplayer_init()
    for _, player in pairs(game.players) do
        register_translations(player)
    end
end

--------------------------------------------------------------------------------
-- Event ticker
--------------------------------------------------------------------------------

---@return tt.Ticker
local function get_ticker()
    storage.ticker = storage.ticker or {}
    return storage.ticker
end

---@param ticker tt.Ticker
---@return string next entity type to process
local function next_entity(ticker)
    ticker.entity_type = next(const.entity_types, ticker.entity_type) or next(const.entity_types)
    return ticker.entity_type
end

local function onTick()
    local ticker = get_ticker()

    local entity_type = ticker.entity_type or next_entity(ticker)
    local entities = This.TrainTracker:entities(entity_type)
    local process_count = math.ceil((table_size(entities) * TICK_RATE) / 60)
    local index = ticker.last_tick_index

    -- if the train that the index points to has been removed in the meantime, reset the index
    if index and not entities[index] then index = nil end

    if process_count > 0 then
        ---@type tt.TrainInfo
        local train_info
        repeat
            index, train_info = next(entities, index)
            if train_info then
                local train = game.train_manager.get_train_by_id(train_info.train_id)
                if train and train.valid then
                    train_info.train_name = const.getTrainName(train)
                    if train.station then train_info.current_station = train.station end
                    train_info.last_state = train.state
                else
                    This.TrainTracker:clearEntity(entity_type, train_info.train_id)
                end
                process_count = process_count - 1
            end
        until process_count == 0 or not index
    else
        index = nil
    end

    if not index then next_entity(ticker) end
    ticker.last_tick_index = index
end

--------------------------------------------------------------------------------
-- event registration and management
--------------------------------------------------------------------------------

local function register_events()
    -- Configuration changes (startup)
    Event.on_configuration_changed(on_configuration_changed)
    Event.register(defines.events.on_singleplayer_init, on_singleplayer_init)
    Event.register(defines.events.on_player_joined_game, on_player_joined)

    Event.register(defines.events.on_train_changed_state, on_train_changed_state)
    Event.register(defines.events.on_train_created, on_train_created)
    Event.register(defines.events.on_object_destroyed, on_object_destroyed)

    -- Ticker
    Event.on_nth_tick(TICK_RATE, onTick)
end

--------------------------------------------------------------------------------
-- mod init/load code
--------------------------------------------------------------------------------

local function on_init()
    This.TrainTracker:init()
    This.TrainTracker:resync()
    register_events()
end

local function on_load()
    register_events()
end

-- setup player management
Player.register_events(true)

Event.on_init(on_init)
Event.on_load(on_load)
