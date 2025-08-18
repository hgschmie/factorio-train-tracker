------------------------------------------------------------------------
-- debug migrations
------------------------------------------------------------------------

This = require('lib.this')

require('stdlib.utils.string')

local const = require('lib.constants')

This.TrainTracker:init()

---@param freight tt.Freight?
---@return tt.Freight?
local function fix_freight(freight)
    if not freight then return freight end

    ---@type tt.Freight
    local new_freight = {}
    for key, item in pairs(freight) do
        if type(freight) ~= 'table' then
            local result = {
                count = item
            }

            if key:contains('__') then
                result.type = 'item'
                local parts = key:split('__')
                assert(#parts == 2)
                result.name = parts[1]
                result.quality = parts[2]
            else
                result.type = 'fluid'
                result.name = key
            end
            new_freight[key] = result
        else
            new_freight[key] = item
            new_freight[key].type = new_freight[key].quality and 'item' or 'fluid'
        end
    end
    return new_freight
end

for entity_type in pairs(const.entity_types) do
    if storage.tt_data[entity_type] then
        for _, train_info in pairs(storage.tt_data[entity_type]) do
            train_info.total_freight = fix_freight(train_info.total_freight)
            train_info.current_freight = fix_freight(train_info.current_freight)
        end
    end
end

This.TrainTracker:resync()
