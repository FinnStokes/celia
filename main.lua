local walk_v = 512
local jump_height = 272
local jump_length = 384

local jump_v = 4*walk_v*jump_height/jump_length
local g = jump_v*jump_v/(2*jump_height)

local context = gauge.input.context.new({active = true})
context.map = function (raw_in, map_in)
  if raw_in.key.pressed["up"] then
    map_in.actions["jump"] = true
  end
  
  if raw_in.key.pressed["down"] then
    map_in.actions["zoomOut"] = true
  end
  
  if raw_in.key.released["down"] then
    map_in.actions["zoomIn"] = true
  end
  
  if raw_in.key.pressed["r"] then
    map_in.actions["reset"] = true
  end

  -- Left Key
  if raw_in.key.pressed["left"] then
    if raw_in.key.down["right"] then
      map_in.actions["stop"] = true
    else
      map_in.actions["left"] = true
    end
  end
  if raw_in.key.released["left"] then
    if raw_in.key.down["right"] then
      map_in.actions["right"] = true
    else
      map_in.actions["stop"] = true
    end
  end

  -- Right Key
  if raw_in.key.pressed["right"] then
    if raw_in.key.down["left"] then
      map_in.actions["stop"] = true
    else
      map_in.actions["right"] = true
    end
  end
  if raw_in.key.released["right"] then
    if raw_in.key.down["left"] then
      map_in.actions["left"] = true
    else
      map_in.actions["stop"] = true
    end
  end
  
  -- Map Scale
  if raw_in.key.pressed["e"] then
    map_in.actions["grow"] = true
  end
  if raw_in.key.pressed["q"] then
    map_in.actions["shrink"] = true
  end
  
  return map_in
end

local littleTheme = gauge.music.new({file="little.ogg", volume=0, loop=true})
local bigTheme = gauge.music.new({file="big.ogg", volume=0, loop=true})
littleTheme.play()
bigTheme.play()

gauge.entity.registerType("player", {
  acceleration = { x = 0, y = g },
  width=38,
  height=118,
  scaled=false,
  image=love.graphics.newImage("celia.png"),
  animations = {
    idleLeft = {
      framerate = 3,
      frames = 3,
      flipped = true,
      line = 0
    },
    idleRight = {
      framerate = 3,
      frames = 3,
      flipped = false,
      line = 0
    },
    walkLeft = {
      framerate = 15,
      frames = 6,
      flipped = true,
      line = 1
    },
    walkRight = {
      framerate = 15,
      frames = 6,
      flipped = false,
      line = 1
    }
  },
  frame = 0,
  faceRight = true,
  animation = "idleRight",
  setAnimation=function(anim)
    self.animation = anim
  end,
  chestHeaving = 1,
  render=function(object, self)
    if self.frame >self.animations[self.animation].frames then
      self.frame = self.frame - self.animations[self.animation].frames
    end
    --self.frame = self.frame % self.frames <-- not sure if want
    local sprite = love.graphics.newQuad(64*math.floor(self.frame),
      128*self.animations[self.animation].line,64,128,384,256)
    love.graphics.setColor({255,255,255})
    local position = object.position()
    local scaleFlip = 1
    local originFlip = 0
    if self.animations[self.animation].flipped then
      scaleFlip = -1
      originFlip = 64
    end
    love.graphics.drawq(self.image,sprite,position.x-16,position.y-10,0,
    scaleFlip, 1, originFlip, 0)
  end,
  update=function(object, self, dt)
    if self.velocity.x > 1 then
      self.animation = "walkRight"
      self.faceRight = true
      if self.chestHeaving < 5 then
        self.chestHeaving = self.chestHeaving + dt
      end
    elseif self.velocity.x < -1 then
      self.animation = "walkLeft"
      self.faceRight = false
      if self.chestHeaving < 5 then
        self.chestHeaving = self.chestHeaving + dt
      end
    elseif self.faceRight then
      self.animation = "idleRight"
      if self.chestHeaving > 1 then
        self.chestHeaving = self.chestHeaving - dt
      end
    else
      self.animation = "idleLeft"
      if self.chestHeaving > 1 then
        self.chestHeaving = self.chestHeaving - dt
      end
    end
    if self.animation == "idleLeft" then
      self.animations[self.animation].framerate = 2 * self.chestHeaving
    elseif self.animation == "idleRight" then
      self.animations[self.animation].framerate = 2 * self.chestHeaving
    end
    self.frame = self.frame + dt*self.animations[self.animation].framerate
    
    -- camera
    local camera = gauge.state.get().camera
    local player_x = nil
    local player_y = nil
    if camera.zoom then
      player_x = object.position().x / 4
      player_y = object.position().y / 4
    else
      player_x = object.position().x
      player_y = object.position().y
    end
    local dx = camera.position.x - player_x
    local dy = camera.position.y - player_y
    if math.abs(dx) > dx * camera.speed then
      camera.position.x = camera.position.x - (dx * camera.speed)
    else
      camera.position.x = player_x
    end
    if math.abs(dy) > dx * camera.speed then
      camera.position.y = camera.position.y - (dy * camera.speed)
    else
      camera.position.y = player_y
    end
    camera.position.x = math.floor(camera.position.x)
    camera.position.y = math.floor(camera.position.y)
    
    -- music
    if gauge.entity.scale > 1/2 then
      littleTheme.volume(1)
      bigTheme.volume(0)
    elseif gauge.entity.scale < 1/4 then
      littleTheme.volume(0)
      bigTheme.volume(1)
    else
      local s = ((1 / gauge.entity.scale) - 2) / 2
      littleTheme.volume(1 - s)
      bigTheme.volume(s)
    end
  end
})

local level = 0
local nextLevel = function ()
  level = level + 1
  gauge.event.notify("loadMap", {
    file = level .. ".lua"
  })
end
nextLevel()

local spawn = gauge.entity.getList({type="player_spawn"})[1]
local player = gauge.entity.new({
  type="player",
  position={x=spawn.position().x, y=spawn.position().y},
})

gauge.event.subscribe("animation",
  function (arg)
    if arg.entity == player then
      player.setAnimation(arg.animation)
    end
  end
)

gauge.event.subscribe("input",
  function (input)
    if input.actions.jump then
      if not player.falling then
        player.velocity({y = -jump_v*math.sqrt(gauge.entity.scale)})
        player.falling = true
      end
    end
    if input.actions.left then
      player.velocity({x = -walk_v*math.sqrt(gauge.entity.scale)})
    end
    if input.actions.right then
      player.velocity({x = walk_v*math.sqrt(gauge.entity.scale)})
    end
    if input.actions.stop then
      player.velocity({x = 0})
    end
  end
)

local scale = gauge.entity.scale

local scaleTween = nil

local growing = false
local endGrow = function()
  growing = false
end

gauge.event.subscribe("entityCollision",
  function (entities)
    if entities[1] == player then
      if entities[2].type == "grower" then
        tween.stop(scaleTween)
        scale = 1/(1/scale + 1)
        scaleTween = tween(1,gauge.entity,{scale = scale},'linear',endGrow)
        entities[2].delete = true
        growing = true
      end
      if entities[2].type == "shrinker" then
        tween.stop(scaleTween)
        scale = 1/(1/scale - 1)
        scaleTween = tween(1,gauge.entity,{scale = scale})
        entities[2].delete = true
      end
      if entities[2].type == "door" then
        local size = entities[2].height()
        if math.abs(128 - size) < 1 then
          if player.position().x >= entities[2].position().x and
              player.position().x + player.width() <= entities[2].position().x + entities[2].width() and
              player.position().y >= entities[2].position().y and
              player.position().y + player.height() <= entities[2].position().y + entities[2].height() then
            nextLevel()
          end
        end
      end
    end
  end
)

gauge.event.subscribe("entityStuck",
  function (entity)
    if entity == player and growing then
      tween.stop(scaleTween)
      scale = 1/(1/scale - 1)
      scaleTween = tween(0.5, gauge.entity,{scale = scale})
      growing = false
    end
  end
)

local cameraTween = nil
gauge.event.subscribe("input",
  function (input)
    if input.actions.zoomOut then
      gauge.state.get().camera.zoom = true
      tween.stop(cameraTween)
      cameraTween = tween(1, gauge.state.get().camera,{
        scale = 0.2
      })
    end
  end
)

gauge.event.subscribe("input",
  function (input)
    if input.actions.zoomIn then
      gauge.state.get().camera.zoom = false
      tween.stop(cameraTween)
      cameraTween = tween(1, gauge.state.get().camera,{
        scale = 1
      })
    end
  end
)

gauge.event.subscribe("input", function (input)
  if input.actions.reset then
    tween.stop(scaleTween)
    gauge.state.get().map.reset()
    player = gauge.entity.new({
      type="player",
      position={x=spawn.position().x, y=spawn.position().y},
    })
    scale = gauge.entity.scale
  end
end)
