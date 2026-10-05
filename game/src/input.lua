-- Input abstraction: gamepad (SDL mapping provided by PortMaster) + keyboard (PC testing).
-- Everything is converted to logical actions:
--   up down left right accept back x y l1 r1 l2 r2 start select
local M = {
  swap_ab = false,   -- swap accept/back on gamepads (Nintendo vs Xbox layout)
  pad_seen = false,  -- once a gamepad is used, keyboard events are ignored
  on_action = nil,
}

local PAD = {
  dpup = "up", dpdown = "down", dpleft = "left", dpright = "right",
  a = "accept", b = "back", x = "x", y = "y",
  leftshoulder = "l1", rightshoulder = "r1",
  start = "start", back = "select",
}

local KEYS = {
  up = "up", down = "down", left = "left", right = "right",
  ["return"] = "accept", kpenter = "accept",
  backspace = "back", escape = "back",
  x = "x", y = "y", q = "l1", e = "r1", a = "l2", d = "r2",
  space = "start", tab = "select",
}

local REPEATABLE = { up = true, down = true, left = true, right = true }
local REPEAT_DELAY, REPEAT_RATE = 0.40, 0.07

local held = {}
local timers = {}
local pad_down = {}
local key_down = {}
local axis_state = {}

function M.is_held(a)
  return held[a] == true
end

local function emit(a)
  if M.on_action then M.on_action(a) end
end

local function press(a)
  if held[a] then return end
  held[a] = true
  if REPEATABLE[a] then timers[a] = REPEAT_DELAY end
  emit(a)
end

local function release(a)
  held[a] = nil
  timers[a] = nil
end

function M.update(dt)
  local due
  for a, t in pairs(timers) do
    t = t - dt
    if t <= 0 then
      due = due or {}
      due[#due + 1] = a
      t = REPEAT_RATE
    end
    timers[a] = t
  end
  if due then
    for _, a in ipairs(due) do
      if held[a] then emit(a) end
    end
  end
end

-- Keyboard -------------------------------------------------------------------
function M.keypressed(key)
  if M.pad_seen then return end
  local a = KEYS[key]
  if a then
    key_down[key] = a
    press(a)
  end
end

function M.keyreleased(key)
  local a = key_down[key]
  if a then
    key_down[key] = nil
    release(a)
  end
end

-- Gamepad --------------------------------------------------------------------
function M.padpressed(button)
  M.pad_seen = true
  local a = PAD[button]
  if not a then return end
  if M.swap_ab then
    if a == "accept" then a = "back" elseif a == "back" then a = "accept" end
  end
  pad_down[button] = a
  press(a)
end

function M.padreleased(button)
  local a = pad_down[button]
  if a then
    pad_down[button] = nil
    release(a)
  end
end

local function axis_dir(name, v, neg, pos)
  local s = axis_state[name] or 0
  local ns = 0
  if v > 0.6 then ns = 1 elseif v < -0.6 then ns = -1 end
  -- hysteresis: stay engaged until the stick returns near the centre
  if s ~= 0 and ns == 0 and ((s == 1 and v > 0.35) or (s == -1 and v < -0.35)) then
    ns = s
  end
  if ns ~= s then
    if s == -1 then release(neg) elseif s == 1 then release(pos) end
    if ns ~= 0 then M.pad_seen = true end
    if ns == -1 then press(neg) elseif ns == 1 then press(pos) end
    axis_state[name] = ns
  end
end

function M.padaxis(axis, v)
  if axis == "leftx" then
    axis_dir(axis, v, "left", "right")
  elseif axis == "lefty" then
    axis_dir(axis, v, "up", "down")
  elseif axis == "triggerleft" or axis == "triggerright" then
    local a = axis == "triggerleft" and "l2" or "r2"
    local on = v > 0.5
    if on and not held[a] then
      M.pad_seen = true
      press(a)
    elseif not on and held[a] and v < 0.3 then
      release(a)
    end
  end
end

return M
