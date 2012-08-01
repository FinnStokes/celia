-- main.lua

local pepperfish_profiler = require "pepperfish_profiler"

local sandbox = require "sandbox"

local gauge = {}
gauge.event = require "event"
gauge.entity = require "entity"
gauge.input = require "input"
gauge.state = require "state"
gauge.map = require "map"
gauge.music = require "music"
gauge.time = require "time"

local tween = require "tween"

local profiler = newProfiler()
profiler:start()

local loading = false

love.load = function ()
  local context = gauge.input.context.new({active = true})
  context.map = function (raw_in, map_in)
    if raw_in.key.pressed["-"] then
      map_in.actions["quit"] = true
    end
    return map_in
  end
  gauge.event.subscribe("input",
    function (input)
      if input.actions.quit then
        local quit = love.event.quit or love.event.push
        quit("q")
      end
    end
  )

  -- Set video mode (use settings.lua if present)
  local mode = { width = nil, height = nil }
  local fullscreen = true
  if love.filesystem.exists("settings.lua") then
    local settings = assert(love.filesystem.load("settings.lua"))()
    mode = {
      width = settings.screen_width or nil,
      height = settings.screen_height or nil
    }
    if settings.fullscreen ~= nil then
      fullscreen = settings.fullscreen
    end
  end
  if not mode.width or not mode.height then
    local modes = love.graphics.getModes()
    table.sort(modes, function(a, b)
      return a.width*a.height > b.width*b.height
    end)
    mode = modes[1]
  end
  love.graphics.setMode(mode.width, mode.height, fullscreen)
  gauge.video_mode = mode -- XXX: ugly hack

  local bgm = nil
  local old_bgm_file = nil
  local game_state = gauge.state.new()
  gauge.event.subscribe("loadMap", function (arg)
    loading = true
    if love.filesystem.exists(arg.file) then
      if game_state.map then game_state.map.delete() end
      game_state.map = gauge.map.new({
        data = love.filesystem.load(arg.file)
      })
      local bgm_file = game_state.map.properties().bgm
      if bgm_file and bgm_file ~= old_bgm_file then
        if bgm then bgm.stop() end
        bgm = gauge.music.new({file="game/"..bgm_file, volume=1, loop=true})
        bgm.play()
        old_bgm_file = bgm_file
      elseif not bgm_file then
        bgm.stop()
        old_bgm_file = nil
      end
      gauge.event.notify("input", {
        actions = {reset = true},
        states = {},
        ranges = {}
      })
    else
      gauge.event.notify("input", {
        actions = {quit = true},
        states = {},
        ranges = {}
      })
    end
  end)
  game_state.render = function (lagging)
    love.graphics.push()
    --love.graphics.scale(game_state.camera.scale)
    if game_state.map then
      game_state.map.render(lagging)
    end
    love.graphics.translate(
      (love.graphics.getWidth() / 2) - math.floor(game_state.camera.position.x),
      (love.graphics.getHeight() / 2) - math.floor(game_state.camera.position.y))
    gauge.entity.render()
    love.graphics.pop()
  end
  game_state.update = function (dt)
    gauge.entity.update(dt)
  end
  game_state.map = nil
  game_state.camera = {
    position = {
      x = 0,
      y = 0
    },
    speed = 0.05,
    max_distance = 150,
    scale = 1,
    zoom = false
  }
  gauge.state.push(game_state)

  local untrusted_code = assert(love.filesystem.load("game/main.lua"))
  local trusted_code = sandbox.new(untrusted_code, {gauge=gauge, math=math, print=print, tween=tween, love=love})
  pcall(trusted_code)
end

frames = 0
skipped = 0

local lagging = false
love.update = function (dt)
  if not loading then
    local input = gauge.input.update(dt)
    if input then
      gauge.event.notify("input", input)
    end
    
    gauge.time.update(dt)
    
    frames = frames + 1
    local updates = 1
    if dt > 1/30 then
      lagging = true
    else
      lagging = false
    end

    if dt > 1/60 then
      updates = math.ceil(dt*60)
      if updates > 8 then
        updates = 8
        dt = 1/60
        skipped = skipped + 1
      else
         dt = dt/updates
      end
    end
    
    local state = gauge.state.get()
    for i = 1,updates do
      if dt > 0 then
        tween.update(dt)
      end
      state.update(dt)
    end
  else
    loading = false
  end
end

love.draw = function ()
  gauge.state.get().render(lagging)
end

love.keypressed = function (key, unicode)
  gauge.input.keyPressed(key)
end

love.keyreleased = function (key, unicode)
  gauge.input.keyReleased(key)
end

love.joystickpressed = function (joystick, button)
  gauge.input.joystickPressed(joystick, button)
end

love.joystickreleased = function (joystick, button)
  gauge.input.joystickReleased(joystick, button)
end

love.focus = function (f)

end

love.quit = function ()
   profiler:stop()
   print("Average fps",frames/gauge.time.get())
   print("% frames skipped",(skipped/frames) * 100)
   local outfile = io.open( "profile.txt", "w+" )
   profiler:report( outfile )
   outfile:close()
   outfile = io.open("report.txt", "w+")
   outfile:write("Average fps: ",frames/gauge.time.get())
   outfile:write("\n% frames skipped: ",(skipped/frames) * 100)
   outfile:close()
end
