------------------------------------------------------------------------
-- Sorted tree implementation
------------------------------------------------------------------------

---@class TreeNode
---@field left TreeNode?
---@field right TreeNode?
---@field value any?

---@class Tree
---@field comparator fun(a: any, b: any): integer
---@field root TreeNode
---@field add (fun(self: Tree, value: any))?
---@field traverse (fun(self: Tree, sink: (fun(value: any): boolean), limit: number?))?


local Tree_MT = {}

Tree_MT.__index = function(t, k)
    return Tree_MT[k]
end

---@return Tree
function Tree_MT.create(comparator, reverse)
    ---@type Tree
    local tree_root = {
        comparator = comparator,
        reverse = reverse,
        root = {}
    }
    setmetatable(tree_root, Tree_MT)
    return tree_root
end

---@value any
function Tree_MT:add(value)
    assert(value)
    self:add_node(self.root, value)
end

---@param node TreeNode
---@value any
function Tree_MT:add_node(node, value)
    if not node.value then
        node.value = value
        return
    end

    local result = self.comparator(value, node.value)
    if self.reverse then result = -result end

    if result <= 0 then
        if node.left then
            self:add_node(node.left, value)
        else
            node.left = {
                value = value
            }
        end
    else
        if node.right then
            self:add_node(node.right, value)
        else
            node.right = {
                value = value
            }
        end
    end
end

---@param callback fun(value: any): boolean
---@param limit number?
function Tree_MT:traverse(callback, limit)
    assert(callback)
    limit = limit or -1
    return Tree_MT:traverse_tree(self.root, callback, limit)
end

---@param node TreeNode
---@param callback fun(value: any): boolean
---@param limit number
---@return number new_limit
function Tree_MT:traverse_tree(node, callback, limit)
    if limit == 0 then return 0 end
    if node.left then limit = self:traverse_tree(node.left, callback, limit) end

    if limit == 0 then return 0 end
    if node.value and callback(node.value) then limit = limit - 1 end

    if limit == 0 then return 0 end
    if node.right then limit = self:traverse_tree(node.right, callback, limit) end

    return limit
end

return Tree_MT
