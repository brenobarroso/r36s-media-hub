-- Interactive Folder Picker for custom media directories.
local app = require("src.app")
local ui = require("src.ui")
local fs = require("src.fs")
local input = require("src.input")
local state = require("src.state")
local U = require("src.util")

local FP = {
  kind = "music",        -- "music" | "photos" | "videos" | "books"
  dir = "/",
  dirs = {},
  sel = 1,
  scroll = 0,
}

local LABELS = {
  music = "Músicas",
  photos = "Fotos",
  videos = "Vídeos",
  books = "Livros (PDF, EPUB, TXT)",
}

local function scan_dirs(path)
  local list = fs.list(path)
  local dirs = {}
  -- If not at root, add parent directory ".."
  if path ~= "/" and path ~= "" and path ~= "C:/" and path ~= "C:\\" then
    dirs[#dirs + 1] = {
      name = ".. (Subir pasta)",
      file = "..",
      path = U.dirname(path),
      is_parent = true,
    }
  end

  for _, e in ipairs(list) do
    if e.is_dir then
      dirs[#dirs + 1] = {
        name = e.name,
        file = e.file,
        path = e.path,
        is_parent = false,
      }
    end
  end
  return dirs
end

function FP.enter(kind, initial_dir)
  FP.kind = kind or "music"
  local start = initial_dir or app.state[FP.kind .. "_dir"]
  if not start or not fs.dir_exists(start) then
    start = fs.find_media_root(FP.kind)
  end
  if not start or not fs.dir_exists(start) then
    start = U.is_windows() and "C:/" or (fs.dir_exists("/roms") and "/roms" or "/")
  end

  FP.dir = start
  FP.dirs = scan_dirs(FP.dir)
  FP.sel = 1
  FP.scroll = 0
end

local function select_current_folder()
  local key = FP.kind .. "_dir"
  app.state[key] = FP.dir
  local singular = FP.kind:gsub("s$", "") .. "_dir"
  app.state[singular] = FP.dir
  state.save(app.state)

  -- If music dir changed, update app.root
  if FP.kind == "music" then
    app.root = FP.dir
  elseif FP.kind == "photos" and app.screens.photos then
    app.screens.photos.dir = nil
  elseif FP.kind == "videos" and app.screens.videos then
    app.screens.videos.dir = nil
  elseif FP.kind == "books" and app.screens.books then
    app.screens.books.dir = nil
  end

  if fs.clear_cache then fs.clear_cache() end

  ui.toast("Pasta de " .. (LABELS[FP.kind] or "Mídia") .. " definida!", 1.5)
  app.show("settings")
end

function FP.action(a)
  local total = #FP.dirs

  if a == "up" then
    FP.sel = FP.sel - 1
    if FP.sel < 1 then FP.sel = math.max(1, total) end
  elseif a == "down" then
    FP.sel = FP.sel + 1
    if FP.sel > total then FP.sel = 1 end
  elseif a == "left" or a == "l1" then
    FP.sel = math.max(1, FP.sel - 6)
  elseif a == "right" or a == "r1" then
    FP.sel = math.min(total, FP.sel + 6)
  elseif a == "back" then
    if FP.dir ~= "/" and FP.dir ~= "C:/" and FP.dir ~= "" then
      FP.dir = U.dirname(FP.dir)
      FP.dirs = scan_dirs(FP.dir)
      FP.sel = 1
      FP.scroll = 0
    else
      app.show("settings")
    end
  elseif a == "accept" then
    local d = FP.dirs[FP.sel]
    if d then
      FP.dir = d.path
      FP.dirs = scan_dirs(FP.dir)
      FP.sel = 1
      FP.scroll = 0
    end
  elseif a == "start" or a == "x" then
    select_current_folder()
  end

  -- Scroll adjustment
  local VISIBLE = 6
  if FP.sel <= FP.scroll then
    FP.scroll = FP.sel - 1
  elseif FP.sel > FP.scroll + VISIBLE then
    FP.scroll = FP.sel - VISIBLE
  end
  FP.scroll = math.max(0, FP.scroll)
  return true
end

function FP.update(dt)
end

function FP.draw()
  -- Header
  ui.set(ui.c.panel)
  love.graphics.rectangle("fill", 0, 0, ui.W, 44)
  ui.set(ui.c.accent)
  ui.icon_folder(18, 10, 24)
  ui.set(ui.c.text)
  love.graphics.setFont(ui.f.head)
  local title = "Escolher Pasta de " .. (LABELS[FP.kind] or "Mídia")
  love.graphics.print(title, 52, 22 - ui.f.head:getHeight() / 2)

  -- Current Path Bar
  local py = 50
  ui.set(ui.c.panel2)
  love.graphics.rectangle("fill", 16, py, ui.W - 32, 34, 6, 6)
  ui.set(ui.c.dim)
  love.graphics.setFont(ui.f.tiny)
  love.graphics.print("Caminho atual:", 28, py + 17 - ui.f.tiny:getHeight() / 2)
  ui.set(ui.c.accent)
  love.graphics.setFont(ui.f.small)
  local path_fit = ui.fit(ui.f.small, FP.dir, ui.W - 170)
  love.graphics.print(path_fit, 130, py + 17 - ui.f.small:getHeight() / 2)

  -- Directory List
  local list_y = 92
  local row_h = 50
  local card_w = ui.W - 32
  local card_x = 16
  local VISIBLE = 6

  if #FP.dirs == 0 then
    ui.set(ui.c.dim)
    love.graphics.setFont(ui.f.body)
    love.graphics.printf("Nenhuma subpasta aqui.\nAperte START ou X para selecionar esta pasta!", 0, 200, ui.W, "center")
  end

  for i = 1, VISIBLE do
    local idx = FP.scroll + i
    local d = FP.dirs[idx]
    if not d then break end

    local y = list_y + (i - 1) * (row_h + 4)
    local is_sel = (idx == FP.sel)

    if is_sel then
      ui.set(ui.c.card_sel or ui.c.panel2)
      love.graphics.rectangle("fill", card_x, y, card_w, row_h, 6, 6)
      ui.set(ui.c.card_border or ui.c.accent)
      love.graphics.setLineWidth(2)
      love.graphics.rectangle("line", card_x, y, card_w, row_h, 6, 6)
      love.graphics.rectangle("fill", card_x, y + 6, 4, row_h - 12, 2, 2)
    else
      ui.set(ui.c.card_bg or ui.c.panel)
      love.graphics.rectangle("fill", card_x, y, card_w, row_h, 6, 6)
    end

    -- Icon
    ui.set(is_sel and ui.c.accent or ui.c.dim)
    ui.icon_folder(card_x + 14, y + 13, 24)

    -- Folder name
    ui.set(is_sel and ui.c.text or ui.c.text, is_sel and 1.0 or 0.88)
    love.graphics.setFont(ui.f.body)
    love.graphics.print(ui.fit(ui.f.body, d.name, card_w - 90), card_x + 48, y + 12)

    -- Enter arrow
    ui.set(is_sel and ui.c.accent or ui.c.faint)
    love.graphics.setFont(ui.f.small)
    love.graphics.print(">", card_x + card_w - 24, y + 25 - ui.f.small:getHeight() / 2)
  end

  -- Action Banner at bottom
  local acc = input.swap_ab and "B" or "A"
  local bck = input.swap_ab and "A" or "B"
  ui.hints({
    { acc, "Entrar" },
    { "START / X", "SELECIONAR ESTA PASTA" },
    { bck, "Voltar" },
  }, 448)
end

return FP
