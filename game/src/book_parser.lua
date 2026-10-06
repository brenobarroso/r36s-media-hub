-- Book and Manga Parser: EPUB, MOBI (PalmDOC), TXT, CBZ.
local U = require("src.util")

local BP = {}

-- Strip XML/HTML tags and decode common entities
local function clean_html(str)
  if not str then return "" end
  -- Replace line breaks
  str = str:gsub("<[bB][rR]%s*/?>", "\n")
  str = str:gsub("</[pP]>", "\n\n")
  str = str:gsub("</[hH]%d>", "\n\n")
  str = str:gsub("</[dD][iI][vV]>", "\n")
  str = str:gsub("</[lL][iI]>", "\n")
  -- Strip tags
  str = str:gsub("<[^>]+>", "")
  -- Decode entities
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
  -- Normalize newlines
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

  -- Normalize newlines and sanitize non-printable control chars except \n and \t
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
    -- Fallback: read raw zip file for text if mounting fails
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

-- PalmDOC LZ77 decompressor for MOBI
local function decompress_palmdoc(bytes)
  local out = {}
  local i = 1
  local len = #bytes

  while i <= len do
    local b = bytes:byte(i)
    i = i + 1

    if b == 0 then
      -- literal null
      out[#out + 1] = "\0"
    elseif b >= 1 and b <= 8 then
      -- literal copy of next b bytes
      local chunk = bytes:sub(i, i + b - 1)
      out[#out + 1] = chunk
      i = i + b
    elseif b >= 9 and b <= 0x7f then
      -- literal byte
      out[#out + 1] = string.char(b)
    elseif b >= 0x80 and b <= 0xbf then
      -- distance / length pair (2 bytes)
      if i <= len then
        local b2 = bytes:byte(i)
        i = i + 1
        local distance = bit.bor(bit.lshift(bit.band(b, 0x3f), 3), bit.rshift(b2, 5))
        local length = bit.band(b2, 0x1f) + 3

        -- Copy from previously decompressed output
        local full_so_far = table.concat(out)
        local start_pos = #full_so_far - distance + 1
        if start_pos > 0 and start_pos <= #full_so_far then
          for k = 1, length do
            local p = start_pos + k - 1
            if p <= #full_so_far then
              out[#out + 1] = full_so_far:sub(p, p)
            end
          end
        end
      end
    elseif b >= 0xc0 then
      -- space followed by (b ^ 0x80)
      out[#out + 1] = " " .. string.char(bit.bxor(b, 0x80))
    end
  end

  return table.concat(out)
end

-- MOBI / Kindle loader
function BP.load_mobi(path)
  local f = io.open(path, "rb")
  if not f then return nil, "Não foi possível abrir o arquivo MOBI" end
  local header = f:read(78)
  if not header or #header < 78 then
    f:close()
    return nil, "Cabeçalho MOBI inválido"
  end

  -- Number of records at offset 76 (2 bytes big endian)
  local num_records = header:byte(77) * 256 + header:byte(78)
  if num_records < 2 then
    f:close()
    return nil, "MOBI sem registros de texto"
  end

  local record_info = f:read(num_records * 8)
  if not record_info or #record_info < num_records * 8 then
    f:close()
    return nil, "Índice MOBI incompleto"
  end

  local function read_u32(str, offset)
    local b1, b2, b3, b4 = str:byte(offset, offset + 3)
    return b1 * 16777216 + b2 * 65536 + b3 * 256 + b4
  end

  local offsets = {}
  for r = 0, num_records - 1 do
    offsets[r + 1] = read_u32(record_info, r * 8 + 1)
  end

  -- Record 0 has PalmDOC header
  local r0_len = offsets[2] - offsets[1]
  f:seek("set", offsets[1])
  local r0 = f:read(r0_len)
  if not r0 or #r0 < 16 then
    f:close()
    return nil, "Registro 0 MOBI corrompido"
  end

  local compression = r0:byte(1) * 256 + r0:byte(2)
  local text_records = r0:byte(9) * 256 + r0:byte(10)
  text_records = math.min(text_records, num_records - 1)

  local text_parts = {}
  for r = 1, text_records do
    local start_off = offsets[r + 1]
    local next_off = offsets[r + 2] or (start_off + 4096)
    local rlen = next_off - start_off
    f:seek("set", start_off)
    local rec_data = f:read(rlen)
    if rec_data then
      if compression == 1 then
        text_parts[#text_parts + 1] = rec_data
      elseif compression == 2 then
        local ok, dec = pcall(decompress_palmdoc, rec_data)
        if ok and dec then text_parts[#text_parts + 1] = dec end
      else
        text_parts[#text_parts + 1] = rec_data
      end
    end
  end
  f:close()

  local raw = table.concat(text_parts)
  local clean = clean_html(raw)
  if #clean == 0 then
    clean = raw:gsub("[%z\1-\8\11\12\14-\31]", "")
  end

  return {
    type = "text",
    content = clean,
  }
end

-- CBZ (Comic Book Zip / Manga) loader
function BP.load_cbz(path)
  local mount_point = "cbz_" .. tostring(love.timer.getTime()):gsub("%.", "")
  local ok = love.filesystem.mount(path, mount_point)
  if not ok then
    return nil, "Falha ao montar arquivo CBZ"
  end

  local images = {}
  local valid_ext = { jpg = true, jpeg = true, png = true, webp = true, bmp = true }

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
          if valid_ext[ext] then
            images[#images + 1] = full
          end
        end
      end
    end
  end

  scan(mount_point)
  table.sort(images)

  if #images == 0 then
    pcall(love.filesystem.unmount, path)
    return nil, "Nenhuma página de imagem encontrada no CBZ"
  end

  return {
    type = "cbz",
    mount = mount_point,
    archive_path = path,
    pages = images,
  }
end

-- PDF text extractor (basic text stream parser)
function BP.load_pdf(path)
  local f = io.open(path, "rb")
  if not f then return nil, "Não foi possível abrir o PDF" end
  local data = f:read("*a")
  f:close()
  if not data or #data == 0 then return nil, "Arquivo vazio" end

  -- 1) Check if ArkOS / Linux has pdftotext installed
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

  -- 2) Pure Lua stream extractor with zlib/deflate decompression
  local parts = {}

  local function extract_text_from_chunk(s)
    if not s or #s == 0 then return end
    for block in s:gmatch("BT(.-)ET") do
      for txt in block:gmatch("%((.-)%)%s*T[jJ]") do
        txt = txt:gsub("\\%(", "("):gsub("\\%)", ")"):gsub("\\\\", "\\")
        if #txt > 0 then parts[#parts + 1] = txt end
      end
      for array in block:gmatch("%[(.-)%]%s*TJ") do
        for item in array:gmatch("%((.-)%)") do
          item = item:gsub("\\%(", "("):gsub("\\%)", ")"):gsub("\\\\", "\\")
          if #item > 0 then parts[#parts + 1] = item end
        end
      end
    end
  end

  -- Check raw uncompressed blocks
  extract_text_from_chunk(data)

  -- Check compressed streams (FlateDecode)
  for stream in data:gmatch("stream[\r\n]+(.-)[\r\n]+endstream") do
    if love.data and love.data.decompress then
      local ok, decomp = pcall(love.data.decompress, "string", "zlib", stream)
      if not ok or not decomp then
        ok, decomp = pcall(love.data.decompress, "string", "deflate", stream)
      end
      if ok and decomp then
        extract_text_from_chunk(decomp)
      end
    end
  end

  if #parts > 0 then
    local text = table.concat(parts, " ")
    text = text:gsub("%s+", " "):gsub(" ([.,;:!?])", "%1")
    return {
      type = "text",
      content = text,
    }
  end

  return {
    type = "text",
    content = "Documento PDF: Formato com formatação complexa ou digitalizado.\n\nPara melhor legibilidade no console R36S, recomendamos converter para EPUB ou TXT.",
  }
end

-- Universal book loader by extension
function BP.load_book(path)
  local ext = U.ext(path):lower()
  if ext == "epub" then
    return BP.load_epub(path)
  elseif ext == "mobi" or ext == "azw" or ext == "prc" then
    return BP.load_mobi(path)
  elseif ext == "cbz" or ext == "cbr" or ext == "zip" then
    return BP.load_cbz(path)
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
      -- empty line / paragraph separator
      current_page_lines[#current_page_lines + 1] = ""
      if #current_page_lines >= lines_per_page then
        pages[#pages + 1] = table.concat(current_page_lines, "\n")
        current_page_lines = {}
      end
    else
      -- Wrap paragraph into lines of width <= max_w
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
