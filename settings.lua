------------------------------------------------------------------------
-- settings code
------------------------------------------------------------------------

This, Framework = require('lib.init')()

local const = require('lib.constants')

local framework_settings = {
    {
        -- Debug mode (framework dependency)
        type = 'string-setting',
        name = Framework.PREFIX .. 'debug-mode',
        order = 'az',
        setting_type = 'startup',
        default_value = '0',
        allowed_values = { '0', '1', '2', '3' },
    },
    {
        type = 'bool-setting',
        name = const.settings.use_named_temp_stops,
        setting_type = 'startup',
        default_value = false,
        order = 'a',
    },
}

data:extend(framework_settings)

---@diagnostic disable-next-line: undefined-field
Framework.post_settings_stage()
