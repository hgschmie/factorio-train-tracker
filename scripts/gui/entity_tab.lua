------------------------------------------------------------------------
-- Code for entity lists
------------------------------------------------------------------------

local Player = require('stdlib.event.player')
local math = require('stdlib.utils.math')

-- load extended string library
require('stdlib.utils.string')

local const = require('lib.constants')

local GuiTools = require('scripts.gui_tools')

local Tree = require('scripts.tree')


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

---@param value number?
---@return string
local function format_distance(value)
    if value == 0 then return '0m' end
    if value < 10000 then return ('%.2fm'):format(value) end
    return ('%.2fkm'):format(value / 1000)
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
            [defines.events.on_gui_click] = gui.gui_events.onClickEntity
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

---@alias tt.Formatter fun(train_info: tt.TrainInfo, entity_type: string?): (string|LocalisedString)?

---@class tt.TabInfo
---@field comparator fun(a: tt.TrainInfo, b: tt.TrainInfo): integer
---@field formatter tt.Formatter
---@field tags (fun(gui: framework.gui, train_info: tt.TrainInfo, event_type: string?) : table<string, string>)?

---@type table<string, tt.TabInfo>
local tab_info = {
    [const.sorting.train_id] = {
        comparator = compare_train_id,
        formatter = function(train_info)
            return format_string(train_info.train_id)
        end,
        tags = tag_train_id,
    },
    [const.sorting.train_name] = {
        comparator = function(a, b)
            local result = compare_string(a.train_name, b.train_name)
            if result ~= 0 then return result end
            return compare_train_id(a, b)
        end,
        formatter = function(train_info)
            return format_string(train_info.train_name)
        end,
        tags = tag_train_id,
    },
    [const.sorting.total_distance] = {
        comparator = function(a, b)
            local result = math.sign(a.total_distance - b.total_distance)
            if result ~= 0 then return result end
            return compare_train_id(a, b)
        end,
        formatter = function(train_info)
            return format_distance(train_info.total_distance)
        end,
    },
    [const.sorting.total_runtime] = {
        comparator = function(a, b)
            local result = math.sign(a.total_runtime - b.total_runtime)
            if result ~= 0 then return result end
            return compare_train_id(a, b)
        end,
        formatter = function(train_info)
            return format_time(train_info.total_runtime)
        end,
    },
    [const.sorting.stop_waittime] = {
        comparator = function(a, b)
            local result = math.sign(a.stop_waittime - b.stop_waittime)
            if result ~= 0 then return result end
            return compare_train_id(a, b)
        end,
        formatter = function(train_info)
            return format_time(train_info.stop_waittime)
        end,
    },
    [const.sorting.signal_waittime] = {
        comparator = function(a, b)
            local result = math.sign(a.signal_waittime - b.signal_waittime)
            if result ~= 0 then return result end
            return compare_train_id(a, b)
        end,
        formatter = function(train_info)
            return format_time(train_info.signal_waittime)
        end,
    },
    [const.sorting.next_station] = {
        comparator = function(a, b)
            local left = const.get_station_name(a.next_station)
            local right = const.get_station_name(b.next_station)
            local result = compare_string(left, right)
            if result ~= 0 then return result end

            return compare_train_id(a, b)
        end,
        formatter = function(train_info)
            return const.get_station_name(train_info.next_station, '')
        end,
        tags = tag_next_station_id,
    },
    [const.sorting.last_station] = {
        comparator = function(a, b)
            local left = const.get_station_name(a.last_station)
            local right = const.get_station_name(b.last_station)
            local result = compare_string(left, right)
            if result ~= 0 then return result end

            return compare_train_id(a, b)
        end,
        formatter = function(train_info)
            return const.get_station_name(train_info.last_station, '')
        end,
        tags = tag_last_station_id,
    },
    [const.sorting.state] = {
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
    },
}

---@param gui framework.gui
---@param entity_type string
---@param sort_value string sorted value constant
---@return framework.gui.element_definition
local function render_checkbox(gui, entity_type, sort_value)
    ---@type tt.PlayerStorage
    local player_data = assert(Player.pdata(gui.player_index))
    local tab_state = assert(player_data.tab_state[entity_type])

    return GuiTools.renderCheckbox(gui, entity_type, gui.gui_events.onSort, tab_state, sort_value)
end

---@param gui framework.gui
---@param entity_type string
---@param field string
---@param train_info tt.TrainInfo
---@param tooltip_override string?
local function flow_add(gui, entity_type, field, train_info, tooltip_override)
    local element = assert(gui:find_element(entity_type .. '-' .. field))
    local tags = tab_info[field].tags and tab_info[field].tags(gui, train_info) or nil

    element.add {
        type = 'label',
        name = gui:generate_gui_name(('%s-%s-%d'):format(entity_type, field, train_info.train_id)),
        caption = tab_info[field].formatter(train_info, entity_type) or { const:locale('unknown') },
        style = tags and 'tt_clickable_label' or 'label',
        tags = tags,
        tooltip = tags and { const:locale('open_gui_' .. (tooltip_override or field)) },
    }
end

---@param entity_type string
---@return tt.GuiPane
local function create_gui_pane(entity_type)
    local entity_table = entity_type .. '_table'

    return {
        init = function()
            return {
                sort = const.sorting.train_id,
                sort_mode = {},
                limit = const.limit_dropdown.all,
                filter = const.filter_dropdown.id,
                search = '',
            }
        end,
        getGui = function(gui)
            local gui_events = gui.gui_events

            return {
                tab = {
                    type = 'tab',
                    style = 'tab',
                    caption = { const:locale(entity_type) },
                    handler = { [defines.events.on_gui_selected_tab_changed] = gui_events.onTabChanged },
                    elem_tags = {
                        tab = entity_type,
                    }
                },
                content = {
                    type = 'frame',
                    style = 'deep_frame_in_tabbed_pane',
                    style_mods = {
                        horizontally_stretchable = true,
                    },
                    direction = 'vertical',
                    children = {
                        {
                            type = 'scroll-pane',
                            direction = 'vertical',
                            visible = true,
                            vertical_scroll_policy = 'auto',
                            horizontal_scroll_policy = 'never',
                            style_mods = {
                                horizontally_stretchable = true,
                                vertically_stretchable = false,
                            },
                            children = {
                                {
                                    type = 'table',
                                    style = 'table',
                                    name = entity_table,
                                    column_count = table_size(const.sorting),
                                    draw_horizontal_line_after_headers = true,
                                    style_mods = {
                                        margin = 4,
                                        cell_padding = 2,
                                    },
                                    children = {
                                        render_checkbox(gui, entity_type, const.sorting.train_id),
                                        render_checkbox(gui, entity_type, const.sorting.train_name),
                                        render_checkbox(gui, entity_type, const.sorting.total_distance),
                                        render_checkbox(gui, entity_type, const.sorting.total_runtime),
                                        render_checkbox(gui, entity_type, const.sorting.signal_waittime),
                                        render_checkbox(gui, entity_type, const.sorting.stop_waittime),
                                        render_checkbox(gui, entity_type, const.sorting.last_station),
                                        render_checkbox(gui, entity_type, const.sorting.next_station),
                                        render_checkbox(gui, entity_type, const.sorting.state),
                                        {
                                            type = 'flow',
                                            name = entity_type .. '-' .. const.sorting.train_id,
                                            direction = 'vertical',
                                            style_mods = {
                                                horizontally_stretchable = true,
                                                horizontal_align = 'center',
                                            },
                                        },
                                        {
                                            type = 'flow',
                                            name = entity_type .. '-' .. const.sorting.train_name,
                                            direction = 'vertical',
                                            style_mods = {
                                                horizontally_stretchable = true,
                                                horizontal_align = 'left',
                                            },
                                        },
                                        {
                                            type = 'flow',
                                            name = entity_type .. '-' .. const.sorting.total_distance,
                                            direction = 'vertical',
                                            style_mods = {
                                                minimal_width = 80,
                                                horizontally_stretchable = true,
                                                horizontal_align = 'right',
                                            },
                                        },
                                        {
                                            type = 'flow',
                                            name = entity_type .. '-' .. const.sorting.total_runtime,
                                            direction = 'vertical',
                                            style_mods = {
                                                minimal_width = 80,
                                                horizontally_stretchable = true,
                                                horizontal_align = 'right',
                                            },
                                        },
                                        {
                                            type = 'flow',
                                            name = entity_type .. '-' .. const.sorting.signal_waittime,
                                            direction = 'vertical',
                                            style_mods = {
                                                minimal_width = 80,
                                                horizontally_stretchable = true,
                                                horizontal_align = 'right',
                                            },
                                        },
                                        {
                                            type = 'flow',
                                            name = entity_type .. '-' .. const.sorting.stop_waittime,
                                            direction = 'vertical',
                                            style_mods = {
                                                minimal_width = 80,
                                                horizontally_stretchable = true,
                                                horizontal_align = 'right',
                                            },
                                        },
                                        {
                                            type = 'flow',
                                            name = entity_type .. '-' .. const.sorting.last_station,
                                            direction = 'vertical',
                                            style_mods = {
                                                horizontally_stretchable = true,
                                                horizontal_align = 'left',
                                            },
                                        },
                                        {
                                            type = 'flow',
                                            name = entity_type .. '-' .. const.sorting.next_station,
                                            direction = 'vertical',
                                            style_mods = {
                                                horizontally_stretchable = true,
                                                horizontal_align = 'left',
                                            },
                                        },
                                        {
                                            type = 'flow',
                                            name = entity_type .. '-' .. const.sorting.state,
                                            direction = 'vertical',
                                            style_mods = {
                                                horizontally_stretchable = true,
                                                horizontal_align = 'left',
                                            },
                                        },
                                    },
                                },
                            }, -- children
                        },     -- scroll-pane
                    },         -- children
                },             -- content
            }
        end,
        onSort = function(event, gui)
            ---@type tt.PlayerStorage
            local player_data = assert(Player.pdata(gui.player_index))
            local tab_state = player_data.tab_state[entity_type]

            tab_state.sort = event.element.tags.value
            tab_state.sort_mode[tab_state.sort] = event.element.state

            ---@type tt.GuiContext
            local context = gui.context
            context.pacer = 0
        end,
        onClickEntity = function(event, gui)
            local player = assert(Player.get(gui.player_index))

            local train_id = assert(event.element.tags.id)
            local train = game.train_manager.get_train_by_id(train_id)
            if not (train and train.valid) then return end
            local loco = This.TrainTracker.getMainLocomotive(train)
            if not (loco and loco.valid) then return end

            if event.shift then
                player.opened = nil
                player.set_controller {
                    type = defines.controllers.remote,
                    position = loco.position,
                    surface = loco.surface,
                }
            else
                player.opened = loco
            end
        end,
        onClickLastStation = function(event, gui)
            local player = assert(Player.get(gui.player_index))

            local train_id = assert(event.element.tags.id)
            local train_info = This.TrainTracker:getEntity(entity_type, train_id)
            if not train_info then return end

            local station = train_info.last_station
            if not (station and station.valid) then return end

            if event.shift then
                player.opened = nil
                player.set_controller {
                    type = defines.controllers.remote,
                    position = station.position,
                    surface = station.surface,
                }
            else
                player.opened = station
            end
        end,
        onClickNextStation = function(event, gui)
            local player = assert(Player.get(gui.player_index))

            local train_id = assert(event.element.tags.id)
            local train_info = This.TrainTracker:getEntity(entity_type, train_id)
            if not train_info then return end

            local station = train_info.next_station
            if not (station and type(station) ~= 'string' and station.valid) then return end

            if event.shift then
                player.opened = nil
                player.set_controller {
                    type = defines.controllers.remote,
                    position = station.position,
                    surface = station.surface,
                }
            else
                player.opened = station
            end
        end,
        refreshGuiPane = function(gui)
            local train_table = assert(gui:find_element(entity_table))
            -- first set of columns are the headers, second set are the flows
            assert(#train_table.children == train_table.column_count * 2)

            if not train_table then return false end

            ---@type LuaPlayer, tt.PlayerStorage
            local player, player_data = Player.get(gui.player_index)
            assert(player)
            assert(player_data)

            local trains = This.TrainTracker:entities(entity_type)

            local tab_state = player_data.tab_state[entity_type]

            local tree = Tree.create(tab_info[tab_state.sort].comparator, tab_state.sort_mode[tab_state.sort])

            for _, train_info in pairs(trains) do
                tree:add(train_info)
            end

            for i = train_table.column_count + 1, train_table.column_count * 2 do
                train_table.children[i].clear()
            end

            local limit = const.limit_dropdown_values[tab_state.limit] or -1

            local filter_func = assert(const.filter_dropdown_values[tab_state.filter or const.filter_dropdown.id])
            local search = tab_state.search:pattern_escape():trim():lower()

            tree:traverse(function(train_info)
                if search:len() > 0 then
                    local match_string = filter_func(train_info, entity_type, player):lower()
                    if not (match_string and match_string:contains(search)) then return false end
                end

                flow_add(gui, entity_type, const.sorting.train_id, train_info, const.sorting.last_station)
                flow_add(gui, entity_type, const.sorting.train_name, train_info, const.sorting.last_station)
                flow_add(gui, entity_type, const.sorting.total_distance, train_info)
                flow_add(gui, entity_type, const.sorting.total_runtime, train_info)
                flow_add(gui, entity_type, const.sorting.signal_waittime, train_info)
                flow_add(gui, entity_type, const.sorting.stop_waittime, train_info)
                flow_add(gui, entity_type, const.sorting.next_station, train_info, const.sorting.last_station)
                flow_add(gui, entity_type, const.sorting.last_station, train_info)
                flow_add(gui, entity_type, const.sorting.state, train_info)

                return true
            end, limit)

            return true
        end,
        updateGuiPane = function(gui)
            ---@type tt.PlayerStorage
            local player_data = assert(Player.pdata(gui.player_index))
            local tab_state = player_data.tab_state[entity_type]

            local train_table = assert(gui:find_element(entity_table))
            for i = 1, train_table.column_count do
                GuiTools.updateCheckbox(train_table.children[i], tab_state)
            end

            return true
        end,
    }
end

return {
    create_gui_pane = create_gui_pane,
}
