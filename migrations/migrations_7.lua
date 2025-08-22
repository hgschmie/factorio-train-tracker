------------------------------------------------------------------------
-- debug migrations
------------------------------------------------------------------------

This = require('lib.this')

require('stdlib.utils.string')

local const = require('lib.constants')

This.TrainTracker:init()

---@type table<integer, LuaTrain>
local trains = {}

for _, train in pairs(game.train_manager.get_trains {}) do
    trains[train.id] = train
end

for entity_type in pairs(const.entity_types) do
    if storage.tt_data[entity_type] then
        for train_id, train_info in pairs(storage.tt_data[entity_type]) do
            train_info.total_freight = train_info.total_freight or {}
            if trains[train_id] then
                train_info.current_freight = This.TrainTracker:getFreightFromTrain(trains[train_id])
            else
                train_info.current_freight = {}
            end
        end
    end
end

This.TrainTracker:resync()
