--------------------------------------------------------------------------------
-- custom commands
--------------------------------------------------------------------------------
assert(script)

local Event = require('stdlib.event.event')
local Is = require('stdlib.utils.is')

local const = require('lib.constants')

--------------------------------------------------------------------------------

---@class tt.Console
local Console = {}

---@param data CustomCommandData
local function clear_train_tracker(data)
    for _, entity_type in pairs(const.entity_types) do
        for train_id in pairs(This.TrainTracker:entities(entity_type)) do
            This.TrainTracker:clearEntity(entity_type, train_id)
        end
    end
end

function Console:register_commands()
    commands.add_command('clear-train-tracker', { const:locale('command_clear_train_tracker') }, clear_train_tracker)
end

--------------------------------------------------------------------------------
-- mod init/load code
--------------------------------------------------------------------------------

local function on_init()
    Console:register_commands()
end

local function on_load()
    Console:register_commands()
end

Event.on_init(on_init)
Event.on_load(on_load)

return Console
