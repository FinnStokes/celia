
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
  return map_in
end


local player = gauge.entity.new{
  position = { x = 200, y = 200 },
  velocity = { x = 0, y = 0 },
  acceleration = { x = 0, y = 300},
}
player.lifetime = 0

local update = player.update
player.update = function (dt)
  update(dt)
  player.lifetime = player.lifetime + dt
  
  -- camera
  local camera = gauge.state.get().camera
  local player = player.position()
  local dx = camera.position.x - player.x
  local dy = camera.position.y - player.y
  local distance = math.sqrt((dx * dx) + (dy * dy))
  if math.abs(dx) > camera.max_distance or
      math.abs(dy) > camera.max_distance then
    camera.position.x = camera.position.x - (dx / camera.speed)
    camera.position.y = camera.position.y - (dy / camera.speed)
  end
end


gauge.event.subscribe("input",
  function (input)
    if input.actions.jump then
      if not player.falling then
        player.velocity({y = -300})
        player.falling = true
      end
    end
    if input.actions.left then
      player.velocity({x = -100})
    end
    if input.actions.right then
      player.velocity({x = 100})
    end
    if input.actions.stop then
      player.velocity({x = 0})
    end
  end
)
