local utf8 = require("utf8")
local theme = require("src.theme")

local M = {}

M.W, M.H = 640, 480

-- Dynamic access to the active theme palette
M.c = setmetatable({}, {
  __index = function(_, k)
    return theme.get()[k]
  end,
})

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

function M.icon_music(x, y, s)
  -- Beamed eighth notes
  local r = s * 0.16
  love.graphics.circle("fill", x + s * 0.28, y + s * 0.76, r)
  love.graphics.circle("fill", x + s * 0.72, y + s * 0.64, r)
  love.graphics.setLineWidth(s * 0.09)
  love.graphics.line(x + s * 0.36, y + s * 0.76, x + s * 0.36, y + s * 0.22)
  love.graphics.line(x + s * 0.80, y + s * 0.64, x + s * 0.80, y + s * 0.10)
  love.graphics.line(x + s * 0.34, y + s * 0.22, x + s * 0.82, y + s * 0.10)
end

function M.icon_video(x, y, s)
  -- Clapperboard / movie screen
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", x + s * 0.08, y + s * 0.15, s * 0.84, s * 0.70, 4, 4)
  local ps = s * 0.32
  local px, py = x + s * 0.40, y + s * 0.34
  love.graphics.polygon("fill", px, py, px, py + ps, px + ps * 0.86, py + ps / 2)
end

function M.icon_photo(x, y, s)
  -- Photo frame with sun & mountains
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", x + s * 0.08, y + s * 0.12, s * 0.84, s * 0.76, 4, 4)
  love.graphics.circle("fill", x + s * 0.68, y + s * 0.34, s * 0.10)
  -- Mountains
  love.graphics.polygon("fill", x + s * 0.16, y + s * 0.78, x + s * 0.44, y + s * 0.44, x + s * 0.62, y + s * 0.78)
  love.graphics.polygon("fill", x + s * 0.48, y + s * 0.78, x + s * 0.68, y + s * 0.54, x + s * 0.84, y + s * 0.78)
end

function M.icon_book(x, y, s)
  -- Open book
  love.graphics.setLineWidth(2)
  local mx, my = x + s * 0.50, y + s * 0.78
  local lw, rw = x + s * 0.12, x + s * 0.88
  local ty = y + s * 0.22
  love.graphics.line(mx, my, mx, ty + s * 0.08)
  love.graphics.line(mx, ty + s * 0.08, lw, ty)
  love.graphics.line(lw, ty, lw, my - s * 0.08)
  love.graphics.line(lw, my - s * 0.08, mx, my)
  love.graphics.line(mx, ty + s * 0.08, rw, ty)
  love.graphics.line(rw, ty, rw, my - s * 0.08)
  love.graphics.line(rw, my - s * 0.08, mx, my)
end

function M.icon_gear(x, y, s)
  -- Settings cog
  local cx, cy = x + s * 0.5, y + s * 0.5
  local r_out = s * 0.42
  local r_in = s * 0.20
  love.graphics.setLineWidth(s * 0.12)
  love.graphics.circle("line", cx, cy, (r_out + r_in) / 2)
  for i = 0, 7 do
    local ang = i * (math.pi / 4)
    local x1 = cx + math.cos(ang) * (r_in + 2)
    local y1 = cy + math.sin(ang) * (r_in + 2)
    local x2 = cx + math.cos(ang) * (r_out + 3)
    local y2 = cy + math.sin(ang) * (r_out + 3)
    love.graphics.line(x1, y1, x2, y2)
  end
  love.graphics.circle("fill", cx, cy, r_in * 0.6)
end

function M.icon_battery(x, y, s, pct, charging)
  love.graphics.setLineWidth(2)
  local bw, bh = s * 0.72, s * 0.42
  local bx = x + s * 0.10
  local by = y + (s - bh) / 2
  love.graphics.rectangle("line", bx, by, bw, bh, 2, 2)
  -- Terminal nub
  love.graphics.rectangle("fill", bx + bw + 1, by + bh * 0.28, s * 0.07, bh * 0.44, 1, 1)
  -- Fill
  local fill_w = math.max(0, math.min(1, (pct or 100) / 100)) * (bw - 4)
  if fill_w > 0 then
    if (pct or 100) > 30 then
      M.set(M.c.accent)
    elseif (pct or 100) > 15 then
      love.graphics.setColor(0.95, 0.75, 0.20, 1)
    else
      love.graphics.setColor(0.95, 0.30, 0.30, 1)
    end
    love.graphics.rectangle("fill", bx + 2, by + 2, fill_w, bh - 4, 1, 1)
  end
  if charging then
    love.graphics.setColor(1, 0.9, 0.2, 1)
    love.graphics.polygon("fill", bx + bw * 0.55, by - 1, bx + bw * 0.35, by + bh * 0.55, bx + bw * 0.50, by + bh * 0.55,
      bx + bw * 0.45, by + bh + 1, bx + bw * 0.68, by + bh * 0.40, bx + bw * 0.52, by + bh * 0.40)
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
