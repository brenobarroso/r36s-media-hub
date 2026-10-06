-- High-performance Book & Document Parser: EPUB, TXT, and PDF.
-- Scope reduced to PDF, EPUB, and TXT for optimal stability, speed, and formatting.
local U = require("src.util")
local utf8 = require("utf8")

local BP = {}

-- Windows-1252 / Latin-1 byte mapping to UTF-8
local WIN1252_MAP = {
  [128] = "€", [130] = "‚", [131] = "ƒ", [132] = "„", [133] = "…",
  [134] = "†", [135] = "‡", [136] = "ˆ", [137] = "‰", [138] = "Š",
  [139] = "‹", [140] = "Œ", [142] = "Ž", [145] = "‘", [146] = "’",
  [147] = "“", [148] = "”", [149] = "•", [150] = "–", [151] = "—",
  [152] = "˜", [153] = "™", [154] = "š", [155] = "›", [156] = "œ",
  [158] = "ž", [159] = "Ÿ",
}

-- Standard TeX/PDF embedded font ligatures (bytes 1..5)
local PDF_LIGATURE_MAP = {
  [1] = "ff",
  [2] = "fi",
  [3] = "fl",
  [4] = "ffi",
  [5] = "ffl",
}

-- Convert string with octal escapes and Latin-1/Windows-1252 bytes to clean UTF-8
local function latin1_to_utf8(s)
  if not s or #s == 0 then return "" end

  -- 1) Replace PDF octal escapes \ddd with raw byte or standard ligature
  s = s:gsub("\\([0-7][0-7]?[0-7]?)", function(oct)
    local b = tonumber(oct, 8)
    if b and PDF_LIGATURE_MAP[b] then
      return PDF_LIGATURE_MAP[b]
    elseif b and b < 32 and b ~= 9 and b ~= 10 and b ~= 13 then
      return ""
    end
    return b and string.char(b) or ""
  end)

  -- 2) Replace standard escapes
  s = s:gsub("\\n", "\n"):gsub("\\r", "\r"):gsub("\\t", "\t")
  s = s:gsub("\\%(", "("):gsub("\\%)", ")"):gsub("\\\\", "\\")

  -- 3) Check if already valid UTF-8
  local ok, ulen = pcall(utf8.len, s)
  if ok and ulen ~= nil then return s end

  -- 4) Convert byte by byte
  local res = {}
  local i = 1
  local len = #s
  while i <= len do
    local b = s:byte(i)
    if PDF_LIGATURE_MAP[b] then
      res[#res + 1] = PDF_LIGATURE_MAP[b]
      i = i + 1
    elseif b < 32 and b ~= 9 and b ~= 10 and b ~= 13 then
      -- Discard unprintable control characters
      i = i + 1
    elseif b < 128 then
      res[#res + 1] = string.char(b)
      i = i + 1
    elseif WIN1252_MAP[b] then
      res[#res + 1] = WIN1252_MAP[b]
      i = i + 1
    elseif b >= 160 and b <= 255 then
      -- ISO-8859-1 (160..255) -> 2-byte UTF-8
      res[#res + 1] = string.char(0xC0 + math.floor(b / 64), 0x80 + (b % 64))
      i = i + 1
    else
      -- Check if multi-byte valid UTF-8 sequence
      local ok2, ulen2 = pcall(utf8.len, s:sub(i, i + 3))
      if ok2 and ulen2 ~= nil then
        res[#res + 1] = s:sub(i, i + 3)
        i = i + 4
      else
        i = i + 1 -- discard invalid byte
      end
    end
  end
  return table.concat(res)
end

-- Parse PDF TJ array tokens: [(string) kerning (string)]
local function parse_tj_array(arr)
  local chunks = {}
  local pos = 1
  local len = #arr

  while pos <= len do
    local b1, b2 = arr:find("^%s+", pos)
    if b1 then pos = b2 + 1 end
    if pos > len then break end

    local c = arr:sub(pos, pos)
    if c == "(" then
      -- Extract string in balanced parens
      local start_p = pos
      local depth = 1
      pos = pos + 1
      while pos <= len and depth > 0 do
        local ch = arr:sub(pos, pos)
        if ch == "\\" then
          pos = pos + 2
        elseif ch == "(" then
          depth = depth + 1
          pos = pos + 1
        elseif ch == ")" then
          depth = depth - 1
          pos = pos + 1
        else
          pos = pos + 1
        end
      end
      local inner = arr:sub(start_p + 1, pos - 2)
      local decoded = latin1_to_utf8(inner)
      if #decoded > 0 then
        chunks[#chunks + 1] = decoded
      end
    elseif c == "<" and arr:sub(pos + 1, pos + 1) ~= "<" then
      -- Hex string <...>
      local close_pos = arr:find(">", pos + 1)
      if close_pos then
        local hex = arr:sub(pos + 1, close_pos - 1):gsub("%s+", "")
        local raw = {}
        for h in hex:gmatch("%x%x") do
          raw[#raw + 1] = string.char(tonumber(h, 16))
        end
        chunks[#chunks + 1] = latin1_to_utf8(table.concat(raw))
        pos = close_pos + 1
      else
        pos = pos + 1
      end
    else
      -- Number (kerning offset)
      local n1, n2, num_str = arr:find("^([-]?%d+%.?%d*)", pos)
      if n1 then
        local num = tonumber(num_str)
        -- Negative offset < -120 units represents a space between words in PDF font coords
        if num and num < -120 then
          chunks[#chunks + 1] = " "
        end
        pos = n2 + 1
      else
        pos = pos + 1
      end
    end
  end

  return table.concat(chunks)
end

-- Process decompressed PDF content stream
local function process_pdf_stream(s, output_lines)
  local current_line = {}
  local last_y = nil

  for line in s:gmatch("[^\r\n]+") do
    -- Td / TD: tx ty Td (relative text position)
    local tx, ty = line:match("([%d.-]+)%s+([%d.-]+)%s+T[dD]")
    if ty then
      local dy = tonumber(ty)
      if dy and math.abs(dy) > 2 then
        if #current_line > 0 then
          output_lines[#output_lines + 1] = table.concat(current_line)
          current_line = {}
        end
      end
    end

    -- Tm: text matrix a b c d e f Tm (detect vertical coordinate change)
    local tm_f = line:match("[%d.-]+%s+[%d.-]+%s+[%d.-]+%s+[%d.-]+%s+[%d.-]+%s+([%d.-]+)%s+Tm")
    if tm_f then
      local y = tonumber(tm_f)
      if y and last_y and math.abs(y - last_y) > 2 then
        if #current_line > 0 then
          output_lines[#output_lines + 1] = table.concat(current_line)
          current_line = {}
        end
      end
      if y then last_y = y end
    end

    -- T* / ' / ": line breaks
    if line:match("T%*") or line:match("['\"]") then
      if #current_line > 0 then
        output_lines[#output_lines + 1] = table.concat(current_line)
        current_line = {}
      end
    end

    -- TJ: [ ... ] TJ (array of strings and kerning)
    for arr in line:gmatch("%[(.-)%]%s*TJ") do
      local txt = parse_tj_array(arr)
      if #txt > 0 then
        if #current_line > 0 and current_line[#current_line]:sub(-1) ~= " " and txt:sub(1, 1) ~= " " then
          current_line[#current_line + 1] = " "
        end
        current_line[#current_line + 1] = txt
      end
    end

    -- Tj: ( ... ) Tj (single string)
    for str in line:gmatch("%((.-)%)%s*T[jJ]") do
      local txt = latin1_to_utf8(str)
      if #txt > 0 then
        if #current_line > 0 and current_line[#current_line]:sub(-1) ~= " " and txt:sub(1, 1) ~= " " then
          current_line[#current_line + 1] = " "
        end
        current_line[#current_line + 1] = txt
      end
    end

    -- ET: end of text block
    if line:match("ET") then
      if #current_line > 0 then
        output_lines[#output_lines + 1] = table.concat(current_line)
        current_line = {}
      end
    end
  end

  if #current_line > 0 then
    output_lines[#output_lines + 1] = table.concat(current_line)
  end
end

-- PDF text extractor (Pure Lua + zlib stream decompressor)
function BP.load_pdf(path)
  local f = io.open(path, "rb")
  if not f then return nil, "Não foi possível abrir o arquivo PDF" end
  local data = f:read("*a")
  f:close()
  if not data or #data == 0 then return nil, "Arquivo PDF vazio" end

  -- 1) Try pdftotext on Linux if installed
  if not U.is_windows() then
    local tmp = "/tmp/pdf_read.txt"
    local q = string.format("%q", path)
    local code = os.execute(string.format("pdftotext %s %s 2>/dev/null", q, tmp))
    if code == 0 then
      local res = BP.load_txt(tmp)
      os.remove(tmp)
      if res and #res.content > 0 then return res end
    end
  end

  -- 2) Pure Lua stream extractor with zlib/deflate stream decompression
  local output_lines = {}

  -- Process uncompressed stream blocks in raw data
  process_pdf_stream(data, output_lines)

  -- Decompress all FlateDecode streams
  for stream in data:gmatch("stream[\r\n]+(.-)[\r\n]+endstream") do
    if love.data and love.data.decompress then
      local ok, decomp = pcall(love.data.decompress, "string", "zlib", stream)
      if not ok or not decomp then
        ok, decomp = pcall(love.data.decompress, "string", "deflate", stream)
      end
      if ok and decomp then
        process_pdf_stream(decomp, output_lines)
      end
    end
  end

  if #output_lines > 0 then
    -- Clean up lines, strip extra spaces and fix punctuation
    local cleaned = {}
    for _, l in ipairs(output_lines) do
      l = U.trim(l)
      -- Clean up formatting artifacts
      l = l:gsub("%s+", " ")
      l = l:gsub(" ([.,;:!?])", "%1")
      l = l:gsub("%( %)", "")
      if #l > 0 then
        cleaned[#cleaned + 1] = l
      end
    end

    local text = table.concat(cleaned, "\n")
    if #text > 0 then
      return {
        type = "text",
        content = text,
      }
    end
  end

  return {
    type = "text",
    content = "Documento PDF: Formato com formatação complexa ou digitalizado.\n\nPara melhor legibilidade no console R36S, recomendamos converter para EPUB ou TXT.",
  }
end

-- Strip XML/HTML tags and decode common entities
local function clean_html(str)
  if not str then return "" end
  str = str:gsub("<[bB][rR]%s*/?>", "\n")
  str = str:gsub("</[pP]>", "\n\n")
  str = str:gsub("</[hH]%d>", "\n\n")
  str = str:gsub("</[dD][iI][vV]>", "\n")
  str = str:gsub("</[lL][iI]>", "\n")
  str = str:gsub("<[^>]+>", "")
  str = str:gsub("&nbsp;", " ")
  str = str:gsub("&amp;", "&")
  str = str:gsub("&lt;", "<")
  str = str:gsub("&gt;", ">")
  str = str:gsub("&quot;", '"')
  str = str:gsub("&apos;", "'")
  str = str:gsub("&#(%d+);", function(c)
    local n = tonumber(c)
    if n and n >= 32 and n <= 126 then return string.char(n) end
    return ""
  end)
  str = str:gsub("\r\n", "\n"):gsub("\r", "\n")
  str = str:gsub("\n\n\n+", "\n\n")
  return str
end

-- TXT loader
function BP.load_txt(path)
  local f = io.open(path, "rb")
  if not f then return nil, "Não foi possível abrir o arquivo" end
  local data = f:read("*a")
  f:close()
  if not data or #data == 0 then return nil, "Arquivo vazio" end

  data = data:gsub("\r\n", "\n"):gsub("\r", "\n")
  data = data:gsub("[%z\1-\8\11\12\14-\31]", "")
  return {
    type = "text",
    content = data,
  }
end

-- EPUB loader (mounts archive via love.filesystem)
function BP.load_epub(path)
  local mount_point = "epub_" .. tostring(love.timer.getTime()):gsub("%.", "")
  local ok, err = pcall(function()
    return love.filesystem.mount(path, mount_point)
  end)

  if not ok or not err then
    return BP.load_txt(path)
  end

  local all_text = {}
  local files = {}

  local function scan(dir)
    local items = love.filesystem.getDirectoryItems(dir)
    for _, item in ipairs(items) do
      local full = (dir == "") and item or (dir .. "/" .. item)
      local info = love.filesystem.getInfo(full)
      if info then
        if info.type == "directory" then
          scan(full)
        elseif info.type == "file" then
          local ext = U.ext(item):lower()
          if ext == "xhtml" or ext == "html" or ext == "htm" or ext == "xml" then
            files[#files + 1] = full
          end
        end
      end
    end
  end

  scan(mount_point)
  table.sort(files)

  for _, fpath in ipairs(files) do
    local content = love.filesystem.read(fpath)
    if content and #content > 0 then
      local text = clean_html(content)
      if #text > 0 then
        all_text[#all_text + 1] = text
      end
    end
  end

  pcall(love.filesystem.unmount, path)

  local full = table.concat(all_text, "\n\n--- Capítulo ---\n\n")
  if #full == 0 then
    return nil, "Nenhum texto encontrado no EPUB"
  end

  return {
    type = "text",
    content = full,
  }
end

-- Universal book loader: PDF, EPUB, TXT
function BP.load_book(path)
  local ext = U.ext(path):lower()
  if ext == "epub" then
    return BP.load_epub(path)
  elseif ext == "pdf" then
    return BP.load_pdf(path)
  else
    return BP.load_txt(path)
  end
end

-- Paginate text into pages fitting screen
function BP.paginate_text(full_text, font, max_w, max_h, line_h)
  local pages = {}
  local lines_per_page = math.max(1, math.floor(max_h / line_h))
  local current_page_lines = {}

  for paragraph in full_text:gmatch("([^\n]*)\n?") do
    if #paragraph == 0 then
      current_page_lines[#current_page_lines + 1] = ""
      if #current_page_lines >= lines_per_page then
        pages[#pages + 1] = table.concat(current_page_lines, "\n")
        current_page_lines = {}
      end
    else
      local words = {}
      for w in paragraph:gmatch("%S+") do words[#words + 1] = w end

      local cur_line = ""
      for _, w in ipairs(words) do
        local test_line = (#cur_line == 0) and w or (cur_line .. " " .. w)
        if font:getWidth(test_line) <= max_w then
          cur_line = test_line
        else
          if #cur_line > 0 then
            current_page_lines[#current_page_lines + 1] = cur_line
            if #current_page_lines >= lines_per_page then
              pages[#pages + 1] = table.concat(current_page_lines, "\n")
              current_page_lines = {}
            end
          end
          cur_line = w
        end
      end

      if #cur_line > 0 then
        current_page_lines[#current_page_lines + 1] = cur_line
        if #current_page_lines >= lines_per_page then
          pages[#pages + 1] = table.concat(current_page_lines, "\n")
          current_page_lines = {}
        end
      end
    end
  end

  if #current_page_lines > 0 then
    pages[#pages + 1] = table.concat(current_page_lines, "\n")
  end

  if #pages == 0 then
    pages[1] = "Página vazia"
  end

  return pages
end

return BP
