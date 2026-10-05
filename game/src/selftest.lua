-- Automated smoke test, enabled with env R36S_AUTOTEST=1 (never runs on the device).
-- Plays the first track found, exercises the main actions and saves screenshots
-- (np1.png / browser.png / np2.png) to LÖVE's save directory, then quits.
local app = require("src.app")
local player = require("src.player")
local fs = require("src.fs")
local U = require("src.util")

local T = { t = 0, step = 0 }

local steps = {}

local function log(...)
  print("[selftest]", ...)
end

function T.start()
  log("root=" .. app.root)
end

steps[1] = { 0.5, function()
  log("screen=" .. tostring(app.current_name))
  love.graphics.captureScreenshot("home.png")
end }

steps[2] = { 1.2, function()
  app.show("settings")
  log("showing settings")
end }

steps[3] = { 1.8, function()
  love.graphics.captureScreenshot("settings.png")
  local theme = require("src.theme")
  theme.set("amoled")
  log("theme set to amoled")
end }

steps[4] = { 2.4, function()
  love.graphics.captureScreenshot("settings_amoled.png")
  local theme = require("src.theme")
  theme.set("dark")
  app.show("home")
end }

steps[5] = { 3.0, function()
  local tracks = fs.collect(app.root)
  log("tracks found: " .. #tracks)
  if #tracks > 0 then
    player.play_queue(tracks, 1)
  end
  app.show("nowplaying")
end }

steps[6] = { 4.5, function()
  love.graphics.captureScreenshot("np1.png")
  app.show("home")
end }

steps[7] = { 5.5, function()
  log("home with mini player")
  love.graphics.captureScreenshot("home_playing.png")
end }

steps[8] = { 6.5, function()
  log("DONE")
  love.event.quit()
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
