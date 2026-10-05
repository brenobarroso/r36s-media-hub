-- Real filesystem access (outside LÖVE's sandbox) via io.popen.
-- Works on Linux (device) and Windows (development).
local U = require("src.util")

local M = {}

-- Extensions we list/play. LÖVE can decode all of these.
M.extensions = { mp3 = true, ogg = true, flac = true, wav = true }

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
function M.list(dir)
  local dirs, files = raw_list(dir)
  local out = {}

  local function add(list, is_dir)
    local tmp = {}
    for _, n in ipairs(list) do
      if n:sub(1, 1) ~= "." and (is_dir or M.extensions[U.ext(n)]) then
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
  for _, e in ipairs(M.list(dir)) do
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

-- Decides which folder is the "library root".
-- Order: env R36S_MUSIC_DIR, lines in music_dir.txt, then common locations.
function M.find_music_root()
  local function try(p)
    if not p or p == "" then return nil end
    p = strip_slash(p)
    if M.dir_exists(p) then return p end
    return nil
  end

  local r = try(os.getenv("R36S_MUSIC_DIR"))
  if r then return r end

  local base = love.filesystem.getSourceBaseDirectory()
  local src = love.filesystem.getSource()
  for _, f in ipairs({ base .. "/music_dir.txt", src .. "/music_dir.txt" }) do
    for _, line in ipairs(read_lines(f)) do
      r = try(line)
      if r then return r end
    end
  end

  local candidates
  if U.is_windows() then
    candidates = { (os.getenv("USERPROFILE") or "C:") .. "/Music", "C:/" }
  else
    local home = os.getenv("HOME") or "/root"
    candidates = {
      "/roms2/ports/gmu-music-player/music",
      "/roms/ports/gmu-music-player/music",
      "/roms2/music", "/roms2/Music", "/roms/music", "/roms/Music",
      "/roms2/bgmusic", "/roms/bgmusic", home .. "/Music", "/roms", "/",
    }
  end
  for _, c in ipairs(candidates) do
    r = try(c)
    if r then return r end
  end
  return "/"
end

return M
