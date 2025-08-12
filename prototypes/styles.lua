--------------------------------------------------------------------------------
-- custom gui styles
--------------------------------------------------------------------------------

local util = require('util')

if not data.raw['gui-style'] then return end

local styles = data.raw['gui-style'].default

local empty_checkmark = {
    filename = '__core__/graphics/empty.png',
    priority = 'very-low',
    width = 1,
    height = 1,
    frame_count = 1,
    scale = 8,
}

styles.tt_sort_checkbox = {
    type = 'checkbox_style',
    font = 'default-bold',
    padding = 0,
    default_graphical_set = {
        filename = '__core__/graphics/arrows/table-header-sort-arrow-down-white.png',
        size = { 16, 16 },
        scale = 0.5,
    },
    hovered_graphical_set = {
        filename = '__core__/graphics/arrows/table-header-sort-arrow-down-white.png',
        tint = { 0, 1, 0 },
        size = { 16, 16 },
        scale = 0.5,
    },
    clicked_graphical_set = {
        filename = '__core__/graphics/arrows/table-header-sort-arrow-down-white.png',
        tint = { 0, 1, 0 },
        size = { 16, 16 },
        scale = 0.5,
    },
    disabled_graphical_set = {
        filename = '__core__/graphics/arrows/table-header-sort-arrow-down-white.png',
        size = { 16, 16 },
        scale = 0.5,
    },
    selected_graphical_set = {
        filename = '__core__/graphics/arrows/table-header-sort-arrow-up-white.png',
        size = { 16, 16 },
        scale = 0.5,
    },
    selected_hovered_graphical_set = {
        filename = '__core__/graphics/arrows/table-header-sort-arrow-up-white.png',
        tint = { 1, 0, 0 },
        size = { 16, 16 },
        scale = 0.5,
    },
    selected_clicked_graphical_set = {
        filename = '__core__/graphics/arrows/table-header-sort-arrow-up-white.png',
        tint = { 1, 0, 0 },
        size = { 16, 16 },
        scale = 0.5,
    },
    selected_disabled_graphical_set = {
        filename = '__core__/graphics/arrows/table-header-sort-arrow-up-white.png',
        size = { 16, 16 },
        scale = 0.5,
    },
    checkmark = empty_checkmark,
    disabled_checkmark = empty_checkmark,
    text_padding = 5,
}

styles.tt_selected_sort_checkbox = {
    type = 'checkbox_style',
    parent = 'tt_sort_checkbox',
    default_graphical_set = {
        filename = '__core__/graphics/arrows/table-header-sort-arrow-down-white.png',
        tint = { 0, 1, 0 },
        size = { 16, 16 },
        scale = 0.5,
    },
    selected_graphical_set = {
        filename = '__core__/graphics/arrows/table-header-sort-arrow-up-white.png',
        tint = { 1, 0, 0 },
        size = { 16, 16 },
        scale = 0.5,
    },
}

local default_color = {
    r = 1, g = 0.5, b = 0,
}

local hovered_color = {
    r = 0.75, g = 0.375, b = 0,
}

styles.tt_clickable_label = {
    type = 'label_style',
    parent = 'semibold_label',
    underlined = true,
    font_color = default_color,
    hovered_font_color = hovered_color,
    clicked_font_color = hovered_color,
}
