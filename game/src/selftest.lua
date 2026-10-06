-- Automated smoke test, enabled with env R36S_AUTOTEST=1 (never runs on the device).
-- Tests all screens (Home, Settings, Photos, Videos, Books, NowPlaying), exercises features, saves screenshots, then quits cleanly.
local app = require("src.app")
local player = require("src.player")
local fs = require("src.fs")
local theme = require("src.theme")
local U = require("src.util")

local T = { t = 0, step = 0 }
local steps = {}

local function log(...)
  print("[selftest]", ...)
end

function T.start()
  log("Media Hub self-test started, root=" .. tostring(app.root))
end

-- Step 1: Home screen
steps[1] = { 0.4, function()
  log("screen=" .. tostring(app.current_name))
  love.graphics.captureScreenshot("test_01_home.png")
end }

-- Step 2: Settings screen (Dark)
steps[2] = { 1.0, function()
  app.show("settings")
  log("showing settings")
  love.graphics.captureScreenshot("test_02_settings.png")
end }

-- Step 3: Switch theme to AMOLED
steps[3] = { 1.6, function()
  theme.set("amoled")
  log("theme set to amoled")
  player.set_eq("bass")
  log("eq set to bass")
  love.graphics.captureScreenshot("test_03_settings_amoled.png")
end }

-- Step 4: Photos screen
steps[4] = { 2.2, function()
  theme.set("dark")
  app.show("photos")
  log("showing photos screen, entries=" .. #app.screens.photos.entries)
  love.graphics.captureScreenshot("test_04_photos.png")
end }

-- Step 5: Videos screen
steps[5] = { 2.8, function()
  app.show("videos")
  log("showing videos screen, entries=" .. #app.screens.videos.entries)
  love.graphics.captureScreenshot("test_05_videos.png")
end }

-- Step 6: Books screen
steps[6] = { 3.4, function()
  app.show("books")
  log("showing books screen, entries=" .. #app.screens.books.entries)
  love.graphics.captureScreenshot("test_06_books.png")
end }

-- Step 6b: Folder Picker screen
steps[7] = { 3.8, function()
  app.show("folder_picker", "photos")
  log("showing folder picker screen, dirs=" .. #app.screens.folder_picker.dirs)
  love.graphics.captureScreenshot("test_06b_folder_picker.png")
end }

-- Step 7: Book Reader with inline test text
steps[8] = { 4.2, function()
  -- Create a temporary test book
  local tmp_book = (os.getenv("TEMP") or ".") .. "/test_book.txt"
  local f = io.open(tmp_book, "w")
  if f then
    f:write("Capítulo 1: O Começo da Jornada\n\nEste é um teste do leitor de livros para o console R36S.\nO R36S Media Hub agora suporta leitura de livros digitais em formato PDF, EPUB e TXT!\n\nAs páginas são paginadas automaticamente com controle de tamanho de fonte, marcadores de página e modo escuro para leitura confortável.")
    f:close()
  end
  app.show("book_reader", tmp_book, 1)
  log("showing book reader screen")
  love.graphics.captureScreenshot("test_07_book_reader.png")

  local user_pdf = "E:/books/Breno_Barroso_Desenvolvedor_Backend_NET.pdf"
  local uf = io.open(user_pdf, "rb")
  if uf then
    uf:close()
    app.show("book_reader", user_pdf, 1)
    log("tested user pdf reader: pages=" .. #app.screens.book_reader.pages)
    if #app.screens.book_reader.pages > 0 then
      log("PDF SAMPLE TEXT:\n" .. tostring(app.screens.book_reader.pages[1]):sub(1, 400))
    end
  end
end }

-- Step 8: Play music and show Now Playing
steps[9] = { 4.8, function()
  local tracks = fs.collect(app.root)
  log("tracks found: " .. #tracks)
  if #tracks > 0 then
    player.play_queue(tracks, 1)
  end
  app.show("nowplaying")
  log("showing now playing screen")
end }

-- Step 9: Capture Now Playing with EQ badge
steps[10] = { 5.6, function()
  love.graphics.captureScreenshot("test_08_nowplaying.png")
end }

-- Step 10: Home screen with mini player
steps[11] = { 6.2, function()
  app.show("home")
  log("showing home with mini player active")
end }

-- Step 11: Capture Home with mini player
steps[12] = { 6.8, function()
  love.graphics.captureScreenshot("test_09_home_miniplayer.png")
end }

-- Step 12: Done!
steps[13] = { 7.4, function()
  log("ALL SCREEN TESTS COMPLETED SUCCESSFULLY!")
  love.event.quit(0)
end }

function T.update(dt)
  T.t = T.t + dt
  local s = steps[T.step + 1]
  if s and T.t >= s[1] then
    T.step = T.step + 1
    local ok, err = pcall(s[2])
    if not ok then
      log("ERROR in step " .. T.step .. ": " .. tostring(err))
      love.event.quit(1)
    end
  end
end

return T
