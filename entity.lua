-- entity.lua
local state = require "state"
local event = require "event"
local M = {}

local manager = {
  entities = {},
  types = {},
  deleteQueue = {},
}

M.scale = 1;

M.new = function (arg)
  -- Default properties
  local self = {
    width = 30,
    height = 30,
    position = {x = 0, y = 0},
    velocity = {x = 0, y = 0},
    acceleration = {x = 0, y = 0},
    inset = 0,
    friction = 0,
    scaled = true,
    dynamic = false,
  }
  
  -- Add type-specific properties and defaults
  if arg.type then
    local type = manager.types[arg.type]
    if type then
      for k,v in pairs(type) do
        self[k] = v
      end
    end
  end
  
  -- Instance-specific default overrides
  for k,v in pairs(arg) do
    self[k] = v
  end
  
  local collide = function (map, x1, y1, x2, y2)
    local i1 = map.getTileIndices({x = x1, y = y1})
    local i2 = map.getTileIndices({x = x2, y = y2})
    for x=i1.x,i2.x do
      for y=i1.y,i2.y do
        if map.getTileProperties({x = x, y = y}).solid == true then
          return true
        end
      end
    end
    return false
  end
  
  if not self.collisionRect then
    self.collisionRect = { left = self.inset*self.width, top = self.inset*self.height,
                           right = (1-self.inset)*self.width, bottom = (1-self.inset)*self.height }
  end
  
  local object = {}
  object.type = arg.type
  object.falling = true
  object.transforming = false
  object.delete = false
  object.setAnimation = function (anim, lowPriority)
    self.setAnimation(object, self, anim, lowPriority)
  end
  if self.render then
    object.render = function () 
      self.render(object, self)
    end
  else
    object.render = function ()
      love.graphics.setColor({0,255,0})
      local position = object.getPosition()
      love.graphics.rectangle("fill", position.x, position.y, object.width(), object.height())
    end
  end
  object.update = function (dt)
    if self.dynamic then
      self.position.y = self.position.y + dt*(self.velocity.y + self.acceleration.y*dt/2)
      self.velocity.y = self.velocity.y + dt*(self.acceleration.y - self.friction*self.velocity.y)
      local map = state.get().map
      local rect = object.getCollisionRect()
      local width = object.width()
      local height = object.height()
      local verticalStuck = false
      local horizontalStuck = false
      if map then
        -- Vertical collisions
        if self.velocity.y < 0 or object.transforming then
          if collide(map, rect.left + 1, rect.top, rect.right - 1, rect.top) then
            self.position.y = (map.getTileBounds(map.getTileIndices({x = rect.left, y = rect.top})).bottom) - self.collisionRect.top
            --if self.scaled then
            self.position.y = self.position.y/M.scale + 1
            --end
            self.velocity.y = 0
            if collide(map, rect.left + 1, rect.bottom, rect.right - 1, rect.bottom) then
              verticalStuck = true
            end
          end
        end
        if self.velocity.y > 0 or object.transforming then
          if collide(map, rect.left + 1, rect.bottom, rect.right - 1, rect.bottom) then
            self.position.y = (map.getTileBounds(map.getTileIndices({x = rect.left, y = rect.bottom})).top) - self.collisionRect.bottom
            --if self.scaled then
            self.position.y = self.position.y/M.scale
            --end
            self.velocity.y = 0
            object.falling = false
            if collide(map, rect.left + 1, rect.top, rect.right - 1, rect.top) then
              verticalStuck = true
            end
          else
            object.falling = true
          end
        end
        
        self.position.x = self.position.x + dt*(self.velocity.x + dt*self.acceleration.x/2)
        self.velocity.x = self.velocity.x + dt*self.acceleration.x
        rect = object.getCollisionRect()
        -- Horizontal collisions
        if self.velocity.x < 0 or object.transforming then
          if collide(map, rect.left, rect.top, rect.left, rect.bottom - 1) then
            self.position.x = (map.getTileBounds(map.getTileIndices({x = rect.left, y = rect.top})).right) - self.collisionRect.left
            --if self.scaled then
            self.position.x = self.position.x/M.scale
            --end
            --velocity.x = 0
            if collide(map, rect.right, rect.top, rect.right, rect.bottom - 1) then
              event.notify("entityStuck",object)
              horizontalStuck = true
            end
          end
        end
        if self.velocity.x > 0 or object.transforming then
          if collide(map, rect.right, rect.top, rect.right, rect.bottom - 1) then
            self.position.x = (map.getTileBounds(map.getTileIndices({x = rect.right, y = rect.top})).left) - self.collisionRect.right
            --if self.scaled then
            self.position.x = self.position.x/M.scale
            --end
            --self.velocity.x = 0
            if not horizontalStuck and collide(map, rect.left, rect.top, rect.left, rect.bottom - 1) then
              event.notify("entityStuck",object)
              horizontalStuck = true
            end
          end
        end
        if verticalStuck and not horizontalStuck and
           collide(map, rect.left + 1, rect.top,    rect.right - 1, rect.top) and
           collide(map, rect.left + 1, rect.bottom, rect.right - 1, rect.bottom) then
           event.notify("entityStuck",object)
        end
      end
      
      if self.position.x < 0 then
        self.position.x = self.position.x + map.width()
      end
      if self.position.x > map.width() then
        self.position.x = self.position.x - map.width()
      end
      if self.position.y < 0 then
        self.position.y = self.position.y + map.height()
      end
      if self.position.y > map.height() then
        self.position.y = self.position.y - map.height()
      end
    end

    --moved type specific update to end. this may cause problems with friction/variable
    if self.update then
      self.update(object, self, dt)
    end
  end
  -- object.scale = function (s)
  --   self.scale = self.scale*s
  --   self.position.x = self.position.x*s
  --   self.position.y = self.position.y*s
  --   self.velocity.x = self.velocity.x*s
  --   self.velocity.y = self.velocity.y*s
  --   self.acceleration.x = self.acceleration.x*s
  --   self.acceleration.y = self.acceleration.y*s
  --   self.width = self.width*s
  --   self.height = self.height*s
  -- end
  object.position = function (arg)
    arg = arg or {} 
    if arg.x then
        self.position.x = arg.x/M.scale
    end
    if arg.y then
        self.position.y = arg.y/M.scale
    end
    local map = state.get().map
    if self.position.x < 0 then
      self.position.x = self.position.x + map.width()
    end
    if self.position.x > map.width() then
      self.position.x = self.position.x - map.width()
    end
    if self.position.y < 0 then
      self.position.y = self.position.y + map.height()
    end
    if self.position.y > map.height() then
      self.position.y = self.position.y - map.height()
    end
    return {x=self.position.x*M.scale,y=self.position.y*M.scale}
  end
  object.getPosition = function ()
    return {x=self.position.x*M.scale,y=self.position.y*M.scale}
  end
  object.getCollisionRect = function ()
    if self.scaled then
      local l = self.collisionRect.left + self.position.x
      local t = self.collisionRect.top + self.position.y
      local r = self.collisionRect.right + self.position.x
      local b = self.collisionRect.bottom + self.position.y
      return {left = l*M.scale, top = t*M.scale, right = r*M.scale, bottom = b*M.scale}
    else
      local x = self.position.x*M.scale
      local y = self.position.y*M.scale
      local l = self.collisionRect.left + x
      local t = self.collisionRect.top + y
      local r = self.collisionRect.right + x
      local b = self.collisionRect.bottom + y
      return {left = l, top = t, right = r, bottom = b}
    end
  end
  object.velocity = function (arg)
    arg = arg or {}
    if arg.x then
        self.velocity.x = arg.x/M.scale
    end
    if arg.y then
        self.velocity.y = arg.y/M.scale
    end
    return {x=self.velocity.x*M.scale,y=self.velocity.y*M.scale}
  end
  object.acceleration = function (arg)
    arg = arg or {}
    if arg.x then
      --if self.scaled then
        self.acceleration.x = arg.x/M.scale
      --else
      --  self.acceleration.x = arg.x
      --end
    end
    if arg.y then
      --if self.scaled then
        self.acceleration.y = arg.y/M.scale
      --else
      --  self.acceleration.y = arg.y
      --end
    end
    --if self.scaled then
      return {x=self.acceleration.x*M.scale,y=self.acceleration.y*M.scale}
    --else
    --  return self.acceleration
    --end
  end
  object.bearing = function ()
    local hypotenuse = math.sqrt( math.pow(self.velocity.x,2) + math.pow(self.velocity.y,2) )
    return math.acos( self.velocity.x/hypotenuse )
  end
  object.height = function ()
    if self.scaled then
      return self.height*M.scale
    else
      return self.height
    end
  end
  object.width = function ()
    if self.scaled then
      return self.width*M.scale
    else
      return self.width
    end
  end
  
  table.insert(manager.entities, object)
  
  return object
end

M.render = function ()
  local camera = state.get().camera.position
  local screen_width = love.graphics.getWidth() --native_mode.width
  local screen_height = love.graphics.getHeight() --native_mode.height
  local sl = camera.x - screen_width/2
  local sr = camera.x + screen_width/2
  local st = camera.y - screen_height/2
  local sb = camera.y + screen_height/2
  for i = 1,#manager.entities do
    local entity = manager.entities[i]
    local position = entity.getPosition()
    local el = position.x
    local er = el + entity.width()
    local et = position.y
    local eb = et + entity.height()
    if er > sl and el < sr and eb > st and et < sb then
      entity.render()
    end
  end
end

M.update = function (dt)
  for _,entity in ipairs(manager.entities) do
    entity.update(dt)
  end
  for i = 1,#manager.entities do
    local e1 = manager.entities[i]
    if not (e1 == nil) then
      local r1 = e1.getCollisionRect()
      for j = i,#manager.entities do
        local e2 = manager.entities[j]
        if not (e2 == nil) then
          local r2 = e2.getCollisionRect()
          if r1.right >= r2.left and r2.right >= r1.left and r1.bottom >= r2.top and r2.bottom >= r1.top then
            event.notify("entityCollision",{e1,e2})
            event.notify("entityCollision",{e2,e1})
          end
        end
      end
    end
  end
  
  local i = 1
  while i <= #manager.entities do
    if manager.entities[i].delete then
      table.remove(manager.entities,i)
    else
      i = i + 1
    end
  end
end

M.registerType = function(name, spec)
  manager.types[name] = spec
end

-- M.scale = function(s)
--   for _,entity in ipairs(manager.entities) do
--     entity.scale(s)
--   end
-- end

M.getList = function(filter)
  local result = {}
  for _,entity in ipairs(manager.entities) do
    local match = true
    for k,v in pairs(filter) do
      if not (entity[k] == v) then
        match = false
        break
      end
    end
    if match then
      table.insert(result, entity)
    end
  end
  return result
end

local spritesheet = love.graphics.newImage("game/entities.png"),

M.registerType("player_spawn", {
  render = function (object, self)
  end
})
M.registerType("tinyworlder", {
  dynamic=true,
  render = function (object, self)
    love.graphics.setColor({255,0,0})
    local position = object.getPosition()
    local width = object.width()
    local height = object.height()
    love.graphics.rectangle("fill", position.x, position.y, spritesheet:getWidth(), spritesheet:getHeight())
  end
})
M.registerType("grower", {
  sprite = love.graphics.newQuad(0,0,128,128,512,896),
  inset=0.1,
  render = function (object, self)
    local position = object.getPosition()
    local width = object.width()
    local height = object.height()
    love.graphics.setColor({255,255,255})
    love.graphics.drawq(spritesheet, self.sprite, position.x, position.y, 0, width/128, height/128)
  end
})
M.registerType("shrinker", {
  sprite = love.graphics.newQuad(128,0,128,128,spritesheet:getWidth(),spritesheet:getHeight()),
  inset=0.1,
  render = function (object, self)
    local position = object.getPosition()
    local width = object.width()
    local height = object.height()
    love.graphics.setColor({255,255,255})
    love.graphics.drawq(spritesheet, self.sprite, position.x, position.y, 0, width/128, height/128)
  end
})
M.registerType("door", {
  render = function (object, self)
    local position = object.getPosition()
    local width = object.width()
    local height = object.height()
    local sprite = nil
    if self.width <= 128 then
      sprite = love.graphics.newQuad(3*128,128,128,128,spritesheet:getWidth(),spritesheet:getHeight())
      width = width / 128
      height = height / 128
    elseif self.width <= 256 then
      sprite = love.graphics.newQuad(0,128,256,256,spritesheet:getWidth(),spritesheet:getHeight())
      width = width / 256
      height = height / 256
    else
      sprite = love.graphics.newQuad(0,3*128,512,512,spritesheet:getWidth(),spritesheet:getHeight())
      width = width / 512
      height = height / 512
    end
    love.graphics.setColor({255,255,255})
    love.graphics.drawq(spritesheet, sprite, position.x, position.y, 0, width, height)
  end
})

M.clearAll = function ()
  manager.entities = {}
end

return M
