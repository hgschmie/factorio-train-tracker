--
-- Migrate framework gui stuff. Needed to adopt the multi-gui GUI manager
--

local const = require('lib.constants')

-- Framework core
require('framework.init'):init(const.framework_init)

local runtime_storage = Framework.runtime:storage()
if not runtime_storage.gui_manager then return end

local state = runtime_storage.gui_manager

---@type table<number, framework.gui>
local old_guis = state.guis

state.guis = {}
for _, gui in pairs(old_guis) do
    Framework.gui_manager:addGui(gui.player_index, gui)
end

runtime_storage.gui_manager = nil
