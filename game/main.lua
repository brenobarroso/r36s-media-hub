-- R36S Media Hub (LÖVE 11.5 / PortMaster)
io.stdout:setvbuf("no")
io.stderr:setvbuf("no")

local app = require("src.app")
local ui = require("src.ui")
local theme = require("src.theme")
local input = require("src.input")
local player = require("src.player")
local fs = require("src.fs")
local state = require("src.state")

local canvas
local debug_on = false
local debug_log = {}
local frame_t0 = 0
local selftest = nil
local last_input_time = 0
local screen_is_dimmed = false

local FRAME_TIME = 1 / 30 - 0.003 -- ~30 fps cap: plenty for a media hub, saves battery

local function dbg(s)
  table.insert(debug_log, 1, s)
  debug_log[9] = nil
end

local function set_backlight(level)
  local candidates = {
    "/sys/class/backlight/backlight/brightness",
    "/sys/class/backlight/pwm-backlight/brightness",
  }
  for _, p in ipairs(candidates) do
    local f = io.open(p, "w")
    if f then
      f:write(tostring(level))
      f:close()
      return
    end
  end
end

local function wake_screen()
  if screen_is_dimmed then
    screen_is_dimmed = false
    local pct = tonumber(app.state.brightness) or 80
    local max = 255
    set_backlight(math.floor(max * (pct / 100)))
  end
end

local function save_state()
  local st = app.state
  local browser = app.screens.browser
  if browser and browser.current_dir() then st.last_dir = browser.current_dir() end
  st.volume = string.format("%.2f", player.volume)
  st.shuffle = player.shuffle and "1" or "0"
  st.repeat_mode = player.repeat_mode
  st.swap_ab = input.swap_ab and "1" or "0"
  st.theme = theme.current_name
  st.brightness = app.state.brightness or "80"
  st.screen_dimmer = app.state.screen_dimmer or "0"
  st.eq = app.state.eq or (player.eq and player.eq.presets[player.eq.current].id) or "flat"
  st.music_dir = app.state.music_dir
  st.photos_dir = app.state.photos_dir or app.state.photo_dir
  st.photo_dir = st.photos_dir
  st.videos_dir = app.state.videos_dir or app.state.video_dir
  st.video_dir = st.videos_dir
  st.books_dir = app.state.books_dir or app.state.book_dir
  st.book_dir = st.books_dir
  state.save(st)
end

local function volume_toast()
  ui.toast(string.format("Volume %d%%", math.floor(player.volume * 100 + 0.5)))
end

local function on_action(a)
  last_input_time = love.timer.getTime()
  wake_screen()

  -- Select is a modifier: Select+Start quits, Select+X swaps A/B, Select+Y toggles the debug overlay.
  if a == "select" and input.is_held("start") then
    love.event.quit()
    return
  end
  if input.is_held("select") and a ~= "select" then
    if a == "start" then
      love.event.quit()
    elseif a == "x" then
      input.swap_ab = not input.swap_ab
      ui.toast(input.swap_ab and "Botões A/B trocados" or "Botões A/B padrão", 1.6)
    elseif a == "y" then
      debug_on = not debug_on
    end
    return
  end

  -- Forward action to active screen first
  local handled = false
  if app.current and app.current.action then
    handled = app.current.action(a)
  end

  if handled then
    return
  end

  -- Global fallbacks for media playback controls
  if a == "start" then
    player.toggle()
    ui.toast(player.status == "playing" and "Tocando" or (player.status == "paused" and "Pausado" or "Nada tocando"))
  elseif a == "l1" then
    player.prev()
  elseif a == "r1" then
    player.next()
  elseif a == "l2" then
    player.change_volume(-0.05)
    volume_toast()
  elseif a == "r2" then
    player.change_volume(0.05)
    volume_toast()
  end
end

function love.load()
  love.graphics.setDefaultFilter("linear", "linear")
  love.mouse.setVisible(false)
  ui.load()
  canvas = love.graphics.newCanvas(ui.W, ui.H)
  last_input_time = love.timer.getTime()

  local st = state.load()
  app.state = st
  app.root = fs.find_music_root()

  if st.theme then theme.set(st.theme) end
  player.set_volume(tonumber(st.volume) or 0.8)
  player.shuffle = (st.shuffle == "1")
  if st.repeat_mode == "all" or st.repeat_mode == "one" then player.repeat_mode = st.repeat_mode end
  input.swap_ab = (st.swap_ab == "1")
  input.on_action = on_action
  if player.eq then
    player.eq.init()
    if st.eq then player.set_eq(st.eq) end
  end

  app.screens.home = require("src.screens.home")
  app.screens.browser = require("src.screens.browser")
  app.screens.nowplaying = require("src.screens.nowplaying")
  app.screens.settings = require("src.screens.settings")
  app.screens.photos = require("src.screens.photos")
  app.screens.photo_viewer = require("src.screens.photo_viewer")
  app.screens.videos = require("src.screens.videos")
  app.screens.books = require("src.screens.books")
  app.screens.book_reader = require("src.screens.book_reader")
  app.screens.folder_picker = require("src.screens.folder_picker")

  app.show("home")

  if os.getenv("R36S_AUTOTEST") == "1" then
    selftest = require("src.selftest")
    selftest.start()
  end
end

function love.update(dt)
  frame_t0 = love.timer.getTime()
  app.time = app.time + dt
  input.update(dt)
  player.update(dt)
  ui.update(dt)

  -- Screen Dimmer auto-power-off
  local dimmer_sec = tonumber(app.state.screen_dimmer) or 0
  if dimmer_sec > 0 and player.status == "playing" and not screen_is_dimmed then
    if (love.timer.getTime() - last_input_time) > dimmer_sec then
      screen_is_dimmed = true
      set_backlight(0)
    end
  end

  if app.current.update then app.current.update(dt) end
  if selftest then selftest.update(dt) end
end

function love.draw()
  love.graphics.setCanvas(canvas)
  love.graphics.clear(ui.c.bg[1], ui.c.bg[2], ui.c.bg[3], 1)
  love.graphics.setColor(1, 1, 1, 1)
  app.current.draw()
  ui.draw_toast()

  if debug_on then
    ui.set({ 0, 0, 0 }, 0.8)
    love.graphics.rectangle("fill", 0, 0, ui.W, 150)
    love.graphics.setFont(ui.f.tiny)
    ui.set(ui.c.text)
    love.graphics.print(string.format("DEBUG  pad_seen=%s swap=%s joysticks=%d root=%s", tostring(input.pad_seen),
      tostring(input.swap_ab), love.joystick.getJoystickCount(), app.root), 8, 4)
    for i, l in ipairs(debug_log) do love.graphics.print(l, 8, 4 + i * 16) end
  end

  love.graphics.setCanvas()
  love.graphics.clear(0, 0, 0, 1)
  local ww, wh = love.graphics.getDimensions()
  local s = math.min(ww / ui.W, wh / ui.H)
  love.graphics.setBlendMode("alpha", "premultiplied")
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(canvas, (ww - ui.W * s) / 2, (wh - ui.H * s) / 2, 0, s, s)
  love.graphics.setBlendMode("alpha")

  local spare = FRAME_TIME - (love.timer.getTime() - frame_t0)
  if spare > 0 then love.timer.sleep(spare) end
end

-- Input events ---------------------------------------------------------------
function love.keypressed(key)
  dbg("key " .. key)
  input.keypressed(key)
end

function love.keyreleased(key)
  input.keyreleased(key)
end

function love.gamepadpressed(_, button)
  dbg("pad " .. button)
  input.padpressed(button)
end

function love.gamepadreleased(_, button)
  input.padreleased(button)
end

function love.gamepadaxis(_, axis, value)
  input.padaxis(axis, value)
end

function love.joystickadded(j)
  dbg("joystick+ " .. j:getName() .. " gamepad=" .. tostring(j:isGamepad()))
end

function love.joystickpressed(j, b)
  if not j:isGamepad() then dbg("raw joy button " .. b) end
end

function love.quit()
  save_state()
end

-- Show errors on screen (and in the PortMaster log) and exit on any button.
function love.errorhandler(msg)
  local trace = (debug.traceback("Error: " .. tostring(msg), 2):gsub("\t", "    "))
  io.stderr:write(trace, "\n")
  print(trace)
  if not (love.window and love.graphics and love.event) then return end
  pcall(love.audio.stop)
  love.graphics.reset()
  love.graphics.setFont(love.graphics.newFont(14))
  local t0 = love.timer.getTime()
  return function()
    love.event.pump()
    for e in love.event.poll() do
      if e == "quit" or e == "keypressed" or e == "joystickpressed" or e == "gamepadpressed" then
        return 1
      end
    end
    if love.timer.getTime() - t0 > 30 then return 1 end
    love.graphics.clear(0.30, 0.08, 0.08)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("R36S Media Hub - erro\n\n" .. trace .. "\n\n(pressione qualquer botao para sair)",
      16, 16, love.graphics.getWidth() - 32)
    love.graphics.present()
    love.timer.sleep(0.05)
  end
end
