----------------------------------------------------------------------------------------------------
--- Initialize this mod's globals
----------------------------------------------------------------------------------------------------

---@class tt.Mod
---@field other_mods table<string, string>
---@field TrainTracker tt.TrainTracker?
---@field Console tt.Console?
---@field Gui tt.Gui?
local This = {
    other_mods = {},
}

if (script) then
    This.TrainTracker = require('scripts.train-tracker')
    This.Console = require('scripts.console')
    This.Gui = require('scripts.gui')
end

----------------------------------------------------------------------------------------------------
return This
