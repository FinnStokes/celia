-- event.lua
local M = {}

local manager = {
  events = {}
}

M.notify = function(event, data)
  if not manager.events[event] then return end
  for _,callback in ipairs(manager.events[event]) do
    callback(data)
  end
end

M.subscribe = function(event, callback)
  if not manager.events[event] then
    manager.events[event] = {}
  end
  table.insert(manager.events[event], callback)
end

M.unsubscribe = function(event, callback)
  if manager.events[event] then
    local del = -1
    for i,c in ipairs(manager.events[event]) do
      if c == callback then
        del = i
      end
    end
    if del ~= -1 then
      table.remove(manager.events[event],del)
    end
  end
end

return M
