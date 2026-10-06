-- Real filesystem access (outside LÖVE's sandbox) via io.popen.
-- Works on Linux (device) and Windows (development).
local U = require("src.util")

local M = {}

-- Extensions we list/play for music. LÖVE can decode all of these.
M.extensions = {
  mp3 = true, ogg = true, flac = true, wav = true,
  m4a = true, aac = true, opus = true, wma = true,
}

local function popen_lines(cmd)
  local f = io.popen(cmd, "r")
  if not f then return {} end
  local out = {}
  for line in f:lines() do
    line = line:gsub("\r$", "")
    if line ~= "" then out[#out + 1] = line end
  end
  f:close()
  return out
end

local function winpath(p)
  return (p:gsub("/", "\\"))
end

function M.dir_exists(p)
  if not p or p == "" then return false end
  local cmd
  if U.is_windows() then
    cmd = 'chcp 65001>nul & if exist "' .. winpath(p) .. '\\" echo y'
  else
    cmd = "[ -d " .. U.sh_quote(p) .. " ] && echo y"
  end
  return popen_lines(cmd)[1] == "y"
end

function M.dir_has_entries(p)
  if not p or p == "" then return false end
  local cmd
  if U.is_windows() then
    local wd = winpath(p)
    cmd = 'chcp 65001>nul & dir /b /a "' .. wd .. '" 2>nul'
  else
    cmd = "ls -1A -- " .. U.sh_quote(p) .. " 2>/dev/null | head -n 1"
  end
  local lines = popen_lines(cmd)
  for _, l in ipairs(lines) do
    if l and l:gsub("%s+", "") ~= "" then
      return true
    end
  end
  return false
end

local function raw_list(dir)
  local dirs, files = {}, {}
  if U.is_windows() then
    local wd = winpath(dir)
    for _, n in ipairs(popen_lines('chcp 65001>nul & dir /b /ad "' .. wd .. '" 2>nul')) do
      dirs[#dirs + 1] = n
    end
    for _, n in ipairs(popen_lines('chcp 65001>nul & dir /b /a-d "' .. wd .. '" 2>nul')) do
      files[#files + 1] = n
    end
  else
    -- -p marks directories with "/", -L follows symlinks, -A hides . and ..
    for _, n in ipairs(popen_lines("ls -1ApL -- " .. U.sh_quote(dir) .. " 2>/dev/null")) do
      if n:sub(-1) == "/" then
        dirs[#dirs + 1] = n:sub(1, -2)
      else
        files[#files + 1] = n
      end
    end
  end
  return dirs, files
end

-- Returns an array of entries: { name, file, path, is_dir } (dirs first, natural order).
-- filter_exts (optional): table of allowed extensions e.g. { png=true, jpg=true }.
-- If filter_exts is nil, all non-hidden files are allowed.
function M.list(dir, filter_exts)
  local dirs, files = raw_list(dir)
  local out = {}

  local function add(list, is_dir)
    local tmp = {}
    for _, n in ipairs(list) do
      if n:sub(1, 1) ~= "." then
        local ext = U.ext(n):lower()
        local allow = is_dir
        if not allow then
          if filter_exts ~= nil then
            allow = (filter_exts[ext] == true)
          else
            allow = true
          end
        end

        if allow then
          local display = U.sanitize(is_dir and n or U.strip_ext(n))
          tmp[#tmp + 1] = {
            name = display,
            file = n,
            path = U.join(dir, n),
            is_dir = is_dir,
            key = U.natkey(display),
          }
        end
      end
    end
    table.sort(tmp, function(a, b) return a.key < b.key end)
    for _, e in ipairs(tmp) do out[#out + 1] = e end
  end

  add(dirs, true)
  add(files, false)
  return out
end

-- Recursively collects playable file paths below `dir`.
function M.collect(dir, out, depth)
  out = out or {}
  depth = depth or 0
  for _, e in ipairs(M.list(dir, M.extensions)) do
    if #out >= 5000 then break end
    if e.is_dir then
      if depth < 5 then M.collect(e.path, out, depth + 1) end
    else
      out[#out + 1] = e.path
    end
  end
  return out
end

function M.is_inside(path, root)
  if path == root then return true end
  local r = root:sub(-1) == "/" and root or (root .. "/")
  return path:sub(1, #r) == r
end

local function strip_slash(p)
  if #p > 1 then p = p:gsub("[/\\]+$", "") end
  return (p:gsub("\\", "/"))
end

local function read_lines(path)
  local f = io.open(path, "r")
  if not f then return {} end
  local lines = {}
  for l in f:lines() do
    l = U.trim(l:gsub("\r$", ""))
    if l ~= "" and not l:match("^#") then
      lines[#lines + 1] = l
    end
  end
  f:close()
  return lines
end

-- Decides which folder is the library root for music, photos, videos, books.
function M.find_media_root(kind)
  local function try(p)
    if not p or p == "" then return nil end
    p = strip_slash(p)
    if M.dir_exists(p) then return p end
    return nil
  end

  -- Check user configured folder in state (both plural and singular keys)
  local ok, app = pcall(require, "src.app")
  if ok and app and app.state then
    local configured = app.state[kind .. "_dir"]
    if not configured or configured == "" then
      local singular = kind:gsub("s$", "") .. "_dir"
      configured = app.state[singular]
    end
    if configured and configured ~= "" and M.dir_exists(configured) then
      return configured
    end
  end

  if U.is_windows() then
    local win_candidates = {
      music = { os.getenv("R36S_MUSIC_DIR"), (os.getenv("USERPROFILE") or "C:") .. "/Music", "C:/Users/barro/.gemini/antigravity/scratch/testmusic", "C:/" },
      photos = { (os.getenv("USERPROFILE") or "C:") .. "/Pictures", "C:/Users/barro/.gemini/antigravity/scratch/testphotos", "C:/" },
      videos = { (os.getenv("USERPROFILE") or "C:") .. "/Videos", "C:/Users/barro/.gemini/antigravity/scratch/testvideos", "C:/" },
      books = { (os.getenv("USERPROFILE") or "C:") .. "/Documents", "C:/Users/barro/.gemini/antigravity/scratch/testbooks", "C:/" },
    }
    local list = win_candidates[kind] or {}
    for _, c in ipairs(list) do
      local r = try(c)
      if r then return r end
    end
    return "C:/"
  end

  -- Linux / ArkOS / PortMaster:
  -- Detect primary SD card based on port installation directory
  local base = love.filesystem.getSourceBaseDirectory() or ""
  local primary = "/roms"
  local secondary = "/roms2"
  if base:match("^/roms2") then
    primary = "/roms2"
    secondary = "/roms"
  end

  local candidates = {}
  if kind == "music" then
    local r = try(os.getenv("R36S_MUSIC_DIR"))
    if r then return r end
    local src = love.filesystem.getSource()
    for _, f in ipairs({ base .. "/music_dir.txt", src .. "/music_dir.txt" }) do
      for _, line in ipairs(read_lines(f)) do
        r = try(line)
        if r then return r end
      end
    end
    candidates = {
      primary .. "/ports/gmu-music-player/music",
      primary .. "/music", primary .. "/Music",
      secondary .. "/ports/gmu-music-player/music",
      secondary .. "/music", secondary .. "/Music",
      primary .. "/bgmusic", secondary .. "/bgmusic",
      "/root/Music", primary,
    }
  elseif kind == "photos" then
    candidates = {
      primary .. "/photos", primary .. "/Photos",
      primary .. "/pictures", primary .. "/Pictures",
      primary .. "/media/photos",
      secondary .. "/photos", secondary .. "/Photos",
      secondary .. "/pictures", secondary .. "/Pictures",
      secondary .. "/media/photos",
      "/root/Pictures", primary,
    }
  elseif kind == "videos" then
    candidates = {
      primary .. "/videos", primary .. "/Videos",
      primary .. "/movies", primary .. "/Movies",
      primary .. "/ports/videos",
      secondary .. "/videos", secondary .. "/Videos",
      secondary .. "/movies", secondary .. "/Movies",
      secondary .. "/ports/videos",
      "/root/Videos", primary,
    }
  elseif kind == "books" then
    candidates = {
      primary .. "/books", primary .. "/Books",
      primary .. "/ebooks", primary .. "/Ebooks",
      primary .. "/comics", primary .. "/Comics",
      primary .. "/media/books",
      secondary .. "/books", secondary .. "/Books",
      secondary .. "/ebooks", secondary .. "/Ebooks",
      secondary .. "/comics", secondary .. "/Comics",
      secondary .. "/media/books",
      "/root/Books", primary,
    }
  end

  -- PASS 1: Candidate on PRIMARY SD that has files/entries
  for _, c in ipairs(candidates) do
    if c:sub(1, #primary) == primary and M.dir_exists(c) and M.dir_has_entries(c) then
      return c
    end
  end

  -- PASS 2: Candidate on SECONDARY SD that has files/entries
  for _, c in ipairs(candidates) do
    if c:sub(1, #secondary) == secondary and M.dir_exists(c) and M.dir_has_entries(c) then
      return c
    end
  end

  -- PASS 3: First candidate on PRIMARY SD that exists (even if empty)
  for _, c in ipairs(candidates) do
    if c:sub(1, #primary) == primary and M.dir_exists(c) then
      return c
    end
  end

  -- PASS 4: First candidate on SECONDARY SD that exists
  for _, c in ipairs(candidates) do
    if M.dir_exists(c) then
      return c
    end
  end

  return primary
end

function M.find_music_root()
  return M.find_media_root("music")
end

return M
