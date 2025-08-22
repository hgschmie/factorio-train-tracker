------------------------------------------------------------------------
-- debug migrations
------------------------------------------------------------------------

local const = require('lib.constants')

This = require('lib.this')

This.TrainTracker:init()

-- fix up missing ships array
if not storage.tt_data.ships then storage.tt_data.ships = {} end

local trains = {}

for _, train in pairs(game.train_manager.get_trains {}) do
    trains[train.id] = train
end

-- fix up missing fields, remove invalid trains
for train_id, train in pairs(storage.tt_data.trains) do
    if  trains[train_id] then
        train.train_name = assert(const.getMainLocomotive(trains[train_id])).backer_name
        train.train_id = train_id
        train.signal_waittime = train.signal_waittime or 0
        train.stop_waittime = train.stop_waittime or 0
    else
        train[train_id] = nil
    end
end

-- move mislabeled ships to the ship array
for _, train in pairs(trains) do
    local entity_type = This.TrainTracker:determineEntityType(train)
    if entity_type ~= 'trains' and storage.tt_data.trains[train.id] then
        storage.tt_data[entity_type][train.id] = storage.tt_data.trains[train.id]
        storage.tt_data.trains[train.id] = nil
    end
end

This.TrainTracker:resync()
