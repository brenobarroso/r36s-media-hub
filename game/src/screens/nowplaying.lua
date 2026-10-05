-- "Now Playing" screen.
local app = require("src.app")
local ui = require("src.ui")
local player = require("src.player")
local input = require("src.input")
local U = require("src.util")

local N = {}

function N.enter() end
function N.update(dt) end

function N.action(a)
  if a == "accept" then
    player.toggle()
  elseif a == "back" then
    app.show("browser")
  elseif a == "left" then
    player.seek(-5)
  elseif a == "right" then
    player.seek(5)
  elseif a == "up" then
    ui.toast(string.format("Volume %d%%", math.floor(player.change_volume(0.05) * 100 + 0.5)))
  elseif a == "down" then
    ui.toast(string.format("Volume %d%%", math.floor(player.change_volume(-0.05) * 100 + 0.5)))
  elseif a == "x" then
    ui.toast(player.toggle_shuffle() and "Aleatório: ligado" or "Aleatório: desligado")
  elseif a == "y" then
    local m = player.cycle_repeat()
    local names = { off = "Repetir: desligado", all = "Repetir: todas", one = "Repetir: uma" }
    ui.toast(names[m])
  end
end

function N.draw()
  local cur = player.cur

  -- header
  ui.set(ui.c.panel)
  love.graphics.rectangle("fill", 0, 0, ui.W, 48)
  ui.set(ui.c.text)
  love.graphics.setFont(ui.f.head)
  love.graphics.print("Tocando agora", 16, 24 - ui.f.head:getHeight() / 2)
  if #player.order > 0 then
    ui.set(ui.c.dim)
    love.graphics.setFont(ui.f.small)
    love.graphics.printf(player.pos .. " / " .. #player.order, ui.W - 140, 24 - ui.f.small:getHeight() / 2, 124, "right")
  end

  if not cur then
    ui.set(ui.c.dim)
    love.graphics.setFont(ui.f.body)
    love.graphics.printf("Nada tocando.\nEscolha uma música no navegador.", 0, 190, ui.W, "center")
    if player.error then
      ui.set({ 1, 0.45, 0.45 })
      love.graphics.printf(player.error, 0, 260, ui.W, "center")
    end
  else
    -- cover
    ui.draw_cover(cur.cover, 32, 66, 244)

    -- info column
    local x, w = 300, ui.W - 300 - 24
    local elapsed = (player.clock or 0) - (player.started_at or 0)

    ui.set(ui.c.text)
    ui.marquee(cur.title, ui.f.title, x, 70, w, elapsed)

    ui.set(ui.c.accent)
    if cur.artist then ui.marquee(cur.artist, ui.f.sub, x, 118, w, elapsed) end

    ui.set(ui.c.dim)
    if cur.album then ui.marquee(cur.album, ui.f.body, x, 150, w, elapsed) end

    -- state row: play/pause + shuffle + repeat
    local ry = 214
    ui.set(ui.c.accent)
    if player.status == "playing" then
      ui.icon_pause(x, ry, 30)
    else
      ui.icon_play(x, ry, 30)
    end
    ui.set(ui.c.dim)
    love.graphics.setFont(ui.f.small)
    local label = ({ playing = "Tocando", paused = "Pausado", stopped = "Parado" })[player.status]
    love.graphics.print(label, x + 44, ry + 15 - ui.f.small:getHeight() / 2)

    ui.set(player.shuffle and ui.c.accent or ui.c.faint)
    ui.icon_shuffle(x + 150, ry + 3, 26)
    ui.set(player.repeat_mode ~= "off" and ui.c.accent or ui.c.faint)
    ui.icon_repeat(x + 196, ry + 3, 26, player.repeat_mode == "one")

    -- volume
    local vy = 266
    ui.set(ui.c.dim)
    ui.icon_speaker(x, vy, 24, player.volume)
    ui.bar(x + 36, vy + 9, w - 36 - 52, 6, player.volume)
    ui.set(ui.c.dim)
    love.graphics.setFont(ui.f.small)
    love.graphics.printf(math.floor(player.volume * 100 + 0.5) .. "%", x + w - 46, vy + 12 - ui.f.small:getHeight() / 2, 46, "right")

    if player.error then
      ui.set({ 1, 0.45, 0.45 })
      love.graphics.setFont(ui.f.small)
      love.graphics.print(ui.fit(ui.f.small, player.error, w), x, 310)
    end

    -- progress
    local pos = player.position()
    local frac = cur.duration and (pos / cur.duration) or 0
    ui.bar(32, 346, ui.W - 64, 8, frac)
    ui.set(ui.c.text)
    love.graphics.setFont(ui.f.small)
    love.graphics.print(U.fmt_time(pos), 32, 360)
    love.graphics.printf(U.fmt_time(cur.duration), ui.W - 32 - 100, 360, 100, "right")
  end

  local acc = input.swap_ab and "B" or "A"
  local bck = input.swap_ab and "A" or "B"
  ui.hints({
    { acc, "Pausa" }, { bck, "Voltar" }, { "Esq/Dir", "Buscar" }, { "Cima/Baixo", "Volume" },
  }, 410)
  ui.hints({
    { "L1", "Anterior" }, { "R1", "Próxima" }, { "X", "Aleatório" }, { "Y", "Repetir" },
  }, 440)
end

return N
