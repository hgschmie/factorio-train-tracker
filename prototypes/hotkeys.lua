--------------------------------------------------------------------------------
-- hotkey definition
--------------------------------------------------------------------------------

local const = require('lib.constants')

data:extend {
    {
        type = 'custom-input',
        name = const.hotkey_names.toggle_display,
        localised_name = { const:locale(const.hotkey.toggle_display) },
        key_sequence = 'CONTROL + SHIFT + T'
    },
}
