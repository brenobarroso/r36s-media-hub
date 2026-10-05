-- Home Screen (Media Hub): Músicas, Vídeos, Fotos, Livros.
local app = require("src.app")
local ui = require("src.ui")
local player = require("src.player")
local input = require("src.input")
local U = require("src.util")

local H = {
  sel = 1,
}

local CARDS = {
  {
    id = "music",
    title = "Músicas",
    sub = "Álbuns, faixas e reprodução",
    icon = "music",
    action = function()
      app.show("browser", app.root)
    end,
  },
  {
    id = "video",
    title = "Vídeos",
    sub = "Filmes, séries e clipes",
    icon = "video",
    action = function()
      if app.screens.videos then
        app.show("videos")
      else
        ui.toast("Módulo de Vídeos em breve!", 1.5)
      end
    end,
  },
  {
    id = "photo",
    title = "Fotos",
    sub = "Galeria, imagens e slideshow",
    icon = "photo",
    action = function()
      if app.screens.photos then
        app.show("photos")
      else
        ui.toast("Módulo de Fotos em breve!", 1.5)
      end
    end,
  },
  {
    id = "book",
    title = "Livros",
    sub = "EPUB, MOBI, TXT e mangás",
    icon = "book",
    action = function()
      if app.screens.books then
        app.show("books")
      else
        ui.toast("Módulo de Livros em breve!", 1.5)
      end
    end,
  },
}

-- Battery reading helper (Linux / ArkOS sysfs)
local function get_battery_info()
  local f = io.open("/sys/class/power_supply/battery/capacity", "r")
  if not f then return nil, false end
  local cap = tonumber(f:read("*l"))
  f:close()
  local charging = false
  local fs = io.open("/sys/class/power_supply/battery/status", "r")
  if fs then
    local st = fs:read("*l")
    fs:close()
    if st and st:lower():match("charging") then charging = true end
  end
  return cap, charging
end

function H.enter()
end

function H.action(a)
  if a == "up" then
    if H.sel > 2 then H.sel = H.sel - 2 end
  elseif a == "down" then
    if H.sel <= 2 then H.sel = H.sel + 2 end
  elseif a == "left" then
    if H.sel == 2 then H.sel = 1 elseif H.sel == 4 then H.sel = 3 end
  elseif a == "right" then
    if H.sel == 1 then H.sel = 2 elseif H.sel == 3 then H.sel = 4 end
  elseif a == "accept" then
    local card = CARDS[H.sel]
    if card and card.action then card.action() end
  elseif a == "select" or a == "y" then
    app.show("settings")
  elseif a == "x" then
    if player.cur then app.show("nowplaying") else ui.toast("Nenhuma música tocando", 1.2) end
  end
end

function H.update(dt)
end

local function draw_topbar()
  local h = 40
  ui.set(ui.c.panel)
  love.graphics.rectangle("fill", 0, 0, ui.W, h)

  -- App Title
  ui.set(ui.c.accent)
  love.graphics.circle("fill", 20, h / 2, 4)
  ui.set(ui.c.text)
  love.graphics.setFont(ui.f.head)
  love.graphics.print("R36S Media Hub", 32, h / 2 - ui.f.head:getHeight() / 2)

  -- Settings hint button in top bar (fixed position)
  local cfg_x = 210
  local cfg_w = 124
  ui.set(ui.c.panel2)
  love.graphics.rectangle("fill", cfg_x, 8, cfg_w, 24, 4, 4)
  ui.set(ui.c.accent)
  love.graphics.setFont(ui.f.tiny)
  love.graphics.print("SELECT / Y", cfg_x + 6, 8 + 12 - ui.f.tiny:getHeight() / 2)
  ui.set(ui.c.dim)
  love.graphics.print("Configs", cfg_x + 72, 8 + 12 - ui.f.tiny:getHeight() / 2)

  -- Right side: Clock
  local clock = os.date("%H:%M")
  love.graphics.setFont(ui.f.small)
  local cw = ui.f.small:getWidth(clock)
  local clock_x = ui.W - 20 - cw
  ui.set(ui.c.text)
  love.graphics.print(clock, clock_x, h / 2 - ui.f.small:getHeight() / 2)

  -- Battery (left of clock)
  local cap, charging = get_battery_info()
  if cap then
    local bx = clock_x - 56
    ui.icon_battery(bx, h / 2 - 10, 20, cap, charging)
    ui.set(ui.c.dim)
    love.graphics.setFont(ui.f.tiny)
    local bw = ui.f.tiny:getWidth(cap .. "%")
    love.graphics.print(cap .. "%", bx - bw - 4, h / 2 - ui.f.tiny:getHeight() / 2)
  end
end

local function draw_mini_player()
  local y, h = 372, 58
  ui.set(ui.c.panel)
  love.graphics.rectangle("fill", 16, y, ui.W - 32, h, 8, 8)

  local cur = player.cur
  if not cur then return end

  ui.draw_cover(cur.cover, 24, y + 6, 46)

  local tx, tw = 80, ui.W - 80 - 70
  ui.set(ui.c.text)
  love.graphics.setFont(ui.f.bodyb)
  love.graphics.print(ui.fit(ui.f.bodyb, cur.title, tw), tx, y + 6)
  ui.set(ui.c.dim)
  love.graphics.setFont(ui.f.small)
  love.graphics.print(ui.fit(ui.f.small, cur.artist or cur.album or "", tw), tx, y + 28)

  ui.set(ui.c.accent)
  if player.status == "playing" then
    ui.icon_pause(ui.W - 54, y + 17, 24)
  else
    ui.icon_play(ui.W - 54, y + 17, 24)
  end

  local frac = 0
  if cur.duration then frac = player.position() / cur.duration end
  ui.bar(tx, y + h - 6, ui.W - 80 - 24 - 40, 3, frac)
end

function H.draw()
  draw_topbar()

  -- 2x2 Media Cards
  local has_mini = (player.cur ~= nil)
  local card_w = 286
  local card_h = has_mini and 144 or 176
  local start_y = has_mini and 50 or 58
  local col_gap = 20
  local row_gap = has_mini and 12 or 18

  for i, card in ipairs(CARDS) do
    local col = (i - 1) % 2
    local row = math.floor((i - 1) / 2)
    local x = 24 + col * (card_w + col_gap)
    local y = start_y + row * (card_h + row_gap)
    local is_sel = (i == H.sel)

    -- Card background
    if is_sel then
      ui.set(ui.c.card_sel or ui.c.panel2)
      love.graphics.rectangle("fill", x, y, card_w, card_h, 12, 12)
      ui.set(ui.c.card_border or ui.c.accent)
      love.graphics.setLineWidth(2.5)
      love.graphics.rectangle("line", x, y, card_w, card_h, 12, 12)
    else
      ui.set(ui.c.card_bg or ui.c.panel)
      love.graphics.rectangle("fill", x, y, card_w, card_h, 12, 12)
      ui.set(ui.c.panel2)
      love.graphics.setLineWidth(1)
      love.graphics.rectangle("line", x, y, card_w, card_h, 12, 12)
    end

    -- Icon circle badge
    local icon_box = 48
    local ix = x + 20
    local iy = y + (card_h / 2) - (icon_box / 2)
    ui.set(is_sel and ui.c.accent or ui.c.panel2, is_sel and 0.22 or 0.6)
    love.graphics.rectangle("fill", ix, iy, icon_box, icon_box, 10, 10)

    ui.set(is_sel and ui.c.accent or ui.c.text)
    if card.icon == "music" then
      ui.icon_music(ix + 6, iy + 6, 36)
    elseif card.icon == "video" then
      ui.icon_video(ix + 6, iy + 6, 36)
    elseif card.icon == "photo" then
      ui.icon_photo(ix + 6, iy + 6, 36)
    elseif card.icon == "book" then
      ui.icon_book(ix + 6, iy + 6, 36)
    end

    -- Text
    local tx = ix + icon_box + 16
    local tw = card_w - (tx - x) - 12
    ui.set(is_sel and ui.c.text or ui.c.text, is_sel and 1.0 or 0.88)
    love.graphics.setFont(ui.f.head)
    love.graphics.print(card.title, tx, iy + 4)

    ui.set(ui.c.dim)
    love.graphics.setFont(ui.f.tiny)
    love.graphics.printf(card.sub, tx, iy + 28, tw, "left")
  end

  if has_mini then
    draw_mini_player()
  end

  local acc = input.swap_ab and "B" or "A"
  local hints = {
    { acc, "Abrir" },
    { "SELECT / Y", "Configs" },
  }
  if has_mini then
    hints[#hints + 1] = { "X", "Tocando" }
    hints[#hints + 1] = { "START", "Pausa" }
  end
  hints[#hints + 1] = { "SELECT+START", "Sair" }

  ui.hints(hints, 448)
end

return H
