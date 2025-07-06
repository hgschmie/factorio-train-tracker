----------------------------------------------------------------------------------------------------
--- Initialize this mod's globals
----------------------------------------------------------------------------------------------------

---@class tt.Mod
---@field other_mods table<string, string>
---@field TrainTracker tt.TrainTracker?
local This = {
    other_mods = {},
}

if (script) then
    This.TrainTracker = require('scripts.train-tracker')
end

----------------------------------------------------------------------------------------------------
return This
