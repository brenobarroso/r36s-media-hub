-- Fullscreen Photo Viewer: pan, zoom, rotate, slideshow, and EXIF/aspect ratio fitting.
local app = require("src.app")
local ui = require("src.ui")
local input = require("src.input")
local U = require("src.util")

local V = {
  photos = {},       -- list of photo file paths
  index = 1,         -- current photo index
  image = nil,       -- loaded love Image
  scale = 1.0,       -- current zoom scale
  base_scale = 1.0,  -- scale to fit screen
  offset_x = 0,
  offset_y = 0,
  rotation = 0,      -- 0, 1, 2, 3 (x 90 deg)
  slideshow = false,
  slide_timer = 0,
  slide_interval = 4.0,
  show_ui = true,
  ui_timer = 3.0,
}

local function load_current()
  if V.image then
    V.image:release()
    V.image = nil
  end
  local path = V.photos[V.index]
  if not path then return end

  local f = io.open(path, "rb")
  if not f then return end
  local data = f:read("*a")
  f:close()
  if not data or #data == 0 then return end

  local ok, img = pcall(function()
    local fd = love.filesystem.newFileData(data, U.basename(path))
    local imd = love.image.newImageData(fd)
    local i = love.graphics.newImage(imd)
    i:setFilter("linear", "linear")
    return i
  end)

  if ok and img then
    V.image = img
    local w, h = img:getDimensions()
    -- Calculate base scale to fit 640x480
    V.base_scale = math.min((ui.W - 16) / w, (ui.H - 16) / h)
    V.scale = 1.0
    V.offset_x = 0
    V.offset_y = 0
    V.rotation = 0
    V.ui_timer = 3.0
  else
    ui.toast("Erro ao carregar imagem", 1.5)
  end
end

function V.enter(photos, start_index)
  V.photos = photos or {}
  V.index = start_index or 1
  V.slideshow = false
  V.slide_timer = 0
  V.show_ui = true
  load_current()
end

function V.action(a)
  V.ui_timer = 3.0
  V.show_ui = true

  if a == "back" then
    if V.image then V.image:release() V.image = nil end
    app.show("photos")
  elseif a == "left" then
    if V.scale > 1.05 then
      V.offset_x = V.offset_x + 40
    else
      V.index = V.index - 1
      if V.index < 1 then V.index = #V.photos end
      load_current()
    end
  elseif a == "right" then
    if V.scale > 1.05 then
      V.offset_x = V.offset_x - 40
    else
      V.index = V.index + 1
      if V.index > #V.photos then V.index = 1 end
      load_current()
    end
  elseif a == "up" then
    if V.scale > 1.05 then
      V.offset_y = V.offset_y + 40
    else
      V.scale = math.min(V.scale + 0.3, 3.5)
    end
  elseif a == "down" then
    if V.scale > 1.05 then
      V.offset_y = V.offset_y - 40
    else
      V.scale = math.max(V.scale - 0.3, 1.0)
      if V.scale <= 1.0 then V.offset_x, V.offset_y = 0, 0 end
    end
  elseif a == "l2" then
    V.scale = math.max(V.scale - 0.25, 1.0)
    if V.scale <= 1.0 then V.offset_x, V.offset_y = 0, 0 end
  elseif a == "r2" then
    V.scale = math.min(V.scale + 0.25, 3.5)
  elseif a == "l1" or a == "y" then
    -- Rotate 90 degrees
    V.rotation = (V.rotation + 1) % 4
  elseif a == "r1" then
    -- Next photo
    V.index = V.index + 1
    if V.index > #V.photos then V.index = 1 end
    load_current()
  elseif a == "start" then
    V.slideshow = not V.slideshow
    V.slide_timer = 0
    ui.toast(V.slideshow and "Slideshow: Ligado" or "Slideshow: Pausado", 1.2)
  elseif a == "accept" then
    -- Reset zoom
    if V.scale > 1.05 then
      V.scale = 1.0
      V.offset_x, V.offset_y = 0, 0
      ui.toast("Zoom redefinido", 0.8)
    else
      V.scale = 2.0
      ui.toast("Zoom 2x", 0.8)
    end
  end
end

function V.update(dt)
  if V.slideshow and #V.photos > 1 then
    V.slide_timer = V.slide_timer + dt
    if V.slide_timer >= V.slide_interval then
      V.slide_timer = 0
      V.index = V.index + 1
      if V.index > #V.photos then V.index = 1 end
      load_current()
    end
  end

  if V.ui_timer > 0 then
    V.ui_timer = V.ui_timer - dt
    if V.ui_timer <= 0 then V.show_ui = false end
  end
end

function V.draw()
  -- Pure dark background for maximum photo contrast
  love.graphics.clear(0, 0, 0, 1)

  if V.image then
    local iw, ih = V.image:getDimensions()
    local s = V.base_scale * V.scale
    local cx = ui.W / 2 + V.offset_x
    local cy = ui.H / 2 + V.offset_y
    local rad = V.rotation * (math.pi / 2)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(V.image, cx, cy, rad, s, s, iw / 2, ih / 2)
  else
    ui.set(ui.c.dim)
    love.graphics.setFont(ui.f.body)
    love.graphics.printf("Nenhuma foto selecionada", 0, ui.H / 2 - 10, ui.W, "center")
  end

  -- Overlay UI (auto fades after inactivity)
  if V.show_ui and #V.photos > 0 then
    -- Top bar
    ui.set({ 0, 0, 0 }, 0.65)
    love.graphics.rectangle("fill", 0, 0, ui.W, 36)
    ui.set(ui.c.text)
    love.graphics.setFont(ui.f.small)
    local name = U.basename(V.photos[V.index] or "")
    love.graphics.print(ui.fit(ui.f.small, name, ui.W - 160), 16, 18 - ui.f.small:getHeight() / 2)

    local counter = string.format("%d / %d", V.index, #V.photos)
    if V.scale > 1.05 then
      counter = string.format("%.1fx  |  %s", V.scale, counter)
    end
    if V.slideshow then
      counter = "Slideshow  |  " .. counter
    end
    love.graphics.printf(counter, ui.W - 180, 18 - ui.f.small:getHeight() / 2, 164, "right")

    -- Footer hints
    local bck = input.swap_ab and "A" or "B"
    local acc = input.swap_ab and "B" or "A"
    ui.hints({
      { "< / >", "Foto" },
      { "L2/R2", "Zoom" },
      { "Y", "Girar" },
      { "START", "Slideshow" },
      { bck, "Voltar" },
    }, 450)
  end
end

return V
