-- Small helpers shared across modules.
local utf8 = require("utf8")

local U = {}

function U.is_windows()
  return love.system.getOS() == "Windows"
end

-- Quote a string for POSIX sh.
function U.sh_quote(s)
  return "'" .. (s:gsub("'", "'\\''")) .. "'"
end

function U.clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

function U.join(a, b)
  if a:sub(-1) == "/" then return a .. b end
  return a .. "/" .. b
end

function U.dirname(p)
  p = (p:gsub("/+$", ""))
  local d = p:match("^(.*)/[^/]*$")
  if d == nil then return "." end
  if d == "" then return "/" end
  return d
end

function U.basename(p)
  p = (p:gsub("/+$", ""))
  return p:match("([^/]*)$")
end

function U.ext(name)
  local e = name:match("%.([^.]+)$")
  return e and e:lower() or ""
end

function U.strip_ext(name)
  return name:match("^(.*)%.[^.]*$") or name
end

-- Make sure a string is valid UTF-8 (falls back to Latin-1 -> UTF-8).
function U.sanitize(s)
  local ok, n = pcall(utf8.len, s)
  if ok and n then return s end
  return (s:gsub("[\128-\255]", function(c) return utf8.char(c:byte()) end))
end

-- Natural, case-insensitive sort key ("2" < "10").
function U.natkey(s)
  return (s:lower():gsub("%d+", function(n)
    if #n >= 12 then return n end
    return string.rep("0", 12 - #n) .. n
  end))
end

function U.fmt_time(sec)
  if not sec or sec < 0 then return "--:--" end
  sec = math.floor(sec)
  local h = math.floor(sec / 3600)
  local m = math.floor((sec % 3600) / 60)
  local s = sec % 60
  if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
  return string.format("%d:%02d", m, s)
end

function U.trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function U.file_exists(p)
  local f = io.open(p, "rb")
  if f then f:close() return true end
  return false
end

return U
