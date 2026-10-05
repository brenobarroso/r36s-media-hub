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
  local tracks = fs.collect(app.root)
  log("tracks found: " .. #tracks)
  if #tracks == 0 then
    log("FAIL: no tracks under root")
    love.event.quit(1)
    return
  end
  local ok = player.play_queue(tracks, 1)
  log("play_queue ok=" .. tostring(ok) .. " err=" .. tostring(player.error))
  app.show("nowplaying")
end }

steps[2] = { 3.0, function()
  local c = player.cur
  if not c then log("FAIL: nothing loaded") love.event.quit(1) return end
  log(string.format("title=%s | artist=%s | album=%s | track=%s | dur=%s | cover=%s | pos=%.2f | status=%s",
    tostring(c.title), tostring(c.artist), tostring(c.album), tostring(c.track),
    tostring(c.duration), tostring(c.cover ~= nil), player.position(), player.status))
  love.graphics.captureScreenshot("np1.png")
end }

steps[3] = { 3.5, function() player.seek(10) end }
steps[4] = { 4.5, function()
  log(string.format("after seek +10: pos=%.2f", player.position()))
  player.toggle()
end }
steps[5] = { 5.0, function()
  log("status after toggle=" .. player.status)
  love.graphics.captureScreenshot("np2.png")
end }
steps[6] = { 5.5, function()
  player.toggle()
  app.show("browser")
end }
steps[7] = { 6.0, function() love.graphics.captureScreenshot("browser.png") end }
steps[8] = { 6.5, function()
  player.next()
  log("next -> " .. tostring(player.cur and player.cur.title) .. " status=" .. player.status)
end }
steps[9] = { 8.0, function()
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
