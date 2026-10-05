-- Playback engine: queue, shuffle/repeat, volume, tags and cover art.
local id3 = require("src.id3")
local U = require("src.util")

local P = {
  queue = {},       -- array of file paths
  order = {},       -- play order (indices into queue)
  pos = 0,          -- index into order
  cur = nil,        -- current track info table
  source = nil,
  status = "stopped", -- "stopped" | "playing" | "paused"
  volume = 0.8,
  shuffle = false,
  repeat_mode = "off", -- "off" | "all" | "one"
  error = nil,
  started_at = 0,   -- app clock when the current track started (for marquee reset)
}

local COVER_NAMES = {
  "cover.jpg", "cover.png", "folder.jpg", "folder.png", "front.jpg", "front.png",
  "Cover.jpg", "Cover.png", "Folder.jpg", "Folder.png", "albumart.jpg",
}
local MAX_COVER = 512

local function make_cover(image_data)
  local img = love.graphics.newImage(image_data)
  img:setFilter("linear", "linear")
  local w, h = img:getDimensions()
  if math.max(w, h) <= MAX_COVER then return img end
  -- Downscale big covers once so we don't keep a huge texture around.
  local s = MAX_COVER / math.max(w, h)
  local cw, ch = math.max(1, math.floor(w * s)), math.max(1, math.floor(h * s))
  local canvas = love.graphics.newCanvas(cw, ch)
  local prev = love.graphics.getCanvas()
  love.graphics.push("all")
  love.graphics.setCanvas(canvas)
  love.graphics.clear(0, 0, 0, 1)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(img, 0, 0, 0, s, s)
  love.graphics.setCanvas(prev)
  love.graphics.pop()
  img:release()
  return canvas
end

local function load_cover(bytes, dir)
  if bytes then
    local ok, img = pcall(function()
      local fd = love.filesystem.newFileData(bytes, "cover")
      return make_cover(love.image.newImageData(fd))
    end)
    if ok and img then return img end
  end
  for _, name in ipairs(COVER_NAMES) do
    local path = U.join(dir, name)
    local f = io.open(path, "rb")
    if f then
      local data = f:read("*a")
      f:close()
      local ok, img = pcall(function()
        local fd = love.filesystem.newFileData(data, name)
        return make_cover(love.image.newImageData(fd))
      end)
      if ok and img then return img end
    end
  end
  return nil
end

function P.unload()
  if P.source then
    P.source:stop()
    P.source = nil
  end
  if P.cur and P.cur.cover and P.cur.cover.release then
    P.cur.cover:release()
  end
  P.cur = nil
  P.status = "stopped"
end

local function load_file(path)
  local f, err = io.open(path, "rb")
  if not f then return false, "Não abriu: " .. tostring(err) end
  local data = f:read("*a")
  f:close()
  if not data or #data == 0 then return false, "Arquivo vazio" end

  local tags = {}
  if U.ext(path) == "mp3" then
    local ok, t = pcall(id3.parse, data)
    if ok and t then tags = t end
  end

  local fd = love.filesystem.newFileData(data, U.basename(path))
  local ok, src = pcall(love.audio.newSource, fd, "stream")
  if not ok then return false, "Formato não suportado" end

  local dur = src:getDuration("seconds")
  if not dur or dur <= 0 then dur = nil end

  P.source = src
  P.cur = {
    path = path,
    filedata = fd, -- keep a reference alive while streaming
    title = tags.title or U.sanitize(U.strip_ext(U.basename(path))),
    artist = tags.artist or tags.album_artist,
    album = tags.album,
    track = tags.track,
    duration = dur,
    cover = load_cover(tags.cover, U.dirname(path)),
  }
  return true
end

function P.load_pos(pos)
  P.unload()
  local n = #P.order
  if n == 0 then return false end
  for _ = 1, n do
    local path = P.queue[P.order[pos]]
    local ok, err = load_file(path)
    if ok then
      P.pos = pos
      P.error = nil
      P.source:setVolume(1)
      P.source:play()
      P.status = "playing"
      P.started_at = P.clock or 0
      return true
    end
    P.error = err
    pos = pos % n + 1
  end
  P.status = "stopped"
  return false
end

function P.build_order(first)
  local n = #P.queue
  P.order = {}
  for i = 1, n do P.order[i] = i end
  if P.shuffle then
    for i = n, 2, -1 do
      local j = love.math.random(i)
      P.order[i], P.order[j] = P.order[j], P.order[i]
    end
    if first then
      for i = 1, n do
        if P.order[i] == first then
          P.order[1], P.order[i] = P.order[i], P.order[1]
          break
        end
      end
    end
    P.pos = 1
  else
    P.pos = first or 1
  end
end

function P.play_queue(paths, start_index)
  if #paths == 0 then return false end
  P.queue = paths
  P.build_order(start_index or 1)
  return P.load_pos(P.pos)
end

function P.set_volume(v)
  P.volume = U.clamp(v, 0, 1)
  love.audio.setVolume(P.volume)
end

function P.change_volume(delta)
  P.set_volume(math.floor((P.volume + delta) * 100 + 0.5) / 100)
  return P.volume
end

function P.position()
  if P.source and P.status ~= "stopped" then
    return P.source:tell("seconds")
  end
  return 0
end

function P.toggle()
  if P.status == "playing" then
    P.source:pause()
    P.status = "paused"
  elseif P.status == "paused" then
    P.source:play()
    P.status = "playing"
  elseif #P.order > 0 then
    P.load_pos(P.pos > 0 and P.pos or 1)
  end
end

function P.next()
  local n = #P.order
  if n == 0 then return end
  P.load_pos(P.pos % n + 1)
end

function P.prev()
  local n = #P.order
  if n == 0 then return end
  if P.position() > 3 then
    P.source:seek(0, "seconds")
    return
  end
  local p = P.pos - 1
  if p < 1 then p = n end
  P.load_pos(p)
end

function P.seek(delta)
  if not P.source or P.status == "stopped" then return end
  local t = P.position() + delta
  local max = P.cur and P.cur.duration
  if max then t = math.min(t, max - 0.5) end
  P.source:seek(math.max(0, t), "seconds")
end

function P.toggle_shuffle()
  P.shuffle = not P.shuffle
  if #P.queue > 0 then
    local current = P.order[P.pos]
    P.build_order(current)
  end
  return P.shuffle
end

function P.cycle_repeat()
  local nxt = { off = "all", all = "one", one = "off" }
  P.repeat_mode = nxt[P.repeat_mode] or "off"
  return P.repeat_mode
end

local function on_track_end()
  local n = #P.order
  if P.repeat_mode == "one" then
    P.load_pos(P.pos)
  elseif P.pos < n then
    P.load_pos(P.pos + 1)
  elseif P.repeat_mode == "all" then
    P.load_pos(1)
  else
    -- end of the queue: stay on the last track, stopped
    if P.source then P.source:stop() end
    P.status = "stopped"
  end
end

function P.update(dt)
  P.clock = (P.clock or 0) + dt
  if P.status == "playing" and P.source and not P.source:isPlaying() then
    on_track_end()
  end
end

return P
