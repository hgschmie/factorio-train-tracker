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

---@param event EventData.on_train_changed_state
local function on_train_changed_state(event)
    local train = event and event.train
    if not train then return end

    local train_name = const.getTrainName(train)

    local update_train_info = function(train_info)
        if not train_info then return end
        train_info.last_state = train.state
        train_info.last_tick = event.tick
        train_info.train_name = train_name
        train_info.train_id = train.id
    end

    local process_old_state = function()
        if event.old_state == defines.train_state.wait_station then
            -- station departure
            return This.TrainTracker:processStationDeparture(train, event.tick)
        elseif event.old_state == defines.train_state.wait_signal then
            -- signal departure
            return This.TrainTracker:processSignalDeparture(train, event.tick)
        end
        return nil
    end

    local train_info = process_old_state()
    update_train_info(train_info)

    local process_train_state = function()
        if train.state == defines.train_state.wait_station then
            -- station arrival. Housekeep all the run information
            return This.TrainTracker:processStationArrival(train, event.tick)
        elseif train.state == defines.train_state.wait_signal then
            -- signal arrival
            return This.TrainTracker:processSignalArrival(train, event.tick)
        else
            return nil
        end
    end

    process_train_state()
    update_train_info(train_info)
end

---@param event EventData.on_train_created
local function on_train_created(event)
    if not (event.train and event.train.valid) then return end
    local entity_type = This.TrainTracker:determineEntityType(event.train)
    This.TrainTracker:getOrCreateEntity(entity_type, event.train)
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

local function next_entity()
    storage.ticker.entity_type = next(const.entity_types, storage.ticker.entity_type) or next(const.entity_types)
    return storage.ticker.entity_type
end

local function onTick()
    storage.ticker = storage.ticker or {}

    local entity_type = storage.ticker.entity_type or next_entity()
    local entities = This.TrainTracker:entities(entity_type)
    local process_count = math.ceil((table_size(entities) * TICK_RATE) / 60)
    local index = storage.ticker.last_tick_index

    if process_count > 0 then
        ---@type tt.TrainInfo
        local train_info
        repeat
            index, train_info = next(entities, index)
            if train_info then
                local train = game.train_manager.get_train_by_id(train_info.train_id)
                if train and train.valid then
                    train_info.current_station = train.station
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

    if not index then next_entity() end
    storage.ticker.last_tick_index = index
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
