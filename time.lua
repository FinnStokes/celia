local event = require "event"

local M = {}

local time = 0
local list = {}

M.update = function (dt)
  time = time + dt
  print(time)
  local e = list[#list]
  while #list > 0 and e.time <= time do
    print("trigger "..#list)
    list[#list] = nil
    event.notify(e.name, e.data)
    e = list[#list]
  end
end

M.get = function ()
  return time
end

M.delay = function (event, data, dt)
  M.notify(event, data, time+dt)
end

M.notify = function (name, data, time)
  local e = {name=name, data=data, time=time}
  if #list > 0 then
    do i = #list,1
      if e.time < list[i].time then
        table.insert(list,i+1,e)
        print("store "..(i+1))
        return
      end
    end
  end
  table.insert(list,1,e)
  print("store 1")
end

M.reset = function ()
  list = {}
  time = 0
end

return M
