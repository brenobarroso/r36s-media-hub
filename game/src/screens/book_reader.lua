-- E-Reader & Manga Viewer: text pagination, font size toggle, CBZ comic reader & bookmarks.
local app = require("src.app")
local ui = require("src.ui")
local input = require("src.input")
local bookmarks = require("src.bookmarks")
local parser = require("src.book_parser")
local U = require("src.util")

local R = {
  path = nil,
  title = "",
  mode = "text",     -- "text" or "cbz"
  pages = {},        -- array of page strings (text mode) or file paths (cbz mode)
  current_page = 1,
  total_pages = 1,
  font_size = "normal", -- "normal" (18px) or "large" (22px)
  color_style = "default", -- "default", "sepia", "amoled"
  loading = false,
  error_msg = nil,

  -- CBZ / Image state
  cbz_mount = nil,
  current_img = nil,
  scale = 1.0,
  base_scale = 1.0,
  offset_x = 0,
  offset_y = 0,
}

local function release_cbz_image()
  if R.current_img then
    R.current_img:release()
    R.current_img = nil
  end
end

local function load_cbz_page()
  release_cbz_image()
  local fpath = R.pages[R.current_page]
  if not fpath then return end

  local data = love.filesystem.read(fpath)
  if not data or #data == 0 then return end

  local ok, img = pcall(function()
    local fd = love.filesystem.newFileData(data, U.basename(fpath))
    local imd = love.image.newImageData(fd)
    local i = love.graphics.newImage(imd)
    i:setFilter("linear", "linear")
    return i
  end)

  if ok and img then
    R.current_img = img
    local w, h = img:getDimensions()
    -- Fit screen with top and bottom margins
    local max_w = ui.W - 8
    local max_h = ui.H - 56
    R.base_scale = math.min(max_w / w, max_h / h)
    R.scale = 1.0
    R.offset_x = 0
    R.offset_y = 0
  end
end

local function repaginate_text(content)
  local font = (R.font_size == "large") and ui.f.head or ui.f.body
  local line_h = (R.font_size == "large") and 30 or 25
  local max_w = ui.W - 48
  local max_h = ui.H - 96 -- space for header and footer

  R.pages = parser.paginate_text(content, font, max_w, max_h, line_h)
  R.total_pages = #R.pages
  R.current_page = math.max(1, math.min(R.current_page, R.total_pages))
end

function R.enter(book_path, start_page)
  R.path = book_path
  R.title = U.sanitize(U.strip_ext(U.basename(book_path)))
  R.current_page = start_page or 1
  R.error_msg = nil
  R.pages = {}
  R.total_pages = 1
  release_cbz_image()

  local res, err = parser.load_book(book_path)
  if not res then
    R.error_msg = err or "Erro ao abrir livro"
    return
  end

  if res.type == "cbz" then
    R.mode = "cbz"
    R.cbz_mount = res.mount
    R.pages = res.pages
    R.total_pages = #R.pages
    R.current_page = math.max(1, math.min(R.current_page, R.total_pages))
    load_cbz_page()
  else
    R.mode = "text"
    R.text_content = res.content
    repaginate_text(res.content)
  end

  bookmarks.set(R.path, R.current_page, R.total_pages)
end

function R.exit()
  release_cbz_image()
  if R.mode == "cbz" and R.path then
    pcall(love.filesystem.unmount, R.path)
  end
  if R.path and R.total_pages > 0 then
    bookmarks.set(R.path, R.current_page, R.total_pages)
  end
end

local function turn_page(delta)
  local new_page = math.max(1, math.min(R.total_pages, R.current_page + delta))
  if new_page ~= R.current_page then
    R.current_page = new_page
    if R.mode == "cbz" then
      load_cbz_page()
    end
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

  -- Manga / CBZ pan controls when zoomed
  if R.mode == "cbz" and R.scale > 1.05 then
    if a == "left" then R.offset_x = R.offset_x + 40 return end
    if a == "right" then R.offset_x = R.offset_x - 40 return end
    if a == "up" then R.offset_y = R.offset_y + 40 return end
    if a == "down" then R.offset_y = R.offset_y - 40 return end
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
  elseif a == "down" then
    turn_page(1)
  elseif a == "accept" then
    if R.mode == "cbz" then
      if R.scale > 1.05 then
        R.scale = 1.0
        R.offset_x, R.offset_y = 0, 0
      else
        R.scale = 2.0
      end
    else
      turn_page(1)
    end
  elseif a == "y" then
    if R.mode == "text" then
      -- Toggle font size
      R.font_size = (R.font_size == "normal") and "large" or "normal"
      if R.text_content then
        repaginate_text(R.text_content)
        ui.toast(R.font_size == "large" and "Fonte: Grande" or "Fonte: Normal", 1.0)
      end
    else
      -- CBZ zoom toggle
      R.scale = (R.scale > 1.05) and 1.0 or 2.0
      R.offset_x, R.offset_y = 0, 0
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

  -- Content Area
  if R.mode == "cbz" then
    -- CBZ Image Rendering
    if R.current_img then
      local iw, ih = R.current_img:getDimensions()
      local s = R.base_scale * R.scale
      local cx = ui.W / 2 + R.offset_x
      local cy = (ui.H - 42) / 2 + 18 + R.offset_y

      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(R.current_img, cx, cy, 0, s, s, iw / 2, ih / 2)
    else
      ui.set(dim_color)
      love.graphics.setFont(ui.f.body)
      love.graphics.printf("Carregando página do mangá...", 0, 220, ui.W, "center")
    end
  else
    -- Text Rendering
    local font = (R.font_size == "large") and ui.f.head or ui.f.body
    love.graphics.setFont(font)
    ui.set(text_color)
    local page_str = R.pages[R.current_page] or ""
    love.graphics.printf(page_str, 24, 46, ui.W - 48, "left")
  end

  -- Reading Progress Bar at Bottom
  local frac = R.total_pages > 0 and (R.current_page / R.total_pages) or 0
  ui.bar(0, ui.H - 38, ui.W, 4, frac, ui.c.accent, header_bg)

  -- Footer Hints
  local bck = input.swap_ab and "A" or "B"
  local mode_hint = (R.mode == "text") and { "Y", "Fonte" } or { "Y", "Zoom" }
  ui.hints({
    { "< / >", "Página" },
    { "L2/R2", "+/-10" },
    mode_hint,
    { "X", "Visual" },
    { bck, "Biblioteca" },
  }, 450)
end

return R
