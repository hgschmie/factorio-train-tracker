------------------------------------------------------------------------
-- mod settings
------------------------------------------------------------------------

local const = require('lib.constants')

---@type ff2.ModSettings
local Settings = {
    startup = {
        [const.settings_names.use_named_temp_stops] = {
            key = const.settings.use_named_temp_stops,
            value = false
        },
    }
}

return Settings
