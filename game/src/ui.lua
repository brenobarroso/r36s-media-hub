-- Theme, fonts and drawing helpers (all coordinates are in the 640x480 virtual screen).
local utf8 = require("utf8")

local M = {}

M.W, M.H = 640, 480

M.c = {
  bg      = { 0.055, 0.065, 0.095 },
  panel   = { 0.095, 0.115, 0.165 },
  panel2  = { 0.140, 0.165, 0.230 },
  accent  = { 0.20, 0.82, 0.64 },
  text    = { 0.94, 0.96, 0.98 },
  dim     = { 0.58, 0.63, 0.72 },
  faint   = { 0.28, 0.32, 0.41 },
}

function M.set(c, a)
  love.graphics.setColor(c[1], c[2], c[3], a or c[4] or 1)
end

local function load_font(path, size)
  local ok, f = pcall(love.graphics.newFont, path, size)
  if ok then return f end
  return love.graphics.newFont(size)
end

function M.load()
  local reg, bold = "assets/NotoSans-Regular.ttf", "assets/NotoSans-Bold.ttf"
  M.f = {
    tiny  = load_font(reg, 14),
    small = load_font(reg, 16),
    body  = load_font(reg, 20),
    bodyb = load_font(bold, 20),
    sub   = load_font(reg, 22),
    head  = load_font(bold, 22),
    title = load_font(bold, 30),
  }
end

-- Text -----------------------------------------------------------------------
local cache, ccount = {}, 0

-- Truncates `text` with an ellipsis so it fits in `maxw` pixels.
function M.fit(font, text, maxw)
  if font:getWidth(text) <= maxw then return text end
  local key = tostring(font) .. "|" .. maxw .. "|" .. text
  local hit = cache[key]
  if hit then return hit end
  local s = text
  while #s > 0 and font:getWidth(s .. "…") > maxw do
    local off = utf8.offset(s, -1)
    if not off then break end
    s = s:sub(1, off - 1)
  end
  s = s .. "…"
  ccount = ccount + 1
  if ccount > 400 then cache, ccount = {}, 0 end
  cache[key] = s
  return s
end

-- Draws text that scrolls horizontally when it doesn't fit in `w`.
function M.marquee(text, font, x, y, w, elapsed)
  love.graphics.setFont(font)
  local tw = font:getWidth(text)
  if tw <= w then
    love.graphics.print(text, x, y)
    return
  end
  local over = tw - w + 32
  local speed = 45
  local cycle = over / speed + 3
  local ph = elapsed % cycle
  local off = 0
  if ph > 1.5 then off = math.min((ph - 1.5) * speed, over) end
  local sx, sy, sw, sh = love.graphics.getScissor()
  love.graphics.setScissor(x, y - 2, w, font:getHeight() + 4)
  love.graphics.print(text, x - off, y)
  if sx then love.graphics.setScissor(sx, sy, sw, sh) else love.graphics.setScissor() end
end

-- Shapes / icons ---------------------------------------------------------------
function M.bar(x, y, w, h, frac, fg, bg)
  M.set(bg or M.c.faint)
  love.graphics.rectangle("fill", x, y, w, h, h / 2, h / 2)
  frac = math.max(0, math.min(1, frac or 0))
  if frac > 0 then
    M.set(fg or M.c.accent)
    love.graphics.rectangle("fill", x, y, math.max(h, w * frac), h, h / 2, h / 2)
  end
end

function M.icon_play(x, y, s)
  love.graphics.polygon("fill", x + s * 0.1, y, x + s * 0.1, y + s, x + s, y + s / 2)
end

function M.icon_pause(x, y, s)
  local w = s * 0.3
  love.graphics.rectangle("fill", x + s * 0.12, y, w, s)
  love.graphics.rectangle("fill", x + s * 0.58, y, w, s)
end

function M.icon_folder(x, y, s)
  love.graphics.rectangle("fill", x, y + s * 0.12, s * 0.45, s * 0.25, 2, 2)
  love.graphics.rectangle("fill", x, y + s * 0.26, s, s * 0.64, 3, 3)
end

function M.icon_note(x, y, s)
  love.graphics.circle("fill", x + s * 0.28, y + s * 0.78, s * 0.2)
  love.graphics.rectangle("fill", x + s * 0.42, y + s * 0.08, s * 0.1, s * 0.72)
  love.graphics.polygon("fill", x + s * 0.52, y + s * 0.08, x + s * 0.92, y + s * 0.3, x + s * 0.52, y + s * 0.42)
end

function M.icon_speaker(x, y, s, volume)
  love.graphics.rectangle("fill", x, y + s * 0.34, s * 0.22, s * 0.32)
  love.graphics.polygon("fill", x + s * 0.22, y + s * 0.34, x + s * 0.5, y + s * 0.1, x + s * 0.5, y + s * 0.9, x + s * 0.22, y + s * 0.66)
  love.graphics.setLineWidth(2)
  if volume > 0 then
    love.graphics.arc("line", "open", x + s * 0.5, y + s * 0.5, s * 0.22, -0.9, 0.9)
  end
  if volume > 0.5 then
    love.graphics.arc("line", "open", x + s * 0.5, y + s * 0.5, s * 0.42, -0.9, 0.9)
  end
  if volume <= 0 then
    love.graphics.line(x + s * 0.65, y + s * 0.35, x + s * 0.95, y + s * 0.65)
    love.graphics.line(x + s * 0.65, y + s * 0.65, x + s * 0.95, y + s * 0.35)
  end
end

function M.icon_shuffle(x, y, s)
  love.graphics.setLineWidth(2)
  love.graphics.line(x, y + s * 0.72, x + s * 0.3, y + s * 0.72, x + s * 0.65, y + s * 0.28, x + s * 0.82, y + s * 0.28)
  love.graphics.line(x, y + s * 0.28, x + s * 0.3, y + s * 0.28, x + s * 0.65, y + s * 0.72, x + s * 0.82, y + s * 0.72)
  love.graphics.polygon("fill", x + s * 0.8, y + s * 0.1, x + s, y + s * 0.28, x + s * 0.8, y + s * 0.46)
  love.graphics.polygon("fill", x + s * 0.8, y + s * 0.54, x + s, y + s * 0.72, x + s * 0.8, y + s * 0.9)
end

function M.icon_repeat(x, y, s, one)
  local r, g, b, a = love.graphics.getColor()
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", x + 1, y + s * 0.2, s - 2, s * 0.6, 5, 5)
  -- gap on the top edge, then an arrowhead in the active colour
  love.graphics.setColor(M.c.bg[1], M.c.bg[2], M.c.bg[3], 1)
  love.graphics.rectangle("fill", x + s * 0.5, y + s * 0.1, s * 0.3, s * 0.2)
  love.graphics.setColor(r, g, b, a)
  love.graphics.polygon("fill", x + s * 0.5, y + s * 0.02, x + s * 0.5, y + s * 0.38, x + s * 0.82, y + s * 0.2)
  if one then
    love.graphics.setFont(M.f.tiny)
    love.graphics.printf("1", x, y + s * 0.5 - M.f.tiny:getHeight() / 2, s, "center")
  end
end

-- Toast ------------------------------------------------------------------------
local toast_text, toast_t = nil, 0

function M.toast(text, seconds)
  toast_text, toast_t = text, seconds or 1.3
end

function M.update(dt)
  if toast_t > 0 then
    toast_t = toast_t - dt
    if toast_t <= 0 then toast_text = nil end
  end
end

function M.draw_toast()
  if not toast_text then return end
  local f = M.f.body
  local w = f:getWidth(toast_text) + 32
  local x, y = (M.W - w) / 2, M.H - 96
  M.set(M.c.panel2, 0.96)
  love.graphics.rectangle("fill", x, y, w, 38, 10, 10)
  M.set(M.c.accent)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", x, y, w, 38, 10, 10)
  M.set(M.c.text)
  love.graphics.setFont(f)
  love.graphics.print(toast_text, x + 16, y + 38 / 2 - f:getHeight() / 2)
end

-- Draws a cover (or a placeholder) fitted inside a square box.
function M.draw_cover(cover, x, y, size)
  M.set(M.c.panel2)
  love.graphics.rectangle("fill", x, y, size, size, 8, 8)
  if cover then
    local w, h = cover:getDimensions()
    local s = math.min(size / w, size / h)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(cover, x + (size - w * s) / 2, y + (size - h * s) / 2, 0, s, s)
  else
    M.set(M.c.faint)
    local n = size * 0.45
    M.icon_note(x + (size - n) / 2, y + (size - n) / 2, n)
  end
end

-- Footer hints: list of { "A", "Abrir" } pairs, drawn as "[A] Abrir   [B] Voltar".
function M.hints(list, y)
  local f = M.f.small
  love.graphics.setFont(f)
  local gap = 14
  local total = 0
  local widths = {}
  for i, h in ipairs(list) do
    local kw = f:getWidth(h[1]) + 12
    local tw = f:getWidth(h[2])
    widths[i] = { kw, tw }
    total = total + kw + 5 + tw + (i > 1 and gap or 0)
  end
  local x = (M.W - total) / 2
  for i, h in ipairs(list) do
    local kw, tw = widths[i][1], widths[i][2]
    M.set(M.c.panel2)
    love.graphics.rectangle("fill", x, y, kw, f:getHeight() + 2, 5, 5)
    M.set(M.c.accent)
    love.graphics.print(h[1], x + 6, y + 1)
    M.set(M.c.dim)
    love.graphics.print(h[2], x + kw + 5, y + 1)
    x = x + kw + 5 + tw + gap
  end
end

return M
