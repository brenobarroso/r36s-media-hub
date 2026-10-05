-- Minimal ID3 reader (ID3v2.2/2.3/2.4 + ID3v1 fallback) for MP3 files.
-- Extracts: title, artist, album, track number and embedded cover art (raw bytes).
local utf8 = require("utf8")
local bit = require("bit")
local U = require("src.util")

local M = {}

local function synchsafe(a, b, c, d)
  return a * 2097152 + b * 16384 + c * 128 + d
end

local function latin1_to_utf8(s)
  return (s:gsub("[\128-\255]", function(c) return utf8.char(c:byte()) end))
end

local function utf16_to_utf8(s, big)
  local out = {}
  local n = #s
  local i = 1
  local b1, b2 = s:byte(1, 2)
  if b1 == 0xFF and b2 == 0xFE then
    big = false
    i = 3
  elseif b1 == 0xFE and b2 == 0xFF then
    big = true
    i = 3
  end
  while i + 1 <= n do
    local a, b = s:byte(i, i + 1)
    local cu = big and (a * 256 + b) or (b * 256 + a)
    i = i + 2
    if cu >= 0xD800 and cu <= 0xDBFF and i + 1 <= n then
      local a2, b2b = s:byte(i, i + 1)
      local lo = big and (a2 * 256 + b2b) or (b2b * 256 + a2)
      if lo >= 0xDC00 and lo <= 0xDFFF then
        cu = 0x10000 + (cu - 0xD800) * 1024 + (lo - 0xDC00)
        i = i + 2
      end
    end
    if cu == 0 then break end
    if cu >= 0xD800 and cu <= 0xDFFF then cu = 0xFFFD end
    out[#out + 1] = utf8.char(cu)
  end
  return table.concat(out)
end

local function cut_at_null(s)
  local z = s:find("\0", 1, true)
  if z then return s:sub(1, z - 1) end
  return s
end

local function decode_text(enc, data)
  local text
  if enc == 1 then
    text = utf16_to_utf8(data, false)
  elseif enc == 2 then
    text = utf16_to_utf8(data, true)
  else
    text = cut_at_null(data)
    local ok, n = pcall(utf8.len, text)
    if not (ok and n) then text = latin1_to_utf8(text) end
  end
  return U.trim(text)
end

local function unsync(s)
  return (s:gsub("\255%z", "\255"))
end

-- Returns picture bytes, picture type
local function parse_apic(fdata, v22)
  local enc = fdata:byte(1)
  local p = 2
  if v22 then
    p = p + 3 -- 3-char image format
  else
    local z = fdata:find("\0", p, true)
    if not z then return nil end
    p = z + 1
  end
  local ptype = fdata:byte(p)
  p = p + 1
  if enc == 1 or enc == 2 then
    local found = false
    while p + 1 <= #fdata do
      if fdata:byte(p) == 0 and fdata:byte(p + 1) == 0 then
        p = p + 2
        found = true
        break
      end
      p = p + 2
    end
    if not found then return nil end
  else
    local z = fdata:find("\0", p, true)
    if not z then return nil end
    p = z + 1
  end
  local img = fdata:sub(p)
  local h2 = img:sub(1, 2)
  local h4 = img:sub(1, 4)
  if h2 ~= "\255\216" and h4 ~= "\137PNG" then return nil end
  return img, ptype
end

local TEXT_FRAMES = {
  TIT2 = "title", TT2 = "title",
  TPE1 = "artist", TP1 = "artist",
  TALB = "album", TAL = "album",
  TRCK = "track", TRK = "track",
  TPE2 = "album_artist", TP2 = "album_artist",
}

local function parse_v2(data, tags)
  local ver = data:byte(4)
  if ver < 2 or ver > 4 then return end
  local flags = data:byte(6)
  local size = synchsafe(data:byte(7, 10))
  local body = data:sub(11, math.min(10 + size, #data))

  if ver <= 3 and bit.band(flags, 0x80) ~= 0 then body = unsync(body) end

  local i = 1
  if ver >= 3 and bit.band(flags, 0x40) ~= 0 and #body >= 4 then
    local a, b, c, d = body:byte(1, 4)
    local ext
    if ver == 4 then
      ext = synchsafe(a, b, c, d)
    else
      ext = ((a * 256 + b) * 256 + c) * 256 + d + 4
    end
    i = 1 + ext
  end

  local hdr = (ver == 2) and 6 or 10
  local cover_type = -1

  while i + hdr - 1 <= #body do
    local id, fsize, fflags2
    if ver == 2 then
      id = body:sub(i, i + 2)
      local a, b, c = body:byte(i + 3, i + 5)
      fsize = a * 65536 + b * 256 + c
    else
      id = body:sub(i, i + 3)
      local a, b, c, d = body:byte(i + 4, i + 7)
      if ver == 4 then
        fsize = synchsafe(a, b, c, d)
      else
        fsize = ((a * 256 + b) * 256 + c) * 256 + d
      end
      fflags2 = body:byte(i + 9)
    end
    if id:byte(1) == 0 then break end -- padding reached
    if fsize <= 0 or i + hdr + fsize - 1 > #body then break end

    local fdata = body:sub(i + hdr, i + hdr + fsize - 1)
    i = i + hdr + fsize

    local skip = false
    if ver == 4 then
      if bit.band(fflags2, 0x0C) ~= 0 then skip = true end -- compressed/encrypted
      if not skip and bit.band(fflags2, 0x01) ~= 0 then fdata = fdata:sub(5) end
      if not skip and bit.band(fflags2, 0x02) ~= 0 then fdata = unsync(fdata) end
    elseif ver == 3 then
      if bit.band(fflags2, 0xC0) ~= 0 then skip = true end
    end

    if not skip then
      local key = TEXT_FRAMES[id]
      if key and #fdata >= 2 then
        local text = decode_text(fdata:byte(1), fdata:sub(2))
        if text ~= "" and not tags[key] then tags[key] = text end
      elseif id == "APIC" or id == "PIC" then
        local img, ptype = parse_apic(fdata, id == "PIC")
        if img and (not tags.cover or (ptype == 3 and cover_type ~= 3)) then
          tags.cover = img
          cover_type = ptype
        end
      end
    end
  end
end

local function parse_v1(data, tags)
  if #data < 128 then return end
  local tail = data:sub(-128)
  if tail:sub(1, 3) ~= "TAG" then return end
  local function field(a, b)
    local s = cut_at_null(tail:sub(a, b))
    s = U.trim(latin1_to_utf8(s))
    if s ~= "" then return s end
  end
  tags.title = tags.title or field(4, 33)
  tags.artist = tags.artist or field(34, 63)
  tags.album = tags.album or field(64, 93)
end

-- data: the full file contents as a string.
function M.parse(data)
  local tags = {}
  if #data >= 10 and data:sub(1, 3) == "ID3" then
    pcall(parse_v2, data, tags)
  end
  pcall(parse_v1, data, tags)
  if tags.track then tags.track = tonumber(tags.track:match("^(%d+)")) end
  return tags
end

return M
