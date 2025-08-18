------------------------------------------------------------------------
-- GUI
------------------------------------------------------------------------
assert(script)

local Event = require('stdlib.event.event')
local Player = require('stdlib.event.player')

local const = require('lib.constants')

local EntityTab = require('scripts.gui.entity_tab')
local Sorting = require('scripts.sorting')

---@class tt.TabState
---@field tab_index integer?
---@field sort string
---@field sort_mode table<string, boolean>
---@field limit tt.limit_dropdown
---@field filter tt.filter_dropdown
---@field search string

---@class tt.PlayerStorage
---@field tab_state table<string, tt.TabState>
---@field tab string
---@field toggle boolean?

---@alias tt.GuiElement framework.gui.element_definition[]

---@class tt.GuiPane
---@field init fun(): tt.TabState
---@field getGui fun(gui: framework.gui) : tt.GuiElement[]
---@field onSort fun(event: EventData.on_gui_checked_state_changed, gui: framework.gui)
---@field onClickEntity fun(event: EventData.on_gui_click, gui: framework.gui)
---@field onClickLastStation fun(event: EventData.on_gui_click, gui: framework.gui)
---@field onClickCurrentStation fun(event: EventData.on_gui_click, gui: framework.gui)
---@field onClickNextStation fun(event: EventData.on_gui_click, gui: framework.gui)
---@field updateGuiPane fun(gui: framework.gui, tab_name: string): boolean
---@field refreshGuiPane fun(gui: framework.gui, tab_name: string): boolean

---@class tt.Gui
---@field NAME string
---@field gui_panes table<string, tt.GuiPane>
local Gui = {
    NAME = 'train-tracker-gui',
    gui_panes = {
        [const.entity_types.trains] = EntityTab.create_gui_pane(const.entity_types.trains),
        [const.entity_types.ships] = const.has_ships and EntityTab.create_gui_pane(const.entity_types.ships) or nil
    },
}

----------------------------------------------------------------------------------------------------
-- UI definition
----------------------------------------------------------------------------------------------------

--- Provides all the events used by the GUI and their mappings to functions. This must be outside the
--- GUI definition as it can not be serialized into storage.
---@return framework.gui_manager.event_definition
local function get_gui_event_definition()
    return {
        events = {
            onWindowClosed = Gui.onWindowClosed,
            onTabChanged = Gui.onTabChanged,
            onSort = Gui.onSort,
            onClickEntity = Gui.onClickEntity,
            onClickLastStation = Gui.onClickLastStation,
            onClickCurrentStation = Gui.onClickCurrentStation,
            onClickNextStation = Gui.onClickNextStation,
            onLimitChanged = Gui.onLimitChanged,
            onFilterFieldChanged = Gui.onFilterFieldChanged,
            onFilterTextChanged = Gui.onFilterTextChanged,
        },
        callback = Gui.guiUpdater,
    }
end

--- Returns the definition of the GUI. All events must be mapped onto constants from the gui_events array.
---@param gui framework.gui
---@return framework.gui.element_definition ui
function Gui.getUi(gui)
    ---@type LuaPlayer, tt.PlayerStorage
    local player, player_data = Player.get(gui.player_index)
    assert(player)
    assert(player_data)

    local gui_events = gui.gui_events
    local max_height = ((player.display_resolution.height / player.display_scale) - 80) / 2

    -- only enable children that are actually present
    local children = {}

    for _, gui_pane in pairs(Gui.gui_panes) do
        local gui_children = gui_pane.getGui(gui)
        for _, gui_child in pairs(gui_children) do
            table.insert(children, gui_child)
        end
    end

    return {
        type = 'frame',
        name = 'gui_root',
        direction = 'vertical',
        handler = { [defines.events.on_gui_closed] = gui_events.onWindowClosed },
        elem_mods = { auto_center = true },
        children = {
            { -- Title Bar
                type = 'flow',
                style = 'frame_header_flow',
                drag_target = 'gui_root',
                children = {
                    {
                        type = 'label',
                        style = 'frame_title',
                        caption = { const:locale(const.name) },
                        drag_target = 'gui_root',
                        ignored_by_interaction = true,
                    },
                    {
                        type = 'empty-widget',
                        style = 'framework_titlebar_drag_handle',
                        ignored_by_interaction = true,
                    },
                    {
                        type = 'sprite-button',
                        style = 'frame_action_button',
                        sprite = 'utility/close',
                        hovered_sprite = 'utility/close_black',
                        clicked_sprite = 'utility/close_black',
                        mouse_button_filter = { 'left' },
                        handler = { [defines.events.on_gui_click] = gui_events.onWindowClosed },
                    },
                },
            }, -- Title Bar End
            {  -- Body
                type = 'frame',
                style = 'entity_frame',
                style_mods = {
                    natural_width = 400,
                    maximal_height = max_height,
                },
                children = {
                    {
                        type = 'flow',
                        style = 'two_module_spacing_vertical_flow',
                        direction = 'vertical',
                        children = {
                            {
                                type = 'flow',
                                direction = 'horizontal',
                                style_mods = {
                                    vertical_align = 'center',
                                },
                                children = {
                                    {
                                        type = 'label',
                                        style = 'semibold_label',
                                        caption = { const:locale('limit-dropdown-label') },
                                        style_mods = {
                                            right_padding = 8,
                                        },
                                    },
                                    {
                                        type = 'drop-down',
                                        name = 'limit',
                                        handler = { [defines.events.on_gui_selection_state_changed] = gui_events.onLimitChanged },
                                        items = {
                                            [const.limit_dropdown.all] = { const:locale('limit-dropdown-all') },
                                            [const.limit_dropdown.show10] = { const:locale('limit-dropdown-show10') },
                                            [const.limit_dropdown.show25] = { const:locale('limit-dropdown-show25') },
                                        },
                                    },
                                    {
                                        type = 'empty-widget',
                                        style_mods = {
                                            horizontally_stretchable = true,
                                            horizontally_squashable = true,
                                        },
                                    },
                                    {
                                        type = 'label',
                                        style = 'semibold_label',
                                        caption = { const:locale('filter-dropdown-label') },
                                        style_mods = {
                                            right_padding = 8,
                                        },
                                    },
                                    {
                                        type = 'drop-down',
                                        name = 'filter-field',
                                        handler = { [defines.events.on_gui_selection_state_changed] = gui_events.onFilterFieldChanged },
                                        items = {
                                            [const.filter_dropdown.id] = { const:locale('filter-' .. Sorting.sorting.train_id) },
                                            [const.filter_dropdown.name] = { const:locale('filter-' .. Sorting.sorting.train_name) },
                                            [const.filter_dropdown.last_station] = { const:locale('filter-' .. Sorting.sorting.last_station) },
                                            [const.filter_dropdown.current_station] = { const:locale('filter-' .. Sorting.sorting.current_station) },
                                            [const.filter_dropdown.next_station] = { const:locale('filter-' .. Sorting.sorting.next_station) },
                                            [const.filter_dropdown.state] = { const:locale('filter-' .. Sorting.sorting.state) },
                                        },
                                    },
                                    {
                                        type = 'textfield',
                                        name = 'filter-text',
                                        lose_focus_on_confirm = true,
                                        icon_selector = true,
                                        handler = { [defines.events.on_gui_text_changed] = gui_events.onFilterTextChanged, },
                                    },
                                },
                            },
                            {
                                type = 'frame',
                                style = 'framework_tabbed_pane_parent',
                                children = {
                                    {
                                        type = 'tabbed-pane',
                                        style = 'tabbed_pane_with_extra_padding',
                                        name = 'main_tab',
                                        handler = { [defines.events.on_gui_selected_tab_changed] = gui_events.onTabChanged },
                                        children = children,
                                    }, -- tabbed pane
                                },     -- children
                            },         -- frame
                        },             -- children
                    },                 -- flow
                },                     -- children
            },                         -- body
        },                             -- children
    }                                  -- main
end

----------------------------------------------------------------------------------------------------
-- UI Callbacks
----------------------------------------------------------------------------------------------------

--- close the UI (button or shortcut key)
---
---@param event EventData.on_gui_click|EventData.on_gui_closed
function Gui.onWindowClosed(event)
    local player = assert(Player.get(event.player_index))
    Gui.closeGui(player)
end

---@param event EventData.on_gui_selected_tab_changed
function Gui.onTabChanged(event)
    local gui = assert(Framework.gui_manager:find_gui(event.player_index))

    local tab_index = event.element.selected_tab_index
    local tab = assert(event.element.tabs[tab_index])
    local entity_type = assert(tab.tab.tags.entity_type)

    ---@type tt.PlayerStorage
    local player_data = assert(Player.pdata(gui.player_index))
    -- player_data.tab always holds the current entity type
    player_data.tab = entity_type

    local tab_state = assert(player_data.tab_state[entity_type])
    tab_state.tab_index = tab_index

    local filter_text = assert(gui:find_element('filter-text'))
    filter_text.text = tab_state.search or ''

    ---@type tt.GuiContext
    local context = gui.context
    context.pacer = 0
end

---@param event EventData.on_gui_checked_state_changed
function Gui.onSort(event)
    local gui = assert(Framework.gui_manager:find_gui(event.player_index))

    ---@type tt.PlayerStorage
    local player_data = assert(Player.pdata(gui.player_index))

    local entity_type = assert(player_data.tab)
    return Gui.gui_panes[entity_type].onSort(event, gui)
end

---@param event EventData.on_gui_click
function Gui.onClickEntity(event)
    local gui = assert(Framework.gui_manager:find_gui(event.player_index))

    ---@type tt.PlayerStorage
    local player_data = assert(Player.pdata(gui.player_index))

    local entity_type = assert(player_data.tab)
    return Gui.gui_panes[entity_type].onClickEntity(event, gui)
end

---@param event EventData.on_gui_click
function Gui.onClickLastStation(event)
    local gui = assert(Framework.gui_manager:find_gui(event.player_index))

    ---@type tt.PlayerStorage
    local player_data = assert(Player.pdata(gui.player_index))

    local entity_type = assert(player_data.tab)
    return Gui.gui_panes[entity_type].onClickLastStation(event, gui)
end

---@param event EventData.on_gui_click
function Gui.onClickCurrentStation(event)
    local gui = assert(Framework.gui_manager:find_gui(event.player_index))

    ---@type tt.PlayerStorage
    local player_data = assert(Player.pdata(gui.player_index))

    local entity_type = assert(player_data.tab)
    return Gui.gui_panes[entity_type].onClickCurrentStation(event, gui)
end

---@param event EventData.on_gui_click
function Gui.onClickNextStation(event)
    local gui = assert(Framework.gui_manager:find_gui(event.player_index))

    ---@type tt.PlayerStorage
    local player_data = assert(Player.pdata(gui.player_index))

    local entity_type = assert(player_data.tab)
    return Gui.gui_panes[entity_type].onClickNextStation(event, gui)
end

---@param event EventData.on_gui_selection_state_changed
function Gui.onLimitChanged(event)
    local gui = assert(Framework.gui_manager:find_gui(event.player_index))

    ---@type tt.PlayerStorage
    local player_data = assert(Player.pdata(gui.player_index))

    local tab_state = assert(player_data.tab_state[player_data.tab])

    tab_state.limit = event.element.selected_index --[[@as tt.limit_dropdown ]]
    gui.context.pacer = 0 -- force refresh
end

---@param event EventData.on_gui_selection_state_changed
function Gui.onFilterFieldChanged(event)
    local gui = assert(Framework.gui_manager:find_gui(event.player_index))

    ---@type tt.PlayerStorage
    local player_data = assert(Player.pdata(gui.player_index))

    local entity_type = player_data.tab
    local tab_state = assert(player_data.tab_state[entity_type])

    tab_state.filter = event.element.selected_index --[[@as tt.filter_dropdown ]]
    tab_state.search = ''

    local filter_text = assert(gui:find_element('filter-text'))
    filter_text.text = tab_state.search

    gui.context.pacer = 0 -- force refresh
end

---@param event EventData.on_gui_text_changed
function Gui.onFilterTextChanged(event)
    local gui = assert(Framework.gui_manager:find_gui(event.player_index))

    ---@type tt.PlayerStorage
    local player_data = assert(Player.pdata(gui.player_index))

    local tab_state = assert(player_data.tab_state[player_data.tab])

    tab_state.search = event.text

    gui.context.pacer = 0 -- force refresh
end

----------------------------------------------------------------------------------------------------
-- open gui handler
----------------------------------------------------------------------------------------------------

--- @param player LuaPlayer
function Gui.openGui(player)
    -- close an eventually open gui
    Framework.gui_manager:destroy_gui(player.index)

    ---@type tt.PlayerStorage
    local player_data = assert(Player.pdata(player.index))

    player_data.tab_state = player_data.tab_state or {}

    for _, entity_type in pairs(const.entity_types) do
        if Gui.gui_panes[entity_type] then
            player_data.tab_state[entity_type] = player_data.tab_state[entity_type] or Gui.gui_panes[entity_type].init()
        else
            player_data.tab_state[entity_type] = nil
        end
    end

    -- player_data.tab always holds the current entity_type
    player_data.tab = player_data.tab or const.entity_types.trains

    ---@class tt.GuiContext
    ---@field pacer integer
    local gui_state = {
        pacer = 0,
    }

    Framework.gui_manager:create_gui {
        type = Gui.NAME,
        player_index = player.index,
        parent = player.gui.screen,
        ui_tree_provider = Gui.getUi,
        context = gui_state,
    }

    player_data.toggle = true
end

function Gui.closeGui(player)
    ---@type tt.PlayerStorage
    local player_data = assert(Player.pdata(player.index))
    Framework.gui_manager:destroy_gui(player.index)

    player_data.toggle = false
end

----------------------------------------------------------------------------------------------------
-- Event ticker
----------------------------------------------------------------------------------------------------

---@param gui framework.gui
---@return boolean
function Gui.guiUpdater(gui)
    ---@type tt.PlayerStorage?
    local player_data = Player.pdata(gui.player_index)
    if not player_data then return false end
    ---@type tt.GuiPane?
    local gui_pane = Gui.gui_panes[player_data.tab]
    if not gui_pane then return false end

    ---@type tt.TabState
    local tab_state = assert(player_data.tab_state[player_data.tab])

    -- update shared fields

    local limit = assert(gui:find_element('limit'))
    limit.selected_index = tab_state.limit or const.limit_dropdown.all

    local filter_field = assert(gui:find_element('filter-field'))
    filter_field.selected_index = tab_state.filter or const.filter_dropdown.id

    local filter_text = assert(gui:find_element('filter-text'))
    if filter_text.text ~= tab_state.search then
        filter_text.text = tab_state.search
    end

    -- end update shared fields

    tab_state.tab_index = tab_state.tab_index or 1

    ---@type LuaGuiElement
    local main_tab = assert(gui:find_element('main_tab'))
    if not main_tab.selected_tab_index then
        main_tab.selected_tab_index = tab_state.tab_index
    end

    local tab_name = assert(main_tab.tabs[tab_state.tab_index].tab.tags.tab_name)

    if not gui_pane.updateGuiPane(gui, tab_name) then return false end

    ---@type tt.GuiContext
    local context = gui.context

    if context.pacer <= 0 then
        context.pacer = 11 -- 11 * 11 = 121 ticks ~ 2 sec
        -- 55 * 11 = 605 ticks ~ 10 sec
        if not gui_pane.refreshGuiPane(gui, tab_name) then return false end
    else
        context.pacer = context.pacer - 1
    end

    return true
end

----------------------------------------------------------------------------------------------------
-- Event registration
----------------------------------------------------------------------------------------------------

local function toggle_hotkey(event)
    ---@type LuaPlayer, tt.PlayerStorage
    local player, player_data = Player.get(event.player_index)
    assert(player)
    assert(player_data)

    player_data.toggle = player_data.toggle or false

    if player_data.toggle then
        Gui.closeGui(player)
    else
        Gui.openGui(player)
    end
end


local function init_gui()
    Framework.gui_manager:register_gui_type(Gui.NAME, get_gui_event_definition())
    Event.on_event(const.hotkey_names.toggle_display, toggle_hotkey)
end

Event.on_init(init_gui)
Event.on_load(init_gui)

return Gui
