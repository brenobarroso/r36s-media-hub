-- Bookmark persistence for e-books and mangas
local U = require("src.util")

local BM = {
  data = {},
  file_path = nil,
}

local function get_save_path()
  local dir
  if U.is_windows() then
    dir = (os.getenv("APPDATA") or ".") .. "/LOVE/r36s-music-player"
  else
    dir = (os.getenv("HOME") or "/root") .. "/.local/share/love/r36s-music-player"
  end
  pcall(function()
    if not U.is_windows() then os.execute("mkdir -p " .. string.format("%q", dir)) end
  end)
  return dir .. "/bookmarks.txt"
end

function BM.load()
  BM.data = {}
  BM.file_path = get_save_path()
  local f = io.open(BM.file_path, "r")
  if not f then return BM.data end

  for line in f:lines() do
    -- Format: path|page|total|timestamp
    local p, pg, tot = line:match("^(.-)|(%d+)|(%d+)")
    if p and pg and tot then
      local page = tonumber(pg) or 1
      local total = tonumber(tot) or 1
      local pct = math.floor((page / math.max(1, total)) * 100 + 0.5)
      BM.data[p] = {
        page = page,
        total = total,
        pct = pct,
      }
    end
  end
  f:close()
  return BM.data
end

function BM.save()
  if not BM.file_path then BM.file_path = get_save_path() end
  local f = io.open(BM.file_path, "w")
  if not f then return false end

  for path, info in pairs(BM.data) do
    f:write(string.format("%s|%d|%d\n", path, info.page, info.total))
  end
  f:close()
  return true
end

function BM.get(path)
  if not BM.file_path then BM.load() end
  return BM.data[path]
end

function BM.set(path, page, total)
  if not BM.file_path then BM.load() end
  local pct = math.floor((page / math.max(1, total)) * 100 + 0.5)
  BM.data[path] = {
    page = page,
    total = total,
    pct = pct,
  }
  BM.save()
end

return BM
