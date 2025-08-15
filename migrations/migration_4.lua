------------------------------------------------------------------------
-- debug migrations
------------------------------------------------------------------------

This = require('lib.this')

local const = require('lib.constants')

This.TrainTracker:init()

---@type table<integer, LuaTrain>
local trains = {}

for _, train in pairs(game.train_manager.get_trains {}) do
    trains[train.id] = train
    script.register_on_object_destroyed(train)
end

for entity_type in pairs(const.entity_types) do
    if storage.tt_data[entity_type] then
        for train_id, train_info in pairs(storage.tt_data[entity_type]) do
            if trains[train_id] then
                if not train_info.current_station and trains[train_id].station then
                    train_info.current_station = trains[train_id].station
                    if train_info.last_station and train_info.last_station.unit_number == train_info.current_station then
                        train_info.last_station = nil
                    end
                end
            else
                train_info[train_id] = nil
            end
        end
    end
end

This.TrainTracker:resync()
