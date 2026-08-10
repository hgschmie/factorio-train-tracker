------------------------------------------------------------------------
-- settings code
------------------------------------------------------------------------

This, Framework = require('lib.init')()

local const = require('lib.constants')

local framework_settings = {
    {
        -- Debug mode (framework dependency)
        type = 'bool-setting',
        name = Framework.PREFIX .. 'debug-mode',
        order = 'z',
        setting_type = 'startup',
        default_value = false,
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
