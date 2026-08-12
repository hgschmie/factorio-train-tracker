--------------------------------------------------------------------------------
-- shortcut bar definition
--------------------------------------------------------------------------------

local const = require('lib.constants')

data:extend {
    ---@type ShortcutPrototype
    {
        type = 'shortcut',
        name = const.hotkey_names.toggle_display,
        order = 'z[train-tracker]',
        action = 'lua',
        toggleable = true,
        associated_control_input = const.hotkey_names.toggle_display,
        icon = const:png('icons/train'),
        icon_size = 64,
        icon_mipmaps = 4,
        small_icon = const:png('icons/train'),
        small_icon_size = 64,
        small_icon_mipmaps = 4,
    },
}
