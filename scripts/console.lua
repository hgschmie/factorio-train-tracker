--------------------------------------------------------------------------------
-- custom commands
--------------------------------------------------------------------------------
assert(script)

local Event = require('stdlib.event.event')

local const = require('lib.constants')

--------------------------------------------------------------------------------

---@class tt.Console
local Console = {}

---@param data CustomCommandData
local function clear_train_tracker(data)
    local cleared_count = 0
    local skipped_count = 0
    for _, entity_type in pairs(const.entity_types) do
        for train_id in pairs(This.TrainTracker:entities(entity_type)) do
            if This.TrainTracker:clearEntity(entity_type, train_id) then
                cleared_count = cleared_count + 1
            else
                skipped_count = skipped_count + 1
            end
        end
    end
    Framework.logger.console(function()
        return { const:locale('command_clear_train_tracker_result'), cleared_count, skipped_count }
    end, data)
end

function Console.register_commands()
    commands.add_command('clear-train-tracker', { const:locale('command_clear_train_tracker') }, clear_train_tracker)
end

--------------------------------------------------------------------------------
-- mod init/load code
--------------------------------------------------------------------------------

local function on_init()
    Console:register_commands()
end

local function on_load()
    Console.register_commands()
end

Event.on_init(on_init)
Event.on_load(on_load)

return Console
