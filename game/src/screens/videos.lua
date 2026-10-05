-- Video Library & Player launcher: folder navigation, thumbnails, posters & playback.
local app = require("src.app")
local ui = require("src.ui")
local fs = require("src.fs")
local input = require("src.input")
local player = require("src.player")
local U = require("src.util")

local V = {
  dir = nil,
  entries = {},
  sel = 1,
  scroll = 0,
  thumb_cache = {},
}

local VIDEO_EXT = {
  mp4 = true, mkv = true, avi = true, mov = true,
  wmv = true, flv = true, webm = true, ogv = true,
  m4v = true, ["3gp"] = true,
}

local POSTER_NAMES = {
  "poster.jpg", "poster.png", "cover.jpg", "cover.png",
  "folder.jpg", "folder.png",
}

local function find_video_root()
  local candidates
  if U.is_windows() then
    candidates = {
      (os.getenv("USERPROFILE") or "C:") .. "/Videos",
      "C:/Users/barro/.gemini/antigravity/scratch/testvideos",
      "C:/",
    }
  else
    candidates = {
      "/roms2/videos", "/roms2/Videos", "/roms2/movies", "/roms2/Movies",
      "/roms/videos", "/roms/Videos", "/roms/movies", "/roms/Movies",
      "/roms2/ports/videos", "/roms/ports/videos",
      "/roms2", "/roms", "/",
    }
  end
  for _, c in ipairs(candidates) do
    if fs.dir_exists(c) then return c end
  end
  return "/"
end

local function format_bytes(bytes)
  if not bytes or bytes <= 0 then return "" end
  if bytes >= 1024 * 1024 * 1024 then
    return string.format("%.1f GB", bytes / (1024 * 1024 * 1024))
  elseif bytes >= 1024 * 1024 then
    return string.format("%.1f MB", bytes / (1024 * 1024))
  elseif bytes >= 1024 then
    return string.format("%d KB", math.floor(bytes / 1024))
  end
  return bytes .. " B"
end

local function get_file_size(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local size = f:seek("end")
  f:close()
  return size
end

local function load_video_thumb(video_path, dir_path)
  if V.thumb_cache[video_path] ~= nil then
    return V.thumb_cache[video_path]
  end

  local base = U.strip_ext(video_path)
  local candidates = {
    base .. ".jpg", base .. ".png", base .. ".jpeg", base .. ".webp",
    base .. ".JPG", base .. ".PNG",
  }
  for _, p in ipairs(POSTER_NAMES) do
    candidates[#candidates + 1] = U.join(dir_path, p)
  end

  for _, img_path in ipairs(candidates) do
    local f = io.open(img_path, "rb")
    if f then
      local data = f:read("*a")
      f:close()
      if data and #data > 0 then
        local ok, img = pcall(function()
          local fd = love.filesystem.newFileData(data, U.basename(img_path))
          local imd = love.image.newImageData(fd)
          local iw, ih = imd:getDimensions()
          -- Downscale to thumbnail size (max 120x80)
          local max_w, max_h = 120, 80
          local s = math.min(max_w / iw, max_h / ih)
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
        end)
        if ok and img then
          V.thumb_cache[video_path] = img
          return img
        end
      end
    end
  end

  V.thumb_cache[video_path] = false
  return nil
end

function V.enter(dir_path)
  V.dir = dir_path or V.dir or find_video_root()
  V.entries = {}
  V.sel = 1
  V.scroll = 0

  local list = fs.list(V.dir)
  for _, e in ipairs(list) do
    local ext = U.ext(e.file)
    if e.is_dir or VIDEO_EXT[ext] then
      local size = not e.is_dir and get_file_size(e.path) or nil
      V.entries[#V.entries + 1] = {
        name = e.name,
        file = e.file,
        path = e.path,
        is_dir = e.is_dir,
        ext = ext:upper(),
        size_str = format_bytes(size),
      }
    end
  end
end

local function play_video(path)
  -- Pause background music if playing
  if player.status == "playing" then
    player.toggle()
  end

  ui.toast("Iniciando vídeo...", 2.0)

  if U.is_windows() then
    -- On Windows, open default media player or mpv/vlc if available
    os.execute(string.format('start "" %q', path))
  else
    -- On Linux / ArkOS / PortMaster: launch mpv (hardware-accelerated KMS/DRM) or ffplay
    local q = string.format("%q", path)
    local cmd = string.format('(mpv --fs --vo=drm %s || mpv --fs %s || ffplay -fs -autoexit %s) >/dev/null 2>&1', q, q, q)
    os.execute(cmd)
  end
end

function V.action(a)
  local total = #V.entries

  if a == "up" then
    V.sel = V.sel - 1
    if V.sel < 1 then V.sel = total end
  elseif a == "down" then
    V.sel = V.sel + 1
    if V.sel > total then V.sel = 1 end
  elseif a == "left" or a == "l1" then
    V.sel = math.max(1, V.sel - 6)
  elseif a == "right" or a == "r1" then
    V.sel = math.min(total, V.sel + 6)
  elseif a == "back" then
    local root = find_video_root()
    if V.dir ~= root and V.dir ~= "/" then
      V.enter(U.dirname(V.dir))
    else
      app.show("home")
    end
  elseif a == "accept" then
    local e = V.entries[V.sel]
    if e then
      if e.is_dir then
        V.enter(e.path)
      else
        play_video(e.path)
      end
    end
  end

  -- Keep selected item inside view
  local VISIBLE_ROWS = 6
  if V.sel <= V.scroll then
    V.scroll = V.sel - 1
  elseif V.sel > V.scroll + VISIBLE_ROWS then
    V.scroll = V.sel - VISIBLE_ROWS
  end
  V.scroll = math.max(0, V.scroll)
end

function V.update(dt)
end

function V.draw()
  -- Header
  ui.set(ui.c.panel)
  love.graphics.rectangle("fill", 0, 0, ui.W, 44)
  ui.set(ui.c.accent)
  ui.icon_video(18, 10, 24)
  ui.set(ui.c.text)
  love.graphics.setFont(ui.f.head)
  local title = (V.dir == find_video_root()) and "Vídeos & Filmes" or U.basename(V.dir)
  love.graphics.print(ui.fit(ui.f.head, title, ui.W - 180), 52, 22 - ui.f.head:getHeight() / 2)

  ui.set(ui.c.dim)
  love.graphics.setFont(ui.f.small)
  local count_text = (#V.entries > 0) and (V.sel .. " / " .. #V.entries) or "Vazio"
  love.graphics.printf(count_text, ui.W - 140, 22 - ui.f.small:getHeight() / 2, 120, "right")

  if #V.entries == 0 then
    ui.set(ui.c.dim)
    love.graphics.setFont(ui.f.body)
    love.graphics.printf("Nenhum vídeo ou pasta encontrado.\nColoque filmes e clipes em /roms2/videos", 0, 200, ui.W, "center")
  end

  -- Video List
  local list_y = 52
  local row_h = 58
  local card_w = ui.W - 32
  local card_x = 16
  local VISIBLE_ROWS = 6

  for i = 1, VISIBLE_ROWS do
    local idx = V.scroll + i
    local e = V.entries[idx]
    if not e then break end

    local y = list_y + (i - 1) * (row_h + 6)
    local is_sel = (idx == V.sel)

    -- Row background
    if is_sel then
      ui.set(ui.c.card_sel or ui.c.panel2)
      love.graphics.rectangle("fill", card_x, y, card_w, row_h, 8, 8)
      ui.set(ui.c.card_border or ui.c.accent)
      love.graphics.setLineWidth(2)
      love.graphics.rectangle("line", card_x, y, card_w, row_h, 8, 8)
      -- Accent indicator bar
      love.graphics.rectangle("fill", card_x, y + 6, 4, row_h - 12, 2, 2)
    else
      ui.set(ui.c.card_bg or ui.c.panel)
      love.graphics.rectangle("fill", card_x, y, card_w, row_h, 8, 8)
    end

    -- Thumbnail / Icon Frame (16:9 ratio box: 64x44)
    local bx, by = card_x + 10, y + 7
    local bw, bh = 64, 44
    ui.set(ui.c.panel2)
    love.graphics.rectangle("fill", bx, by, bw, bh, 4, 4)

    if e.is_dir then
      ui.set(is_sel and ui.c.accent or ui.c.dim)
      ui.icon_folder(bx + (bw - 30) / 2, by + (bh - 30) / 2, 30)
    else
      local thumb = load_video_thumb(e.path, V.dir)
      if thumb then
        local tw, th = thumb:getDimensions()
        local s = math.min(bw / tw, bh / th)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(thumb, bx + (bw - tw * s) / 2, by + (bh - th * s) / 2, 0, s, s)
      else
        ui.set(is_sel and ui.c.accent or ui.c.dim)
        ui.icon_video(bx + (bw - 28) / 2, by + (bh - 28) / 2, 28)
      end
    end

    -- Video Title & Subtitle
    local tx = bx + bw + 14
    local tw = card_w - (bw + 24) - 90

    if is_sel then
      ui.set(ui.c.text)
      ui.marquee(e.name, ui.f.bodyb, tx, y + 9, tw, app.time)
    else
      ui.set(ui.c.text, 0.88)
      love.graphics.setFont(ui.f.body)
      love.graphics.print(ui.fit(ui.f.body, e.name, tw), tx, y + 9)
    end

    -- Subtitle info: format badge + file size
    if e.is_dir then
      ui.set(ui.c.dim)
      love.graphics.setFont(ui.f.tiny)
      love.graphics.print("Pasta de arquivos", tx, y + 33)
    else
      -- Format badge
      local badge_w = 42
      ui.set(ui.c.panel2)
      love.graphics.rectangle("fill", tx, y + 32, badge_w, 18, 3, 3)
      ui.set(ui.c.accent)
      love.graphics.setFont(ui.f.tiny)
      love.graphics.printf(e.ext, tx, y + 41 - ui.f.tiny:getHeight() / 2, badge_w, "center")

      -- Size
      if e.size_str and #e.size_str > 0 then
        ui.set(ui.c.dim)
        love.graphics.setFont(ui.f.tiny)
        love.graphics.print(e.size_str, tx + badge_w + 10, y + 33)
      end
    end

    -- Right Action Icon
    local rx = card_x + card_w - 36
    ui.set(is_sel and ui.c.accent or ui.c.faint)
    if e.is_dir then
      love.graphics.setFont(ui.f.small)
      love.graphics.print(">", rx + 6, y + 29 - ui.f.small:getHeight() / 2)
    else
      ui.icon_play(rx, y + 17, 24)
    end
  end

  local acc = input.swap_ab and "B" or "A"
  local bck = input.swap_ab and "A" or "B"
  ui.hints({
    { acc, "Reproduzir" },
    { bck, "Voltar" },
    { "L1/R1", "Pular 6" },
  }, 448)
end

return V
