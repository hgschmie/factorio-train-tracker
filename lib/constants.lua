------------------------------------------------------------------------
-- mod constant definitions.
--
-- can be loaded into scripts and data
------------------------------------------------------------------------

local Constants = {
    prefix = 'hps__tt-',
    name = 'train-tracker',
    root = '__train-tracker__',
}

Constants.gfx_location = Constants.root .. '/graphics/'

--------------------------------------------------------------------------------
-- Framework intializer
--------------------------------------------------------------------------------

---@return FrameworkConfig config
function Constants.framework_init()
    return {
        -- prefix is the internal mod prefix
        prefix = Constants.prefix,
        -- name is a human readable name
        name = Constants.name,
        -- The filesystem root.
        root = Constants.root,
    }
end

--------------------------------------------------------------------------------
-- Path and name helpers
--------------------------------------------------------------------------------

---@param value string
---@return string result
function Constants:with_prefix(value)
    return self.prefix .. value
end

---@param path string
---@return string result
function Constants:png(path)
    return self.gfx_location .. path .. '.png'
end

---@param id string
---@return string result
function Constants:locale(id)
    return Constants:with_prefix('locale.') .. id
end

--------------------------------------------------------------------------------
-- entity names and maps
--------------------------------------------------------------------------------

-- Base name
Constants.tt_name = Constants:with_prefix(Constants.name)

Constants.hotkey_keys = { 'toggle_display' }
Constants.hotkey_names = {}
Constants.hotkey = {}

for _, key in pairs(Constants.hotkey_keys) do
    Constants.hotkey[key] = key
    Constants.hotkey_names[key] = Constants:with_prefix(key)
end

--------------------------------------------------------------------------------
-- other constants
--------------------------------------------------------------------------------

Constants.entity_types = {
    trains = 'trains',
    ships = 'ships',
}

Constants.ship_names = {
    -- cargo-ships mod
    ['boat_engine'] = true,
    ['cargo_ship_engine'] = true,
}

---@enum tt.limit_dropdown
Constants.limit_dropdown = {
    all = 1,
    show10 = 2,
    show25 = 3,
}

Constants.limit_dropdown_values = { -1, 10, 25 }

---@enum tt.filter_dropdown
Constants.filter_dropdown = {
    id = 1,
    name = 2,
    last_station = 3,
    current_station = 4,
    next_station = 5,
    state = 6,
}
---@param station (string|LuaEntity)?
---@param default string?
---@return string station_name
function Constants.get_station_name(station, default)
    if station then
        if type(station) == 'string' then return station end
        if station.valid then return station.backer_name end
    end
    return default
end

---@type (fun(train_info: tt.TrainInfo, entity_type: string?, player: LuaPlayer?): string?)[]
Constants.filter_dropdown_values = {
    function(train_info) return tostring(train_info.train_id) end,
    function(train_info) return train_info.train_name end,
    function(train_info) return Constants.get_station_name(train_info.last_station, '') end,
    function(train_info) return Constants.get_station_name(train_info.current_station, '') end,
    function(train_info) return Constants.get_station_name(train_info.next_station, '') end,
    function(train_info, entity_type, player)
        local state = train_info.last_state
        if not state then return nil end
        local key = Constants.trainStateKey(train_info.last_state, entity_type)
        return Framework.translation_manager:translate(player, Constants:locale(key))
    end
}

---@param id number|defines.train_state
---@param entity_type string
function Constants.trainStateKey(id, entity_type)
    return ('%s.train-state-%d'):format(entity_type, id)
end

--------------------------------------------------------------------------------
-- sorting constants
--------------------------------------------------------------------------------

Constants.sorting_keys = {
    'train_id',
    'train_name',
    'total_distance',
    'total_runtime',
    'stop_waittime',
    'signal_waittime',
    'last_station',
    'current_station',
    'next_station',
    'state',
}

Constants.sorting = {}

for _, key in pairs(Constants.sorting_keys) do
    Constants.sorting[key] = key
end

--------------------------------------------------------------------------------
-- settings
--------------------------------------------------------------------------------

Constants.settings_keys = {}

Constants.settings_names = {}
Constants.settings = {}

for _, key in pairs(Constants.settings_keys) do
    Constants.settings_names[key] = key
    Constants.settings[key] = Constants:with_prefix(key)
end

return Constants
