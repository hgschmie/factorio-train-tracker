------------------------------------------------------------------------
-- Sorting related code
------------------------------------------------------------------------
assert(script)

local math = require('stdlib.utils.math')
local const = require('lib.constants')

local Tree = require('scripts.tree')

local FREIGHT_COLUMN_COUNT = 8

---@class tt.Sorting
---@field keys string[]
---@field sorting table<string, tt.SortColumn>
---@field tab_info table<tt.SortColumn, tt.TabInfo>
---@field alignment table<tt.SortColumn, string>
---@field tooltip table<tt.SortColumn, string>
local Sorting = {
    ---@enum tt.SortColumn
    keys = {
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
        'current_freight',
        'total_freight'
    },
    sorting = {},
}

for _, key in pairs(Sorting.keys) do
    Sorting.sorting[key] = key --[[@as tt.SortColumn ]]
end

---@alias tt.Formatter fun(train_info: tt.TrainInfo, entity_type: string?, parent: LuaGuiElement?, name: string?): (string|LocalisedString)?

---@class tt.TabInfo
---@field comparator (fun(a: tt.TrainInfo, b: tt.TrainInfo): integer)?
---@field formatter tt.Formatter
---@field tags (fun(gui: framework.gui, train_info: tt.TrainInfo, event_type: string?) : table<string, string>)?
---@field alignment string?
---@field tooltip string?
---@field raw boolean?


------------------------------------------------------------------------
-- Comparators
------------------------------------------------------------------------

---@param a tt.TrainInfo
---@param b tt.TrainInfo
local function compare_train_id(a, b)
    return math.sign(a.train_id - b.train_id)
end

---@param a string?
---@param b string?
local function compare_string(a, b)
    if not a then return (b and -1 or 0) end
    if not b then return 1 end
    if a < b then return -1 end
    if a > b then return 1 end
    return 0
end

------------------------------------------------------------------------
-- Formatters
------------------------------------------------------------------------

---@param value (integer|string)?
---@return string
local function format_string(value)
    return value and tostring(value) or nil
end

---@param tick_value number?
---@return string
local function format_time(tick_value)
    if tick_value == 0 then return '0s' end
    local seconds = tick_value / 60
    if seconds < 60 then return ('%.2fs'):format(seconds) end
    local minutes = math.floor(seconds / 60)
    seconds = seconds - minutes * 60
    if minutes < 60 then return ('%02d:%05.2fs'):format(minutes, seconds) end
    local hours = math.floor(minutes / 60)
    minutes = minutes - hours * 60
    return ('%02d:%02d:%05.2fs'):format(hours, minutes, seconds)
end

---@param freight tt.Freight
---@param parent LuaGuiElement
---@param name string
local function freight_formatter(freight, parent, name)

    local child = parent.add {
        type = 'table',
        style = 'compact_slot_table',
        name = name,
        column_count = FREIGHT_COLUMN_COUNT,
    }

    child.style.width = FREIGHT_COLUMN_COUNT * 38

    local tree = Tree.create(compare_string)
    for key in pairs(freight) do
        tree:add(key)
    end

    local count = 0

    local add_freight_item = function(key)
        local freight_item = freight[key]
        local type = freight_item.type

        child.add {
            type = 'sprite-button',
            sprite = ('%s/%s'):format(type, freight_item.name),
            number = freight_item.count,
            quality = freight_item.quality,
            style = 'compact_slot',
            tooltip = freight_item.count,
            elem_tooltip = {
                name = freight_item.name,
                type = type == 'item' and 'item-with-quality' or 'fluid',
                quality = freight_item.quality,
            },
            enabled = true,

        }
        count = count + 1
    end

    tree:traverse(add_freight_item)

    while (count % FREIGHT_COLUMN_COUNT) > 0 do
        child.add {
            type = 'sprite',
            enabled = true,
        }
        count = count + 1
    end
end


------------------------------------------------------------------------
-- tag functions
------------------------------------------------------------------------

---@param gui framework.gui
---@param train_info tt.TrainInfo
---@return table<string, string>?
local function tag_train_id(gui, train_info)
    if not train_info.train_name then return nil end

    return {
        id = train_info.train_id,
        handler = {
            [defines.events.on_gui_click] = gui.gui_events.onClickEntity,
        },
    }
end

---@param gui framework.gui
---@param train_info tt.TrainInfo
---@return table<string, string>?
local function tag_last_station_id(gui, train_info)
    if not (train_info.last_station and train_info.last_station.valid) then return nil end

    return {
        id = train_info.train_id,
        handler = {
            [defines.events.on_gui_click] = gui.gui_events.onClickLastStation
        },
    }
end

---@param gui framework.gui
---@param train_info tt.TrainInfo
---@return table<string, string>?
local function tag_current_station_id(gui, train_info)
    if not (train_info.current_station and train_info.current_station.valid) then return nil end

    return {
        id = train_info.train_id,
        handler = {
            [defines.events.on_gui_click] = gui.gui_events.onClickCurrentStation
        },
    }
end

---@param gui framework.gui
---@param train_info tt.TrainInfo
---@return table<string, string>?
local function tag_next_station_id(gui, train_info)
    if not (train_info.next_station and type(train_info.next_station) ~= 'string') then return nil end

    return {
        id = train_info.train_id,
        handler = {
            [defines.events.on_gui_click] = gui.gui_events.onClickNextStation
        },
    }
end

------------------------------------------------------------------------
-- Sorting information for all columns in a tab
------------------------------------------------------------------------

Sorting.tab_info = {
    [Sorting.sorting.train_id] = {
        comparator = compare_train_id,
        formatter = function(train_info)
            return format_string(train_info.train_id)
        end,
        tags = tag_train_id,
        alignment = 'center',
        tooltip = 'shift',
    },
    [Sorting.sorting.train_name] = {
        comparator = function(a, b)
            local result = compare_string(a.train_name, b.train_name)
            if result ~= 0 then return result end
            return compare_train_id(a, b)
        end,
        formatter = function(train_info)
            return format_string(train_info.train_name)
        end,
        tags = tag_train_id,
        alignment = 'left',
        tooltip = 'shift',
    },
    [Sorting.sorting.total_distance] = {
        comparator = function(a, b)
            local result = math.sign(a.total_distance - b.total_distance)
            if result ~= 0 then return result end
            return compare_train_id(a, b)
        end,
        formatter = function(train_info)
            return const.formatDistance(train_info.total_distance)
        end,
        alignment = 'right',
    },
    [Sorting.sorting.total_runtime] = {
        comparator = function(a, b)
            local result = math.sign(a.total_runtime - b.total_runtime)
            if result ~= 0 then return result end
            return compare_train_id(a, b)
        end,
        formatter = function(train_info)
            return format_time(train_info.total_runtime)
        end,
        alignment = 'right',
    },
    [Sorting.sorting.stop_waittime] = {
        comparator = function(a, b)
            local result = math.sign(a.stop_waittime - b.stop_waittime)
            if result ~= 0 then return result end
            return compare_train_id(a, b)
        end,
        formatter = function(train_info)
            return format_time(train_info.stop_waittime)
        end,
        alignment = 'right',
    },
    [Sorting.sorting.signal_waittime] = {
        comparator = function(a, b)
            local result = math.sign(a.signal_waittime - b.signal_waittime)
            if result ~= 0 then return result end
            return compare_train_id(a, b)
        end,
        formatter = function(train_info)
            return format_time(train_info.signal_waittime)
        end,
        alignment = 'right',
    },
    [Sorting.sorting.last_station] = {
        comparator = function(a, b)
            local left = const.getStationName(a.last_station)
            local right = const.getStationName(b.last_station)
            local result = compare_string(left, right)
            if result ~= 0 then return result end

            return compare_train_id(a, b)
        end,
        formatter = function(train_info)
            return const.getStationName(train_info.last_station, '')
        end,
        tags = tag_last_station_id,
        alignment = 'left',
        tooltip = 'shift',
    },
    [Sorting.sorting.current_station] = {
        comparator = function(a, b)
            local left = const.getStationName(a.current_station)
            local right = const.getStationName(b.current_station)
            local result = compare_string(left, right)
            if result ~= 0 then return result end

            return compare_train_id(a, b)
        end,
        formatter = function(train_info)
            return const.getStationName(train_info.current_station, '')
        end,
        tags = tag_current_station_id,
        alignment = 'left',
        tooltip = 'shift',
    },
    [Sorting.sorting.next_station] = {
        comparator = function(a, b)
            local left = const.getStationName(a.next_station)
            local right = const.getStationName(b.next_station)
            local result = compare_string(left, right)
            if result ~= 0 then return result end

            return compare_train_id(a, b)
        end,
        formatter = function(train_info)
            return const.getStationName(train_info.next_station, '')
        end,
        tags = tag_next_station_id,
        alignment = 'left',
        tooltip = 'shift',
    },
    [Sorting.sorting.state] = {
        comparator = function(a, b)
            if not a.last_state then return b.last_state and -1 or 0 end
            if not b.last_state then return 1 end
            local result = math.sign(a.last_state - b.last_state)
            if result ~= 0 then return result end

            return compare_train_id(a, b)
        end,
        formatter = function(train_info, entity_type)
            return train_info.last_state and { const:locale(const.trainStateKey(train_info.last_state, entity_type)) } or nil
        end,
        alignment = 'left',
    },
    [Sorting.sorting.current_freight] = {
        comparator = function(a, b)
            local left = table_size(a.current_freight)
            local right = table_size(b.current_freight)
            local result = math.sign(right - left)
            if result ~= 0 then return result end
            return compare_train_id(a, b)
        end,
        formatter = function(train_info, entity_type, parent, name)
            return freight_formatter(train_info.current_freight, parent, name)
        end,
        alignment = 'left',
        raw = true,
    },
    [Sorting.sorting.total_freight] = {
        comparator = function(a, b)
            local left = table_size(a.total_freight)
            local right = table_size(b.total_freight)
            local result = math.sign(right - left)
            if result ~= 0 then return result end
            return compare_train_id(a, b)
        end,
        formatter = function(train_info, entity_type, parent, name)
            return freight_formatter(train_info.total_freight, parent, name)
        end,
        alignment = 'left',
        raw = true,
    },
}

return Sorting
