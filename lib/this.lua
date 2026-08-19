----------------------------------------------------------------------------------------------------
--- Initialize this mod's globals
----------------------------------------------------------------------------------------------------

local const = require('lib.constants')

---@class tt.FreightItem
---@field type 'item'|'fluid'
---@field name string
---@field quality string?
---@field count number

---@alias tt.Freight table<string, tt.FreightItem>

---@class tt.TrainInfo
---@field last_state defines.train_state?      Last state seen for the train. Updated continously
---@field last_station LuaEntity?              Last observed stop
---@field current_station LuaEntity?           Current train stop
---@field current_is_temporary boolean?
---@field current_signal LuaEntity?            Current signal where the train stops
---@field current_distance number?             Total distance that the train will travel between two stops
---@field next_station (LuaEntity|string)?     Next station anticipated
---@field last_tick integer                    Last recorded event tick
---@field last_tick_state defines.train_state? Train state when the last event tick was recorded. Different from last_state
---@field total_distance number                Total distance stat (in ticks)
---@field total_runtime integer                Total runtime stat (in ticks)
---@field total_waittime integer               Total wait time stat (in ticks)
---@field signal_waittime integer              Total signal wait time stat (in ticks)
---@field stop_waittime integer                Total stop wait time stat (in ticks)
---@field train_name string?                   Current train name
---@field train_id integer                     Current train id
---@field current_freight tt.Freight           Current freight on the train
---@field total_freight tt.Freight             Total freight moved by the train
---@field total_stop_count integer?            Number of times stopped at train stop
---@field total_signal_count integer?          Number of times stopped at a signal
---@field lock_time integer?                   Lock timestamp to protect from deletion (needed for teleport)

---@class tt.Ticker
---@field entity_type string?
---@field last_tick_index integer?

---@class tt.Storage
---@field trains table<integer, tt.TrainInfo>
---@field ships table<integer, tt.TrainInfo>
---@field ticker tt.Ticker

---@class tt.Mod
---@field other_mods table<string, string>
---@field settings ff2.ModSettings
---@field TrainTracker tt.TrainTracker
---@field Console tt.Console
---@field Gui tt.Gui
local This = {
    remote_apis = {
        ['space-exploration'] = 'space-exploration',
    },
    settings = require('lib.settings')
}

function This.boot()
    This.TrainTracker = require('scripts.train-tracker')
    This.Console = require('scripts.console')
    This.Gui = require('scripts.gui')
end

--------------------------------------------------------------------------------
-- Framework intializer
--------------------------------------------------------------------------------

---@return FrameworkConfig config
function This.framework_init()
    return {
        -- prefix is the internal mod prefix
        prefix = const.prefix,
        -- prefix for log messages
        log_prefix = const.log_prefix,
        -- name is a human readable name
        name = const.name,
        -- The filesystem root.
        root = const.root,
    }
end

--- Setup the global data structures
function This:init()
    -- init data
    if not storage.tt_data then
        ---@type tt.Storage
        storage.tt_data = {
            trains = {},
            ships = {},
            ticker = {},
        }
    end
end

---@return tt.Storage
function This.storage()
    return assert(storage.tt_data)
end

return This
