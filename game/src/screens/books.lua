-- E-Book & Manga Library: list view with format badges, progress and bookmarks.
local app = require("src.app")
local ui = require("src.ui")
local fs = require("src.fs")
local input = require("src.input")
local bookmarks = require("src.bookmarks")
local U = require("src.util")

local B = {
  dir = nil,
  entries = {},
  sel = 1,
  scroll = 0,
}

local BOOK_EXT = {
  epub = true, mobi = true, azw = true, prc = true,
  txt = true, cbz = true, pdf = true, md = true,
}

local function find_book_root()
  return fs.find_media_root("books")
end

local function format_bytes(bytes)
  if not bytes or bytes <= 0 then return "" end
  if bytes >= 1024 * 1024 then
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

function B.enter(dir_path)
  B.dir = dir_path or find_book_root()
  B.entries = {}
  B.sel = 1
  B.scroll = 0

  bookmarks.load()

  local list = fs.list(B.dir)
  for _, e in ipairs(list) do
    local ext = U.ext(e.file):lower()
    if e.is_dir or BOOK_EXT[ext] then
      local size = not e.is_dir and get_file_size(e.path) or nil
      local bm = not e.is_dir and bookmarks.get(e.path) or nil
      B.entries[#B.entries + 1] = {
        name = e.name,
        file = e.file,
        path = e.path,
        is_dir = e.is_dir,
        ext = ext:upper(),
        size_str = format_bytes(size),
        bookmark = bm,
      }
    end
  end
end

function B.action(a)
  local total = #B.entries

  if a == "up" then
    B.sel = B.sel - 1
    if B.sel < 1 then B.sel = total end
  elseif a == "down" then
    B.sel = B.sel + 1
    if B.sel > total then B.sel = 1 end
  elseif a == "left" or a == "l1" then
    B.sel = math.max(1, B.sel - 6)
  elseif a == "right" or a == "r1" then
    B.sel = math.min(total, B.sel + 6)
  elseif a == "back" then
    local root = find_book_root()
    if B.dir ~= root and B.dir ~= "/" then
      B.enter(U.dirname(B.dir))
    else
      app.show("home")
    end
  elseif a == "accept" then
    local e = B.entries[B.sel]
    if e then
      if e.is_dir then
        B.enter(e.path)
      else
        local start_page = e.bookmark and e.bookmark.page or 1
        app.show("book_reader", e.path, start_page)
      end
    end
  elseif a == "x" then
    local e = B.entries[B.sel]
    if e and not e.is_dir then
      -- Open from beginning (page 1)
      app.show("book_reader", e.path, 1)
    end
  end

  -- Scroll adjustment
  local VISIBLE_ROWS = 6
  if B.sel <= B.scroll then
    B.scroll = B.sel - 1
  elseif B.sel > B.scroll + VISIBLE_ROWS then
    B.scroll = B.sel - VISIBLE_ROWS
  end
  B.scroll = math.max(0, B.scroll)
  return true
end

function B.update(dt)
end

function B.draw()
  -- Header
  ui.set(ui.c.panel)
  love.graphics.rectangle("fill", 0, 0, ui.W, 44)
  ui.set(ui.c.accent)
  ui.icon_book(18, 10, 24)
  ui.set(ui.c.text)
  love.graphics.setFont(ui.f.head)
  local title = (B.dir == find_book_root()) and "Biblioteca de Livros & Mangás" or U.basename(B.dir)
  love.graphics.print(ui.fit(ui.f.head, title, ui.W - 180), 52, 22 - ui.f.head:getHeight() / 2)

  ui.set(ui.c.dim)
  love.graphics.setFont(ui.f.small)
  local count_text = (#B.entries > 0) and (B.sel .. " / " .. #B.entries) or "Vazio"
  love.graphics.printf(count_text, ui.W - 140, 22 - ui.f.small:getHeight() / 2, 120, "right")

  if #B.entries == 0 then
    ui.set(ui.c.dim)
    love.graphics.setFont(ui.f.body)
    love.graphics.printf("Nenhum livro ou manga encontrado.\nPasta: " .. (B.dir or "não definida"), 0, 200, ui.W, "center")
  end

  -- Book List
  local list_y = 52
  local row_h = 58
  local card_w = ui.W - 32
  local card_x = 16
  local VISIBLE_ROWS = 6

  for i = 1, VISIBLE_ROWS do
    local idx = B.scroll + i
    local e = B.entries[idx]
    if not e then break end

    local y = list_y + (i - 1) * (row_h + 6)
    local is_sel = (idx == B.sel)

    -- Row background
    if is_sel then
      ui.set(ui.c.card_sel or ui.c.panel2)
      love.graphics.rectangle("fill", card_x, y, card_w, row_h, 8, 8)
      ui.set(ui.c.card_border or ui.c.accent)
      love.graphics.setLineWidth(2)
      love.graphics.rectangle("line", card_x, y, card_w, row_h, 8, 8)
      -- Accent bar
      love.graphics.rectangle("fill", card_x, y + 6, 4, row_h - 12, 2, 2)
    else
      ui.set(ui.c.card_bg or ui.c.panel)
      love.graphics.rectangle("fill", card_x, y, card_w, row_h, 8, 8)
    end

    -- Icon Box
    local bx, by = card_x + 10, y + 7
    local bw, bh = 46, 44
    ui.set(ui.c.panel2)
    love.graphics.rectangle("fill", bx, by, bw, bh, 4, 4)

    ui.set(is_sel and ui.c.accent or ui.c.dim)
    if e.is_dir then
      ui.icon_folder(bx + (bw - 28) / 2, by + (bh - 28) / 2, 28)
    else
      ui.icon_book(bx + (bw - 26) / 2, by + (bh - 26) / 2, 26)
    end

    -- Title & Details
    local tx = bx + bw + 14
    local tw = card_w - (bw + 24) - 130

    if is_sel then
      ui.set(ui.c.text)
      ui.marquee(e.name, ui.f.bodyb, tx, y + 9, tw, app.time)
    else
      ui.set(ui.c.text, 0.88)
      love.graphics.setFont(ui.f.body)
      love.graphics.print(ui.fit(ui.f.body, e.name, tw), tx, y + 9)
    end

    -- Format badge & reading progress
    if e.is_dir then
      ui.set(ui.c.dim)
      love.graphics.setFont(ui.f.tiny)
      love.graphics.print("Pasta de livros", tx, y + 33)
    else
      local badge_w = 46
      ui.set(ui.c.panel2)
      love.graphics.rectangle("fill", tx, y + 32, badge_w, 18, 3, 3)
      ui.set(ui.c.accent)
      love.graphics.setFont(ui.f.tiny)
      love.graphics.printf(e.ext, tx, y + 41 - ui.f.tiny:getHeight() / 2, badge_w, "center")

      -- Progress or Size
      local px = tx + badge_w + 10
      if e.bookmark and e.bookmark.page and e.bookmark.total then
        ui.set(ui.c.accent)
        love.graphics.setFont(ui.f.tiny)
        local prog_str = string.format("Pág. %d / %d (%d%%)", e.bookmark.page, e.bookmark.total, e.bookmark.pct or 0)
        love.graphics.print(prog_str, px, y + 33)
      else
        ui.set(ui.c.dim)
        love.graphics.setFont(ui.f.tiny)
        local s = e.size_str or "Novo"
        love.graphics.print(s, px, y + 33)
      end
    end

    -- Right Action / Indicator
    local rx = card_x + card_w - 42
    ui.set(is_sel and ui.c.accent or ui.c.faint)
    if e.is_dir then
      love.graphics.setFont(ui.f.small)
      love.graphics.print(">", rx + 12, y + 29 - ui.f.small:getHeight() / 2)
    else
      love.graphics.setFont(ui.f.tiny)
      if e.bookmark then
        love.graphics.printf("Continuar", rx - 48, y + 29 - ui.f.tiny:getHeight() / 2, 70, "right")
      else
        love.graphics.printf("Ler", rx - 20, y + 29 - ui.f.tiny:getHeight() / 2, 42, "right")
      end
    end
  end

  local acc = input.swap_ab and "B" or "A"
  local bck = input.swap_ab and "A" or "B"
  ui.hints({
    { acc, "Ler / Abrir" },
    { bck, "Voltar" },
    { "X", "Início" },
    { "L1/R1", "Pular 6" },
  }, 448)
end

return B
