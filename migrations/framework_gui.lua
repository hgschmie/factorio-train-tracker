--
-- Migrate framework gui stuff. Needed to adopt the multi-gui GUI manager
--

local const = require('lib.constants')

-- Framework core
require('framework.init'):init(const.framework_init)

local state = Framework.gui_manager:state()

---@type table<number, framework.gui>
local old_guis = state.guis

state.guis = {}
for _, gui in pairs(old_guis) do
    Framework.gui_manager:addGui(gui.player_index, gui.type, gui)
end
