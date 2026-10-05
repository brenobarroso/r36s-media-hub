-- Tiny key=value persistence in LÖVE's save directory.
local S = {}

local FILE = "state.txt"

function S.load()
  local t = {}
  local data = love.filesystem.read(FILE)
  if data then
    for k, v in data:gmatch("([%w_]+)=([^\r\n]*)") do t[k] = v end
  end
  return t
end

function S.save(t)
  local lines = {}
  for k, v in pairs(t) do
    lines[#lines + 1] = k .. "=" .. tostring(v)
  end
  table.sort(lines)
  love.filesystem.write(FILE, table.concat(lines, "\n"))
end

return S
