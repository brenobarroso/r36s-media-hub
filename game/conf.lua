-- R36S Media Hub - LÖVE configuration
function love.conf(t)
  t.identity = "r36s-media-hub"
  t.version = "11.5"
  t.console = false

  t.window.title = "R36S Media Hub"
  t.window.width = 640
  t.window.height = 480
  t.window.resizable = false
  t.window.vsync = 1
  -- The PortMaster launcher exports R36S_FULLSCREEN=1 on the device.
  if os.getenv("R36S_FULLSCREEN") == "1" then
    t.window.fullscreen = true
    t.window.fullscreentype = "desktop"
  end

  t.modules.physics = false
  t.modules.video = false
  t.modules.touch = false
  t.modules.thread = false
end
