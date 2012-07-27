local walk_v = 512
local jump_height = 320 --272
local jump_length = 384
local friction = 1

local jump_v = 4*walk_v*jump_height/jump_length
local g = jump_v*jump_v/(2*jump_height)

local context = gauge.input.context.new({active = true})
context.map = function (raw_in, map_in)
  if raw_in.key.pressed["up"] or
      raw_in.key.pressed[" "] or
      raw_in.key.pressed["w"] then
    map_in.actions["jump"] = true
  end
  if raw_in.key.released["up"] or
      raw_in.key.released[" "] or
      raw_in.key.released["w"] then
    map_in.actions["fall"] = true
  end
  
  if raw_in.key.pressed["return"] or
    raw_in.key.pressed["r"] then
    map_in.actions["reset"] = true
  end

  -- Joystick movement
  --[[if raw_in.joystick.axis and raw_in.joystick.axis[1] then
    if raw_in.joystick.axis[1] < -0.2 then
      map_in.actions["left"] = true
    elseif raw_in.joystick.axis[1] > 0.2 then
      map_in.actions["right"] = true
    else
      map_in.actions["stop"] = true
    end
  end]]--

  -- Left Key
  if raw_in.key.pressed["left"] or
      raw_in.key.pressed["a"] then
    if raw_in.key.down["right"] or
      raw_in.key.down["d"] then
      map_in.actions["stop"] = true
    else
      map_in.actions["left"] = true
    end
  end
  if raw_in.key.released["left"] or
      raw_in.key.released["a"] then
    if raw_in.key.down["right"] or
        raw_in.key.down["d"] then
      map_in.actions["right"] = true
    else
      map_in.actions["stop"] = true
    end
  end

  -- Right Key
  if raw_in.key.pressed["right"] or
      raw_in.key.pressed["d"] then
    if raw_in.key.down["left"] or
        raw_in.key.down["a"] then
      map_in.actions["stop"] = true
    else
      map_in.actions["right"] = true
    end
  end
  if raw_in.key.released["right"] or
      raw_in.key.released["d"] then
    if raw_in.key.down["left"] or
        raw_in.key.down["a"] then
      map_in.actions["left"] = true
    else
      map_in.actions["stop"] = true
    end
  end
  
  return map_in
end

gauge.entity.registerType("player", {
  acceleration = { x = 0, y = g },
  width=64,
  height=128,
  weight=1,
  collisionRect = { left = -16, top = -118, right = 16, bottom = 0 },
  scaled=false,
  dynamic=true,
  friction = friction,
  image=love.graphics.newImage("game/celia.png"),
  animations = {
    idle = {
      framerate = 3,
      frames = 3,
      line = 0
    },
    walk = {
      framerate = 10,
      frames = 5,
      line = 1
    },
    jump = {
      framerate = 1,
      frames = 1,
      line = 2
    },
    falling = {
      framerate = 2,
      frames = 4,
      line = 3
    },
    reach = {
      framerate = 1,
      frames = 2,
      line = 4
    },
    lookdown = {
      framerate = 1,
      frames = 1,
      line = 5
    }
  },
  frame = 0,
  faceRight = true,
  animation = "idle",
  setAnimation=function(object, self, anim, lowPriority)
    if not lowPriority or self.animation == "idle" then
      self.animation = anim
    end
  end,
  chestHeaving = 1,
  render=function(object, self)
    self.frame = self.frame % self.animations[self.animation].frames
    local sprite = love.graphics.newQuad(64*math.floor(self.frame),
      128*self.animations[self.animation].line,64,128,
      self.image:getWidth(), self.image:getHeight())
    love.graphics.setColor({255,255,255})
    local position = object.getPosition()
    local scaleFlip = 1
    local originFlip = 0
    if not self.faceRight then
      scaleFlip = -1
      originFlip = 64
    end
    love.graphics.drawq(self.image,sprite,position.x-self.width/2,position.y-self.height, 0,
    scaleFlip, 1, originFlip, 0)
  end,
  update=function(object, self, dt)
    local map = gauge.state.get().map
    local camera = gauge.state.get().camera
    if object.float then
      if self.velocity.y < 0 then
        self.friction = 0
      else
        self.friction = friction
      end
    else
      if self.velocity.y < 0 then
        self.friction = 8
      else
        self.friction = friction
      end
    end
    if map and map.properties and map.properties().credits then
      self.position = { x = 64, y = 128 }
      self.velocity = { x = 0, y = 0 }
      self.acceleration = { x = 0, y = 0 }
      self.animation = "falling"
      self.frame = self.frame + dt*self.animations[self.animation].framerate
      camera.position.x = 128
      camera.position.y = -128
      return
    end
    if self.velocity.y > 1 then
      self.animation = "falling"
    elseif self.velocity.y < -1 then
      self.animation = "jump"
      if self.chestHeaving < 5 then
        self.chestHeaving = self.chestHeaving + 2 * dt
      end
    elseif self.velocity.x > 1 then
      self.animation = "walk"
      self.faceRight = true
      if self.chestHeaving < 5 then
        self.chestHeaving = self.chestHeaving + dt
      end
    elseif self.velocity.x < -1 then
      self.animation = "walk"
      self.faceRight = false
      if self.chestHeaving < 5 then
        self.chestHeaving = self.chestHeaving + dt
      end
    elseif self.faceRight then
      self.animation = "idle"
      if self.chestHeaving > 1 then
        self.chestHeaving = self.chestHeaving - dt
      end
    else
      self.animation = "idle"
      if self.chestHeaving > 1 then
        self.chestHeaving = self.chestHeaving - dt
      end
    end
    if self.animation == "idle" then
      self.animations[self.animation].framerate = 2 * self.chestHeaving
    end
    self.frame = self.frame + dt*self.animations[self.animation].framerate
    
    -- camera
    local camera = gauge.state.get().camera
    local position = object.getPosition()
    local player_x = position.x
    local player_y = position.y
    if camera.zoom then
      player_x = player_x / 4
      player_y = player_y / 4
    end
    camera.position.x = player_x
    camera.position.y = player_y
    
    -- lock to edges
    if not map.properties()['wrap'] then
      if map.width()*gauge.entity.scale < gauge.video_mode.width then
        camera.position.x = (map.width()*gauge.entity.scale/2)
      elseif camera.position.x > (map.width()*gauge.entity.scale) - (gauge.video_mode.width/2) then
        camera.position.x = (map.width()*gauge.entity.scale) - (gauge.video_mode.width/2)
      elseif camera.position.x < gauge.video_mode.width/2 then
        camera.position.x = gauge.video_mode.width/2
      end
      
      if map.height()*gauge.entity.scale < gauge.video_mode.height then
        camera.position.y = (map.height()*gauge.entity.scale/2)
      elseif camera.position.y > (map.height()*gauge.entity.scale) - (gauge.video_mode.height/2) then
        camera.position.y = (map.height()*gauge.entity.scale) - (gauge.video_mode.height/2)
      elseif camera.position.y < gauge.video_mode.height/2 then
        camera.position.y = gauge.video_mode.height/2
      end
    end

  end
})

local level = 0
local nextLevel = function ()
  level = level + 1
  gauge.event.notify("loadMap", {
    file = "game/" .. level .. ".lua"
  })
end
nextLevel()
local previousLevel = function ()
  if level > 1 then
    level = level - 1
  end
  gauge.event.notify("loadMap", {
    file = "game/" .. level .. ".lua"
  })
end

local spawn = gauge.entity.getList({type="player_spawn"})[1]
local spawnPos = function()
  local position = spawn.getPosition()
  position.x = position.x + spawn.width()/2
  position.y = position.y + spawn.height()
  return position
end
local player = gauge.entity.new({
  type="player",
  position=spawnPos(),
})
gauge.entity.scale = gauge.entity.scale * 128 / spawn.height()
local camera = gauge.state.get().camera
camera.position = player.getPosition()

gauge.event.subscribe("animation",
  function (arg)
    if arg.entity == player then
      player.setAnimation(arg.animation, arg.lowPriority)
    end
  end
)

local growing = false
local shrinking = false
local endScale = function()
  player.transforming = false
  growing = false
  shrinking = false
end

gauge.event.subscribe("input",
  function (input)
    if input.actions.jump and not (growing or shrinking) then
      player.float = true
      if not player.falling then
        player.velocity({y = -jump_v*math.sqrt(gauge.entity.scale)})
        player.falling = true
      end
    end
    if input.actions.fall then
      player.float = false
    end
    if input.actions.left and not (growing or shrinking) then
      player.velocity({x = -walk_v*math.sqrt(gauge.entity.scale)})
    end
    if input.actions.right and not (growing or shrinking) then
      player.velocity({x = walk_v*math.sqrt(gauge.entity.scale)})
    end
    if input.actions.stop then
      player.velocity({x = 0})
    end
    if input.actions.nextLevel then
      nextLevel()
    end
    if input.actions.previousLevel then
      previousLevel()
    end
  end
)

local growEffect = gauge.music.new({file="game/whistlegrow.ogg", volume=1})
local shrinkEffect = gauge.music.new({file="game/whistleshrink.ogg", volume=1})
local doorEffect = gauge.music.new({file="game/door.ogg", volume=1})

local scale = gauge.entity.scale

local scaleTween = nil

gauge.event.subscribe("entityCollision",
  function (entities)
    if entities[1] == player then
      if entities[2].type == "grower" and scale > 1 / 5  then
        tween.stop(scaleTween)
        scale = scale/2
        scaleTween = tween(0.5,gauge.entity,{scale = scale},'linear',endScale)
        entities[2].delete = true
        growing = true
        shrinking = false
        player.transforming = true
        gauge.event.notify("input", {actions={stop=true}})
        growEffect.play()
        shrinkEffect.stop()
        doorEffect.stop()
      end
      if entities[2].type == "shrinker" and scale < 1 then
        tween.stop(scaleTween)
        scale = scale*2
        scaleTween = tween(0.5,gauge.entity,{scale = scale},'linear',endScale)
        entities[2].delete = true
        growing = false
        shrinking = true
        player.transforming = true
        gauge.event.notify("input", {actions={stop=true}})
        growEffect.stop()
        shrinkEffect.play()
        doorEffect.stop()
      end
      if entities[2].type == "door" then
        local size = entities[2].height()
        if math.abs(128 - size) < 1 then
	  local player_rect = player.getCollisionRect()
	  local door_rect = entities[2].getCollisionRect()
          if player_rect.left >= door_rect.left and
              player_rect.right <= door_rect.right and
              player_rect.top >= door_rect.top and
              player_rect.bottom <= door_rect.bottom then
            growEffect.stop()
            shrinkEffect.stop()
            doorEffect.play()
            nextLevel()
          end
        elseif 128 < size then
          gauge.event.notify("animation", {
            entity = player,
            animation = "reach",
            lowPriority = true
          })
        elseif 128 > size then
          gauge.event.notify("animation", {
            entity = player,
            animation = "lookdown",
            lowPriority = true
          })
        end
      end
    end
  end
)

gauge.event.subscribe("entityStuck",
  function (entity)
    if entity == player and growing then
      tween.stop(scaleTween)
      scale = scale*2
      scaleTween = tween(0.5, gauge.entity,{scale = scale},'linear',endScale)
      growing = false
      shrinking = true
    end
  end
)

gauge.event.subscribe("input", function (input)
  if input.actions.reset then
    tween.stop(scaleTween)
    player.transforming = false
    gauge.state.get().map.reset()
    gauge.entity.scale = 1
    spawn = gauge.entity.getList({type="player_spawn"})[1]
    player = gauge.entity.new({
      type="player",
      position=spawnPos(),
    })
    gauge.entity.scale = gauge.entity.scale * 128 / spawn.height()
    local camera = gauge.state.get().camera
    camera.position = player.getPosition()
    scale = gauge.entity.scale
    growing = false
    shrinking = false
  end
end)
