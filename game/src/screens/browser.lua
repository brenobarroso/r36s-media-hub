-- Folder browser screen.
local app = require("src.app")
local ui = require("src.ui")
local fs = require("src.fs")
local player = require("src.player")
local input = require("src.input")
local U = require("src.util")

local B = {}

local HEADER_H = 48
local LIST_Y = 54
local ROW_H = 32
local ROWS = 10

local dir = nil
local entries = {}
local sel, scroll = 1, 0

local function clamp_view()
  sel = U.clamp(sel, 1, math.max(1, #entries))
  if sel <= scroll then scroll = sel - 1 end
  if sel > scroll + ROWS then scroll = sel - ROWS end
  scroll = U.clamp(scroll, 0, math.max(0, #entries - ROWS))
end

function B.enter(path, select_name)
  if not path then return end -- coming back from another screen: keep state
  dir = path
  entries = fs.list(dir)
  sel, scroll = 1, 0
  if select_name then
    for i, e in ipairs(entries) do
      if e.file == select_name then sel = i break end
    end
  end
  clamp_view()
  app.state.last_dir = dir
end

function B.current_dir()
  return dir
end

local function play_file(e)
  local paths, idx = {}, 1
  for _, x in ipairs(entries) do
    if not x.is_dir then
      paths[#paths + 1] = x.path
      if x.path == e.path then idx = #paths end
    end
  end
  if player.play_queue(paths, idx) then
    app.show("nowplaying")
  else
    ui.toast(player.error or "Não foi possível tocar", 2)
  end
end

local function play_folder(path)
  local paths = fs.collect(path)
  if #paths == 0 then
    ui.toast("Nenhuma música nessa pasta", 1.6)
    return
  end
  if player.play_queue(paths, 1) then
    app.show("nowplaying")
  else
    ui.toast(player.error or "Não foi possível tocar", 2)
  end
end

function B.action(a)
  local e = entries[sel]
  if a == "up" then
    sel = sel - 1
  elseif a == "down" then
    sel = sel + 1
  elseif a == "left" then
    sel = sel - ROWS
  elseif a == "right" then
    sel = sel + ROWS
  elseif a == "accept" then
    if e then
      if e.is_dir then B.enter(e.path) else play_file(e) end
    end
  elseif a == "back" then
    if dir ~= app.root then
      B.enter(U.dirname(dir), U.basename(dir))
    else
      app.show("home")
    end
  elseif a == "x" then
    if player.cur then app.show("nowplaying") else ui.toast("Nada tocando ainda", 1.4) end
  elseif a == "y" then
    if e and e.is_dir then play_folder(e.path) else play_folder(dir) end
  end
  clamp_view()
end

function B.update(dt) end

local function draw_mini_player()
  local y, h = 376, 62
  ui.set(ui.c.panel)
  love.graphics.rectangle("fill", 12, y, ui.W - 24, h, 10, 10)

  local cur = player.cur
  if not cur then
    ui.set(ui.c.dim)
    love.graphics.setFont(ui.f.body)
    love.graphics.print("Nada tocando", 28, y + h / 2 - ui.f.body:getHeight() / 2)
    return
  end

  ui.draw_cover(cur.cover, 20, y + 6, 44)

  local tx, tw = 76, ui.W - 76 - 70
  ui.set(ui.c.text)
  love.graphics.setFont(ui.f.bodyb)
  love.graphics.print(ui.fit(ui.f.bodyb, cur.title, tw), tx, y + 5)
  ui.set(ui.c.dim)
  love.graphics.setFont(ui.f.small)
  love.graphics.print(ui.fit(ui.f.small, cur.artist or cur.album or "", tw), tx, y + 29)

  -- play / pause state
  ui.set(ui.c.accent)
  if player.status == "playing" then
    ui.icon_pause(ui.W - 58, y + 16, 24)
  else
    ui.icon_play(ui.W - 58, y + 16, 24)
  end

  -- progress
  local frac = 0
  if cur.duration then frac = player.position() / cur.duration end
  ui.bar(tx, y + h - 7, ui.W - 76 - 24 - 36, 3, frac)
end

function B.draw()
  -- header
  ui.set(ui.c.panel)
  love.graphics.rectangle("fill", 0, 0, ui.W, HEADER_H)
  ui.set(ui.c.accent)
  ui.icon_folder(16, 13, 24)
  local title = (dir == app.root) and "Músicas" or U.sanitize(U.basename(dir))
  ui.set(ui.c.text)
  love.graphics.setFont(ui.f.head)
  love.graphics.print(ui.fit(ui.f.head, title, ui.W - 160), 52, HEADER_H / 2 - ui.f.head:getHeight() / 2)
  ui.set(ui.c.dim)
  love.graphics.setFont(ui.f.small)
  local count = (#entries > 0) and (sel .. " / " .. #entries) or "0"
  love.graphics.printf(count, ui.W - 120, HEADER_H / 2 - ui.f.small:getHeight() / 2, 104, "right")

  -- list
  if #entries == 0 then
    ui.set(ui.c.dim)
    love.graphics.setFont(ui.f.body)
    love.graphics.printf("Pasta vazia", 0, LIST_Y + 110, ui.W, "center")
  end

  local cur_path = player.cur and player.cur.path
  for row = 1, ROWS do
    local i = scroll + row
    local e = entries[i]
    if not e then break end
    local y = LIST_Y + (row - 1) * ROW_H
    local is_sel = (i == sel)
    local playing = (e.path == cur_path)

    if is_sel then
      ui.set(ui.c.accent, 0.16)
      love.graphics.rectangle("fill", 8, y, ui.W - 28, ROW_H - 2, 8, 8)
      ui.set(ui.c.accent)
      love.graphics.rectangle("fill", 8, y + 5, 4, ROW_H - 12, 2, 2)
    end

    if e.is_dir then
      ui.set(is_sel and ui.c.accent or ui.c.dim)
      ui.icon_folder(22, y + 6, 20)
    else
      ui.set(playing and ui.c.accent or ui.c.dim)
      ui.icon_note(24, y + 6, 20)
    end

    if playing then ui.set(ui.c.accent) elseif is_sel then ui.set(ui.c.text) else ui.set(ui.c.text, 0.82) end
    love.graphics.setFont(ui.f.body)
    love.graphics.print(ui.fit(ui.f.body, e.name, ui.W - 120), 54, y + (ROW_H - 2) / 2 - ui.f.body:getHeight() / 2)

    if playing then
      ui.set(ui.c.accent)
      if player.status == "playing" then ui.icon_play(ui.W - 54, y + 9, 13) else ui.icon_pause(ui.W - 54, y + 9, 13) end
    end
  end

  -- scrollbar
  if #entries > ROWS then
    local track_h = ROWS * ROW_H - 4
    ui.set(ui.c.faint, 0.5)
    love.graphics.rectangle("fill", ui.W - 14, LIST_Y, 4, track_h, 2, 2)
    local th = math.max(24, track_h * ROWS / #entries)
    local ty = LIST_Y + (track_h - th) * (scroll / math.max(1, #entries - ROWS))
    ui.set(ui.c.accent)
    love.graphics.rectangle("fill", ui.W - 14, ty, 4, th, 2, 2)
  end

  draw_mini_player()

  local acc = input.swap_ab and "B" or "A"
  local bck = input.swap_ab and "A" or "B"
  ui.hints({
    { acc, "Abrir" }, { bck, "Voltar" }, { "X", "Tocando" }, { "Y", "Tocar pasta" }, { "START", "Pausa" },
  }, 448)
end

return B
