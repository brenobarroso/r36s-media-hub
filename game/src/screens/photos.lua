-- Photo Gallery: folder navigation & thumbnail grid.
local app = require("src.app")
local ui = require("src.ui")
local fs = require("src.fs")
local input = require("src.input")
local player = require("src.player")
local U = require("src.util")

local P = {
  dir = nil,
  entries = {},
  photos_only = {},
  sel = 1,
  scroll = 0,
  thumb_cache = {},
}

local COLS = 4
local ROWS = 3
local PAGE = COLS * ROWS

local PHOTO_EXT = {
  jpg = true, jpeg = true, png = true, bmp = true, webp = true,
}

local function find_photo_root()
  local candidates
  if U.is_windows() then
    candidates = {
      (os.getenv("USERPROFILE") or "C:") .. "/Pictures",
      "C:/Users/barro/.gemini/antigravity/scratch/testphotos",
      "C:/",
    }
  else
    local home = os.getenv("HOME") or "/root"
    candidates = {
      "/roms2/photos", "/roms2/Photos", "/roms/photos", "/roms/Photos",
      "/roms2/pictures", "/roms2/Pictures", "/roms/pictures", "/roms/Pictures",
      "/roms2/media/photos", "/roms/media/photos", home .. "/Pictures", "/roms", "/",
    }
  end
  for _, c in ipairs(candidates) do
    if fs.dir_exists(c) then return c end
  end
  return "/"
end

local function load_thumbnail(path)
  if P.thumb_cache[path] then return P.thumb_cache[path] end
  local f = io.open(path, "rb")
  if not f then return nil end
  local data = f:read("*a")
  f:close()
  if not data or #data == 0 then return nil end

  local ok, img = pcall(function()
    local fd = love.filesystem.newFileData(data, U.basename(path))
    local imd = love.image.newImageData(fd)
    -- If image is larger than 256x256, downscale into small canvas to save RAM
    local iw, ih = imd:getDimensions()
    local max_dim = 160
    if math.max(iw, ih) > max_dim then
      local s = max_dim / math.max(iw, ih)
      local cw, ch = math.max(1, math.floor(iw * s)), math.max(1, math.floor(ih * s))
      local raw = love.graphics.newImage(imd)
      local canvas = love.graphics.newCanvas(cw, ch)
      local prev = love.graphics.getCanvas()
      love.graphics.setCanvas(canvas)
      love.graphics.clear(0, 0, 0, 1)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(raw, 0, 0, 0, s, s)
      love.graphics.setCanvas(prev)
      raw:release()
      return canvas
    else
      local i = love.graphics.newImage(imd)
      i:setFilter("linear", "linear")
      return i
    end
  end)

  if ok and img then
    P.thumb_cache[path] = img
    return img
  end
  return nil
end

function P.enter(dir_path)
  P.dir = dir_path or P.dir or find_photo_root()
  P.entries = {}
  P.photos_only = {}
  P.sel = 1
  P.scroll = 0

  local list = fs.list(P.dir)
  for _, e in ipairs(list) do
    if e.is_dir or PHOTO_EXT[U.ext(e.file)] then
      P.entries[#P.entries + 1] = e
      if not e.is_dir then
        P.photos_only[#P.photos_only + 1] = e.path
      end
    end
  end
end

function P.action(a)
  local total = #P.entries

  if a == "up" then
    if P.sel > COLS then
      P.sel = P.sel - COLS
    else
      if P.scroll > 0 then
        P.scroll = P.scroll - COLS
      end
    end
  elseif a == "down" then
    if P.sel + COLS <= total then
      P.sel = P.sel + COLS
    end
  elseif a == "left" then
    if P.sel > 1 then P.sel = P.sel - 1 end
  elseif a == "right" then
    if P.sel < total then P.sel = P.sel + 1 end
  elseif a == "back" then
    local root = find_photo_root()
    if P.dir ~= root and P.dir ~= "/" then
      P.enter(U.dirname(P.dir))
    else
      app.show("home")
    end
  elseif a == "accept" then
    local e = P.entries[P.sel]
    if e then
      if e.is_dir then
        P.enter(e.path)
      else
        -- Find index in photos_only
        local pidx = 1
        for idx, ppath in ipairs(P.photos_only) do
          if ppath == e.path then pidx = idx break end
        end
        app.show("photo_viewer", P.photos_only, pidx)
      end
    end
  elseif a == "start" then
    if #P.photos_only > 0 then
      app.show("photo_viewer", P.photos_only, 1)
      app.screens.photo_viewer.slideshow = true
      ui.toast("Iniciando Slideshow...", 1.2)
    else
      ui.toast("Nenhuma foto nesta pasta", 1.2)
    end
  end

  -- Keep selected item inside visible rows
  if P.sel <= P.scroll then
    P.scroll = math.floor((P.sel - 1) / COLS) * COLS
  elseif P.sel > P.scroll + PAGE then
    P.scroll = math.floor((P.sel - 1) / COLS) * COLS - (ROWS - 1) * COLS
  end
  P.scroll = math.max(0, P.scroll)
end

function P.update(dt)
end

function P.draw()
  -- Header
  ui.set(ui.c.panel)
  love.graphics.rectangle("fill", 0, 0, ui.W, 44)
  ui.set(ui.c.accent)
  ui.icon_photo(18, 10, 24)
  ui.set(ui.c.text)
  love.graphics.setFont(ui.f.head)
  local title = (P.dir == find_photo_root()) and "Galeria de Fotos" or U.basename(P.dir)
  love.graphics.print(ui.fit(ui.f.head, title, ui.W - 180), 52, 22 - ui.f.head:getHeight() / 2)

  ui.set(ui.c.dim)
  love.graphics.setFont(ui.f.small)
  local count_text = (#P.entries > 0) and (P.sel .. " / " .. #P.entries) or "Vazio"
  love.graphics.printf(count_text, ui.W - 140, 22 - ui.f.small:getHeight() / 2, 120, "right")

  if #P.entries == 0 then
    ui.set(ui.c.dim)
    love.graphics.setFont(ui.f.body)
    love.graphics.printf("Nenhuma foto ou pasta encontrada.\nColoque imagens em /roms2/photos", 0, 200, ui.W, "center")
  end

  -- 4x3 Thumbnail Grid
  local card_w = 138
  local card_h = 114
  local start_x = 24
  local start_y = 54
  local gap_x = 16
  local gap_y = 12

  for i = 1, PAGE do
    local idx = P.scroll + i
    local e = P.entries[idx]
    if not e then break end

    local col = (i - 1) % COLS
    local row = math.floor((i - 1) / COLS)
    local x = start_x + col * (card_w + gap_x)
    local y = start_y + row * (card_h + gap_y)
    local is_sel = (idx == P.sel)

    -- Card background
    if is_sel then
      ui.set(ui.c.card_sel or ui.c.panel2)
      love.graphics.rectangle("fill", x, y, card_w, card_h, 8, 8)
      ui.set(ui.c.card_border or ui.c.accent)
      love.graphics.setLineWidth(2)
      love.graphics.rectangle("line", x, y, card_w, card_h, 8, 8)
    else
      ui.set(ui.c.card_bg or ui.c.panel)
      love.graphics.rectangle("fill", x, y, card_w, card_h, 8, 8)
    end

    -- Image / Folder content
    local box_w, box_h = card_w - 12, 74
    local bx, by = x + 6, y + 6
    ui.set(ui.c.panel2)
    love.graphics.rectangle("fill", bx, by, box_w, box_h, 4, 4)

    if e.is_dir then
      ui.set(is_sel and ui.c.accent or ui.c.dim)
      ui.icon_folder(bx + (box_w - 36) / 2, by + (box_h - 36) / 2, 36)
    else
      local thumb = load_thumbnail(e.path)
      if thumb then
        local tw, th = thumb:getDimensions()
        local s = math.min(box_w / tw, box_h / th)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(thumb, bx + (box_w - tw * s) / 2, by + (box_h - th * s) / 2, 0, s, s)
      else
        ui.set(ui.c.faint)
        ui.icon_photo(bx + (box_w - 32) / 2, by + (box_h - 32) / 2, 32)
      end
    end

    -- Title
    ui.set(is_sel and ui.c.text or ui.c.dim)
    love.graphics.setFont(ui.f.tiny)
    love.graphics.print(ui.fit(ui.f.tiny, e.name, card_w - 12), x + 6, y + box_h + 10)
  end

  local acc = input.swap_ab and "B" or "A"
  local bck = input.swap_ab and "A" or "B"
  ui.hints({
    { acc, "Abrir" },
    { bck, "Voltar" },
    { "START", "Slideshow" },
  }, 448)
end

return P
