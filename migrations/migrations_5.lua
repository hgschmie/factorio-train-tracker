------------------------------------------------------------------------
-- debug migrations
------------------------------------------------------------------------

This = require('lib.this')

local const = require('lib.constants')

This.TrainTracker:init()

for entity_type in pairs(const.entity_types) do
    if storage.tt_data[entity_type] then
        for _, train_info in pairs(storage.tt_data[entity_type]) do
            train_info.total_freight = train_info.total_freight or {}
        end
    end
end

This.TrainTracker:resync()
