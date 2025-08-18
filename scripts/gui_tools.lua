------------------------------------------------------------------------
-- Gui Helpers / tools
------------------------------------------------------------------------

local const = require('lib.constants')

---@class tt.GuiTools
local GuiTools = {}

---@param gui framework.gui
---@param prefix string Name prefix to separate gui element names
---@param event_name string The event from the gui events list to use for this checkbox
---@param tab_state tt.TabState The sort state to render for
---@param sort_value string sorted value constant
---@param locale string? optional locale id, otherwise use the sort_value
---@return framework.gui.element_definition
function GuiTools.renderCheckbox(gui, prefix, event_name, tab_state, sort_value, locale)
    local gui_events = gui.gui_events
    local style = (tab_state.sort == sort_value) and 'tt_selected_sort_checkbox' or 'tt_sort_checkbox'

    tab_state.sort_mode[sort_value] = tab_state.sort_mode[sort_value] or false

    local locale_key = ('%s.%s'):format(prefix, (locale or sort_value))

    return {
        type = 'checkbox',
        style = style,
        name = 'check-' .. prefix .. '-' .. sort_value,
        caption = { const:locale(locale_key) },
        handler = { [defines.events.on_gui_checked_state_changed] = gui_events[event_name] },
        state = tab_state.sort_mode[sort_value],
        tooltip = { const:locale('tooltip_' .. locale_key) },
        elem_tags = {
            value = sort_value,
            entity_type = prefix,
        },
        style_mods = {
            horizontal_align = 'center',
        },
    }
end

---@param checkbox LuaGuiElement
---@param tab_state tt.TabState
function GuiTools.updateCheckbox(checkbox, tab_state)
    local style = (tab_state.sort == checkbox.tags.value) and 'tt_selected_sort_checkbox' or 'tt_sort_checkbox'
    local sort = tab_state.sort_mode[checkbox.tags.value] or false
    checkbox.style = style
    checkbox.state = sort
end

return GuiTools
