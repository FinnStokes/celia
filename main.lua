local walk_v = 100
local jump_height = 75
local jump_length = 96

local jump_v = 4*walk_v*jump_height/jump_length
local g = jump_v*jump_v/(2*jump_height)

local context = gauge.input.context.new({active = true})
context.map = function (raw_in, map_in)
  if raw_in.key.pressed["up"] then
    map_in.actions["jump"] = true
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

gauge.entity.registerType("player", {
  acceleration = { x = 0, y = g },
  width=30,
  height=30,
  scaled=false,
  update = function (object, self, dt)
    -- camera
    local camera = gauge.state.get().camera
    local player = object.position()
    local dx = camera.position.x - player.x
    local dy = camera.position.y - player.y
    if math.abs(dx) > camera.max_distance then
      camera.position.x = camera.position.x - (dx * camera.speed)
    end
    if math.abs(dy) > camera.max_distance then
      camera.position.y = camera.position.y - (dy * camera.speed)
    end
    
    -- music
    littleTheme.volume(gauge.entity.scale)
    bigTheme.volume(1 - gauge.entity.scale)
  end
})

gauge.event.notify("loadMap", {file="test_level.lua"})

local spawn = gauge.entity.getList({type="player_spawn"})[1]
local player = gauge.entity.new({
  type="player",
  position={x=spawn.position().x, y=spawn.position().y},
})

gauge.event.subscribe("input",
  function (input)
    if input.actions.jump then
      if not player.falling then
        player.velocity({y = -jump_v})
        player.falling = true
      end
    end
    if input.actions.left then
      player.velocity({x = -walk_v})
    end
    if input.actions.right then
      player.velocity({x = walk_v})
    end
    if input.actions.stop then
      player.velocity({x = 0})
    end
  end
)

gauge.event.subscribe("input",
  function (input)
    if input.actions.grow then
      tween(1,gauge.entity,{scale = gauge.entity.scale * 0.5})
    end
    if input.actions.shrink then
      tween(1,gauge.entity,{scale = gauge.entity.scale / 0.5})
    end
  end
)

gauge.event.subscribe("entityCollision",
  function (entities)
    if entities[1] == player then
      if entities[2].type() == "grower" then
        --gauge.state.get().map.scale(0.5)
        --gauge.entity.scale(0.5)
        tween(1,gauge.entity,{scale = gauge.entity.scale * 0.5})
        -- local x = ((player.position().x + (player.width() / 2)) * 0.5) - (player.width() / 2)
        -- local y = ((player.position().y + player.height()) * 0.5) - player.height()
        -- player.position({x = x, y = y})
        -- local camera = gauge.state.get().camera
        -- camera.position.x = x
        -- camera.position.y = y
        entities[2].delete = true
      end
      if entities[2].type() == "shrinker" then
        --gauge.state.get().map.scale(2)
        --gauge.entity.scale(2)
        tween(1,gauge.entity,{scale = gauge.entity.scale / 0.5})
        -- local x = ((player.position().x + (player.width() / 2)) * 2) - (player.width() / 2)
        -- local y = ((player.position().y + player.height()) * 2) - player.height()
        -- player.position({x = x, y = y})
        -- local camera = gauge.state.get().camera
        -- camera.position.x = x
        -- camera.position.y = y
        entities[2].delete = true
      end
    end
  end
)
