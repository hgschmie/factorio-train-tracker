------------------------------------------------------------------------
-- Code for entity lists
------------------------------------------------------------------------
assert(script)

local Player = require('stdlib.event.player')

-- load extended string library
require('stdlib.utils.string')

local const = require('lib.constants')

local Tree = require('scripts.tree')

---@class tt.Sorting
local Sorting = require('scripts.sorting')

---@param gui framework.gui
---@param entity_type string
---@param tab_name string
---@param sort_value string sorted value constant
---@return framework.gui.element_definition
local function render_checkbox(gui, entity_type, tab_name, sort_value)
    ---@type tt.PlayerStorage
    local player_data = assert(Player.pdata(gui.player_index))

    local tab_state = assert(player_data.tab_state[entity_type])
    local gui_events = gui.gui_events
    local style = (tab_state.sort == sort_value) and 'tt_selected_sort_checkbox' or 'tt_sort_checkbox'

    tab_state.sort_mode[sort_value] = tab_state.sort_mode[sort_value] or false

    local tab_prefix = ('%s_%s'):format(entity_type, tab_name)
    local locale_key = ('%s.%s'):format(entity_type, sort_value)

    return {
        type = 'checkbox',
        style = style,
        name = 'check-' .. tab_prefix .. '-' .. sort_value,
        caption = { const:locale(locale_key) },
        handler = { [defines.events.on_gui_checked_state_changed] = gui_events[gui.gui_events.onSort] },
        state = tab_state.sort_mode[sort_value],
        tooltip = { const:locale('tooltip_' .. locale_key) },
        elem_tags = {
            value = sort_value,
            entity_type = entity_type,
        },
        style_mods = {
            horizontal_align = 'center',
        },
    }
end

---@param entity_type string
---@param tab_name string
---@param column_name string
---@return framework.gui.element_definition
local function render_heading(entity_type, tab_name, column_name)
    local tab_prefix = ('%s_%s'):format(entity_type, tab_name)
    local locale_key = ('%s.%s'):format(entity_type, column_name)

    return {
        type = 'label',
        name = 'header-' .. tab_prefix .. '-' .. column_name,
        caption = { const:locale(locale_key) },
        tooltip = { const:locale('tooltip_' .. locale_key) },
        style = 'label',
        style_mods = {
            horizontal_align = 'center',
        },
    }
end

---@param gui framework.gui
---@param entity_type string
---@param tab_name string
---@param field string
---@param train_info tt.TrainInfo
---@param tooltip_override string?
local function flow_add(gui, entity_type, tab_name, field, train_info, tooltip_override)
    local tab_prefix = ('%s_%s'):format(entity_type, tab_name)
    local field_name = ('%s-%s'):format(tab_prefix, field)
    local element = gui:find_element(field_name)
    if not element then return end

    local tab_info = assert(Sorting.tab_info[field])

    local tags = tab_info.tags and tab_info.tags(gui, train_info) or nil

    local name = gui:generate_gui_name(('%s-%d'):format(field_name, train_info.train_id))
    if tab_info.raw or false then
        tab_info.formatter(train_info, entity_type, element, name)
    else
        element.add {
            type = 'label',
            name = name,
            caption = tab_info.formatter(train_info, entity_type, element, name) or { const:locale('unknown') },
            style = tags and 'tt_clickable_label' or 'label',
            tags = tags,
            tooltip = tags and { const:locale('open_gui_' .. (tooltip_override or field)) },
        }
    end
end

------------------------------------------------------------------------
-- implementation functions
------------------------------------------------------------------------

---@type table<string, tt.SortColumn[]>
local tab_columns = {
    dist = {
        Sorting.sorting.train_id,
        Sorting.sorting.train_name,
        Sorting.sorting.total_distance,
        Sorting.sorting.total_runtime,
        Sorting.sorting.signal_waittime,
        Sorting.sorting.stop_waittime,
    },
    station = {
        Sorting.sorting.train_id,
        Sorting.sorting.train_name,
        Sorting.sorting.last_station,
        Sorting.sorting.current_station,
        Sorting.sorting.next_station,
        Sorting.sorting.state,
    },
    freight = {
        Sorting.sorting.train_id,
        Sorting.sorting.train_name,
        Sorting.sorting.freight,
    },
}

---@param gui framework.gui
---@param entity_type string
---@param tab_name string
---@return tt.GuiElement
local function get_gui_pane(gui, entity_type, tab_name)
    local gui_events = gui.gui_events
    local tab_prefix = entity_type .. '_' .. tab_name
    local entity_table = tab_prefix .. '_table'

    local columns = assert(tab_columns[tab_name])

    ---@type framework.gui.element_definition[]
    local children = {}

    for index, column_name in pairs(columns) do
        children[index] = Sorting.tab_info[column_name].comparator
            and render_checkbox(gui, entity_type, tab_name, column_name)
            or render_heading(entity_type, tab_name, column_name)
        children[index + table_size(columns)] = {
            type = 'flow',
            name = tab_prefix .. '-' .. column_name,
            direction = 'vertical',
            style_mods = {
                horizontal_align = Sorting.tab_info[column_name].alignment,
                horizontally_stretchable = true,
            },
        }
    end

    return {
        tab = {
            type = 'tab',
            style = 'tab',
            caption = { const:locale(tab_prefix) },
            handler = { [defines.events.on_gui_selected_tab_changed] = gui_events.onTabChanged },
            elem_tags = {
                entity_type = entity_type,
                tab_name = tab_name,
            }
        },
        content = {
            type = 'frame',
            style = 'deep_frame_in_tabbed_pane',
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
                        horizontally_squashable = true,
                        vertically_stretchable = false,
                    },
                    children = {
                        {
                            type = 'table',
                            style = 'table',
                            name = entity_table,
                            column_count = table_size(columns),
                            draw_horizontal_line_after_headers = true,
                            style_mods = {
                                margin = 4,
                                cell_padding = 2,
                            },
                            children = children,
                        },
                    }, -- children
                },     -- scroll-pane
            },         -- children
        },             -- content
    }
end


------------------------------------------------------------------------
-- gui pane creation
------------------------------------------------------------------------

---@param entity_type string
---@return tt.GuiPane
local function create_gui_pane(entity_type)
    return {
        init = function()
            return {
                sort = Sorting.sorting.train_id,
                sort_mode = {},
                limit = const.limit_dropdown.all,
                filter = const.filter_dropdown.id,
                search = '',
            }
        end,
        getGui = function(gui)
            return {
                get_gui_pane(gui, entity_type, 'dist'),
                get_gui_pane(gui, entity_type, 'station'),
                get_gui_pane(gui, entity_type, 'freight'),
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
        onClickCurrentStation = function(event, gui)
            local player = assert(Player.get(gui.player_index))

            local train_id = assert(event.element.tags.id)
            local train_info = This.TrainTracker:getEntity(entity_type, train_id)
            if not train_info then return end

            local station = train_info.current_station
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
        refreshGuiPane = function(gui, tab_name)
            local entity_table = (('%s_%s'):format(entity_type, tab_name)) .. '_table'

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

            local comparator = assert(Sorting.tab_info[tab_state.sort].comparator)
            local tree = Tree.create(comparator, tab_state.sort_mode[tab_state.sort])

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

                local columns = assert(tab_columns[tab_name])

                for _, column_name in pairs(columns) do
                    flow_add(gui, entity_type, tab_name, column_name, train_info, Sorting.tab_info[column_name].tooltip)
                end

                return true
            end, limit)

            return true
        end,
        updateGuiPane = function(gui, tab_name)
            local entity_table = (('%s_%s'):format(entity_type, tab_name)) .. '_table'

            ---@type tt.PlayerStorage
            local player_data = assert(Player.pdata(gui.player_index))
            local tab_state = player_data.tab_state[entity_type]

            local train_table = assert(gui:find_element(entity_table))
            for i = 1, train_table.column_count do
                local checkbox = train_table.children[i]
                if checkbox.tags.value then
                    checkbox.style = (tab_state.sort == checkbox.tags.value) and 'tt_selected_sort_checkbox' or 'tt_sort_checkbox'
                    checkbox.state = tab_state.sort_mode[checkbox.tags.value] or false
                end
            end

            return true
        end,
    }
end

return {
    create_gui_pane = create_gui_pane,
}
