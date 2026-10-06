-- Settings Screen: Themes, Controls, Brightness, Screen Dimmer, Equalizer & Custom Media Directories.
local app = require("src.app")
local ui = require("src.ui")
local theme = require("src.theme")
local input = require("src.input")
local player = require("src.player")
local fs = require("src.fs")
local state = require("src.state")
local U = require("src.util")

local S = {
  sel = 1,
  scroll = 0,
}

-- Brightness helper for Linux / ArkOS sysfs
local function get_backlight_path()
  local candidates = {
    "/sys/class/backlight/backlight/brightness",
    "/sys/class/backlight/pwm-backlight/brightness",
  }
  for _, p in ipairs(candidates) do
    local f = io.open(p, "r")
    if f then f:close() return p end
  end
  return nil
end

local function set_system_brightness(pct)
  local path = get_backlight_path()
  if not path then return end
  local max = 255
  local max_path = path:gsub("brightness$", "max_brightness")
  local mf = io.open(max_path, "r")
  if mf then
    max = tonumber(mf:read("*l")) or 255
    mf:close()
  end
  local val = math.max(5, math.floor(max * (pct / 100)))
  local f = io.open(path, "w")
  if f then
    f:write(tostring(val))
    f:close()
  end
end

local DIM_OPTIONS = {
  { label = "Desativado", val = 0 },
  { label = "30 segundos", val = 30 },
  { label = "1 minuto", val = 60 },
  { label = "2 minutos", val = 120 },
  { label = "5 minutos", val = 300 },
}

local function get_dim_index(val)
  val = tonumber(val) or 0
  for i, opt in ipairs(DIM_OPTIONS) do
    if opt.val == val then return i end
  end
  return 1
end

function S.enter()
  S.media_dirs = {
    music = fs.find_media_root("music"),
    photos = fs.find_media_root("photos"),
    videos = fs.find_media_root("videos"),
    books = fs.find_media_root("books"),
  }
end

function S.action(a)
  local total_items = 10

  if a == "up" then
    S.sel = S.sel - 1
    if S.sel < 1 then S.sel = total_items end
  elseif a == "down" then
    S.sel = S.sel + 1
    if S.sel > total_items then S.sel = 1 end
  elseif a == "l1" then
    S.sel = math.max(1, S.sel - 5)
  elseif a == "r1" then
    S.sel = math.min(total_items, S.sel + 5)
  elseif a == "back" then
    app.show("home")
  elseif a == "accept" and S.sel >= 7 then
    -- Open folder picker for media directories
    local kinds = { "music", "photos", "videos", "books" }
    local k = kinds[S.sel - 6]
    if k then
      app.show("folder_picker", k)
    end
  elseif a == "left" or a == "right" or (a == "accept" and S.sel < 7) then
    local dir = (a == "left") and -1 or 1

    if S.sel == 1 then
      -- Theme
      theme.cycle()
      app.state.theme = theme.current_name
      ui.toast("Tema: " .. theme.get().name, 1.2)
    elseif S.sel == 2 then
      -- Button layout
      input.swap_ab = not input.swap_ab
      app.state.swap_ab = input.swap_ab and "1" or "0"
      ui.toast(input.swap_ab and "Layout: Xbox (B=Abrir, A=Voltar)" or "Layout: Nintendo (A=Abrir, B=Voltar)", 1.4)
    elseif S.sel == 3 then
      -- Brightness
      local cur = tonumber(app.state.brightness) or 80
      cur = U.clamp(cur + dir * 10, 10, 100)
      app.state.brightness = tostring(cur)
      set_system_brightness(cur)
      ui.toast(string.format("Brilho da Tela: %d%%", cur), 1.0)
    elseif S.sel == 4 then
      -- Screen Dimmer on playback
      local idx = get_dim_index(app.state.screen_dimmer)
      idx = idx + dir
      if idx < 1 then idx = #DIM_OPTIONS elseif idx > #DIM_OPTIONS then idx = 1 end
      app.state.screen_dimmer = tostring(DIM_OPTIONS[idx].val)
      ui.toast("Apagar tela em: " .. DIM_OPTIONS[idx].label, 1.3)
    elseif S.sel == 5 then
      -- Volume
      local v = player.change_volume(dir * 0.05)
      app.state.volume = string.format("%.2f", v)
      ui.toast(string.format("Volume: %d%%", math.floor(v * 100 + 0.5)), 1.0)
    elseif S.sel == 6 then
      -- Equalizer
      local eq_name = player.cycle_eq()
      if player.eq and player.eq.presets then
        app.state.eq = player.eq.presets[player.eq.current].id
      end
      ui.toast("Equalizador: " .. eq_name, 1.2)
    end
  end

  -- Scroll adjustment
  local VISIBLE = 6
  if S.sel <= S.scroll then
    S.scroll = S.sel - 1
  elseif S.sel > S.scroll + VISIBLE then
    S.scroll = S.sel - VISIBLE
  end
  S.scroll = math.max(0, S.scroll)
  return true
end

function S.update(dt)
end

function S.draw()
  -- Header
  ui.set(ui.c.panel)
  love.graphics.rectangle("fill", 0, 0, ui.W, 46)
  ui.set(ui.c.accent)
  ui.icon_gear(18, 11, 24)
  ui.set(ui.c.text)
  love.graphics.setFont(ui.f.head)
  love.graphics.print("Configurações do Sistema", 52, 23 - ui.f.head:getHeight() / 2)

  local items = {
    {
      title = "Tema Visual",
      desc = "Esquema de cores global da interface",
      val = theme.get().name,
      type = "select",
    },
    {
      title = "Layout dos Botões A/B",
      desc = "Inverter botões de ação e retorno",
      val = input.swap_ab and "Xbox (B confirma / A volta)" or "Nintendo (A confirma / B volta)",
      type = "select",
    },
    {
      title = "Brilho da Tela",
      desc = "Controle de iluminação do painel IPS",
      val = (app.state.brightness or "80") .. "%",
      type = "bar",
      frac = (tonumber(app.state.brightness) or 80) / 100,
    },
    {
      title = "Apagar Tela ao Tocar Música",
      desc = "Desliga o visor para economizar bateria",
      val = DIM_OPTIONS[get_dim_index(app.state.screen_dimmer)].label,
      type = "select",
    },
    {
      title = "Volume Principal",
      desc = "Volume padrão de saída de áudio",
      val = math.floor(player.volume * 100 + 0.5) .. "%",
      type = "bar",
      frac = player.volume,
    },
    {
      title = "Equalizador de Áudio",
      desc = "Predefinições de som (Bass Boost, Rock, Pop, etc.)",
      val = player.get_eq_name(),
      type = "select",
    },
    {
      title = "Pasta de Músicas",
      desc = "Definir diretório da biblioteca musical",
      val = (S.media_dirs and S.media_dirs.music) or fs.find_media_root("music"),
      type = "folder",
    },
    {
      title = "Pasta de Fotos",
      desc = "Definir diretório da galeria de fotos",
      val = (S.media_dirs and S.media_dirs.photos) or fs.find_media_root("photos"),
      type = "folder",
    },
    {
      title = "Pasta de Vídeos",
      desc = "Definir diretório de filmes e clipes",
      val = (S.media_dirs and S.media_dirs.videos) or fs.find_media_root("videos"),
      type = "folder",
    },
    {
      title = "Pasta de Livros",
      desc = "Definir diretório de PDF, EPUB e TXT",
      val = (S.media_dirs and S.media_dirs.books) or fs.find_media_root("books"),
      type = "folder",
    },
  }

  ui.set(ui.c.dim)
  love.graphics.setFont(ui.f.small)
  love.graphics.printf(S.sel .. " / " .. #items, ui.W - 140, 23 - ui.f.small:getHeight() / 2, 120, "right")

  local list_y = 52
  local row_h = 58
  local card_w = ui.W - 36
  local card_x = 18
  local VISIBLE = 6

  for i = 1, VISIBLE do
    local idx = S.scroll + i
    local item = items[idx]
    if not item then break end

    local y = list_y + (i - 1) * row_h
    local is_sel = (idx == S.sel)

    if is_sel then
      ui.set(ui.c.card_sel or ui.c.panel2)
      love.graphics.rectangle("fill", card_x, y, card_w, row_h - 6, 8, 8)
      ui.set(ui.c.card_border or ui.c.accent)
      love.graphics.setLineWidth(2)
      love.graphics.rectangle("line", card_x, y, card_w, row_h - 6, 8, 8)
      love.graphics.rectangle("fill", card_x, y + 6, 4, row_h - 18, 2, 2)
    else
      ui.set(ui.c.card_bg or ui.c.panel)
      love.graphics.rectangle("fill", card_x, y, card_w, row_h - 6, 8, 8)
    end

    -- Title & Description
    ui.set(is_sel and ui.c.text or ui.c.text, is_sel and 1.0 or 0.88)
    love.graphics.setFont(ui.f.bodyb)
    love.graphics.print(item.title, card_x + 18, y + 6)

    ui.set(ui.c.dim)
    love.graphics.setFont(ui.f.tiny)
    love.graphics.print(item.desc, card_x + 18, y + 28)

    -- Right side control
    local rw = 220
    local rx = card_x + card_w - rw - 14

    if item.type == "bar" then
      ui.bar(rx, y + 19, rw - 50, 8, item.frac)
      ui.set(ui.c.accent)
      love.graphics.setFont(ui.f.small)
      love.graphics.printf(item.val, rx + rw - 44, y + 23 - ui.f.small:getHeight() / 2, 44, "right")
    elseif item.type == "folder" then
      ui.set(ui.c.panel2)
      love.graphics.rectangle("fill", rx, y + 9, rw, 30, 6, 6)
      ui.set(is_sel and ui.c.accent or ui.c.text)
      love.graphics.setFont(ui.f.tiny)
      local path_fit = ui.fit(ui.f.tiny, item.val or "/", rw - 34)
      love.graphics.print(path_fit, rx + 10, y + 24 - ui.f.tiny:getHeight() / 2)
      ui.set(is_sel and ui.c.accent or ui.c.dim)
      love.graphics.setFont(ui.f.small)
      love.graphics.print(">", rx + rw - 18, y + 24 - ui.f.small:getHeight() / 2)
    else
      ui.set(ui.c.panel2)
      love.graphics.rectangle("fill", rx, y + 9, rw, 30, 6, 6)
      ui.set(is_sel and ui.c.accent or ui.c.text)
      love.graphics.setFont(ui.f.small)
      love.graphics.printf(is_sel and ("<  " .. item.val .. "  >") or item.val, rx, y + 24 - ui.f.small:getHeight() / 2, rw, "center")
    end
  end

  local acc = input.swap_ab and "B" or "A"
  local bck = input.swap_ab and "A" or "B"
  ui.hints({
    { "Esq/Dir", "Alterar" },
    { acc, "Confirmar / Mudar Pasta" },
    { bck, "Voltar" },
    { "L1/R1", "Rolar" },
  }, 448)
end

return S
