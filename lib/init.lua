----------------------------------------------------------------------------------------------------
--- Global definitions included in all phases
----------------------------------------------------------------------------------------------------

-- mod code
local this = require('lib.this')

-- Framework core
local framework = require('framework.init')
framework:init(this.framework_init)

framework.settings:add_defaults(this.settings)

---@cast script LuaBootstrap?
if script then
    this.boot()
end

return function()
    return this, framework
end
