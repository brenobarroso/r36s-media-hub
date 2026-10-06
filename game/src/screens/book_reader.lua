-- E-Reader: Clean text pagination for PDF, EPUB and TXT with font size toggle, themes and bookmarks.
local app = require("src.app")
local ui = require("src.ui")
local input = require("src.input")
local bookmarks = require("src.bookmarks")
local parser = require("src.book_parser")
local U = require("src.util")

local R = {
  path = nil,
  title = "",
  pages = {},
  current_page = 1,
  total_pages = 1,
  font_size = "normal",   -- "normal" (18px) or "large" (22px)
  color_style = "default", -- "default", "sepia", "amoled"
  error_msg = nil,
  text_content = nil,
}

local function repaginate_text(content)
  if not content or content == "" then
    R.pages = { "Documento vazio." }
    R.total_pages = 1
    R.current_page = 1
    return
  end
  local font = (R.font_size == "large") and ui.f.head or ui.f.body
  local line_h = (R.font_size == "large") and 30 or 25
  local max_w = ui.W - 48
  local max_h = ui.H - 96 -- space for header and footer

  R.pages = parser.paginate_text(content, font, max_w, max_h, line_h)
  R.total_pages = math.max(1, #R.pages)
  R.current_page = math.max(1, math.min(R.current_page, R.total_pages))
end

function R.enter(book_path, start_page)
  R.path = book_path
  R.title = U.sanitize(U.strip_ext(U.basename(book_path)))
  R.current_page = start_page or 1
  R.error_msg = nil
  R.pages = {}
  R.total_pages = 1
  R.text_content = nil

  local res, err = parser.load_book(book_path)
  if not res then
    R.error_msg = err or "Erro ao abrir livro"
    return
  end

  R.text_content = res.content or ""
  repaginate_text(R.text_content)

  if start_page and start_page > 1 then
    R.current_page = math.max(1, math.min(start_page, R.total_pages))
  end

  bookmarks.set(R.path, R.current_page, R.total_pages)
end

function R.exit()
  if R.path and R.total_pages > 0 then
    bookmarks.set(R.path, R.current_page, R.total_pages)
  end
end

local function turn_page(delta)
  local new_page = math.max(1, math.min(R.total_pages, R.current_page + delta))
  if new_page ~= R.current_page then
    R.current_page = new_page
    bookmarks.set(R.path, R.current_page, R.total_pages)
  end
end

function R.action(a)
  if R.error_msg then
    if a == "back" or a == "accept" then
      R.exit()
      app.show("books")
    end
    return
  end

  if a == "back" then
    R.exit()
    app.show("books")
    return
  end

  if a == "right" or a == "r1" then
    turn_page(1)
  elseif a == "left" or a == "l1" then
    turn_page(-1)
  elseif a == "r2" then
    turn_page(10)
    ui.toast(string.format("Página %d / %d", R.current_page, R.total_pages), 0.8)
  elseif a == "l2" then
    turn_page(-10)
    ui.toast(string.format("Página %d / %d", R.current_page, R.total_pages), 0.8)
  elseif a == "up" then
    turn_page(-1)
  elseif a == "down" or a == "accept" then
    turn_page(1)
  elseif a == "y" then
    -- Toggle font size
    R.font_size = (R.font_size == "normal") and "large" or "normal"
    if R.text_content then
      repaginate_text(R.text_content)
      ui.toast(R.font_size == "large" and "Fonte: Grande" or "Fonte: Normal", 1.0)
    end
  elseif a == "x" then
    -- Toggle reader color scheme
    local styles = { "default", "sepia", "amoled" }
    local names = { default = "Tema Padrão", sepia = "Sépia (Descanso)", amoled = "AMOLED Preto" }
    for i, s in ipairs(styles) do
      if s == R.color_style then
        R.color_style = styles[(i % #styles) + 1]
        break
      end
    end
    ui.toast("Visual: " .. names[R.color_style], 1.0)
  end
  return true
end

function R.update(dt)
end

function R.draw()
  -- Color Palette based on color_style
  local bg_color, text_color, dim_color, header_bg
  if R.color_style == "amoled" then
    bg_color = { 0, 0, 0 }
    header_bg = { 0.05, 0.05, 0.05 }
    text_color = { 0.90, 0.90, 0.90 }
    dim_color = { 0.55, 0.55, 0.55 }
  elseif R.color_style == "sepia" then
    bg_color = { 0.95, 0.91, 0.82 }
    header_bg = { 0.88, 0.84, 0.74 }
    text_color = { 0.22, 0.16, 0.10 }
    dim_color = { 0.45, 0.38, 0.30 }
  else
    bg_color = ui.c.bg
    header_bg = ui.c.panel
    text_color = ui.c.text
    dim_color = ui.c.dim
  end

  love.graphics.clear(bg_color[1], bg_color[2], bg_color[3], 1)

  -- Error State
  if R.error_msg then
    ui.set(ui.c.panel)
    love.graphics.rectangle("fill", 0, 0, ui.W, 44)
    ui.set(ui.c.text)
    love.graphics.setFont(ui.f.head)
    love.graphics.print("Erro ao carregar livro", 18, 12)

    ui.set({ 1, 0.4, 0.4 })
    love.graphics.setFont(ui.f.body)
    love.graphics.printf(R.error_msg, 24, 180, ui.W - 48, "center")

    ui.set(ui.c.dim)
    love.graphics.setFont(ui.f.small)
    love.graphics.printf("Pressione B para voltar", 0, 240, ui.W, "center")
    return
  end

  -- Header Bar
  ui.set(header_bg)
  love.graphics.rectangle("fill", 0, 0, ui.W, 36)

  ui.set(text_color)
  love.graphics.setFont(ui.f.small)
  love.graphics.print(ui.fit(ui.f.small, R.title, ui.W - 190), 16, 18 - ui.f.small:getHeight() / 2)

  local pct = math.floor((R.current_page / math.max(1, R.total_pages)) * 100 + 0.5)
  local prog_str = string.format("Pág. %d / %d  (%d%%)", R.current_page, R.total_pages, pct)
  ui.set(dim_color)
  love.graphics.printf(prog_str, ui.W - 180, 18 - ui.f.small:getHeight() / 2, 164, "right")

  -- Text Rendering
  local font = (R.font_size == "large") and ui.f.head or ui.f.body
  love.graphics.setFont(font)
  ui.set(text_color)
  local page_str = R.pages[R.current_page] or ""
  love.graphics.printf(page_str, 24, 46, ui.W - 48, "left")

  -- Reading Progress Bar at Bottom
  local frac = R.total_pages > 0 and (R.current_page / R.total_pages) or 0
  ui.bar(0, ui.H - 38, ui.W, 4, frac, ui.c.accent, header_bg)

  -- Footer Hints
  local bck = input.swap_ab and "A" or "B"
  ui.hints({
    { "< / >", "Página" },
    { "L2/R2", "+/-10" },
    { "Y", "Fonte" },
    { "X", "Visual" },
    { bck, "Biblioteca" },
  }, 450)
end

return R
