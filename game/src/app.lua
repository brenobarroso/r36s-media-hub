-- Shared application table (avoids circular requires between screens and main).
local app = {
  time = 0,
  root = "/",
  state = {},
  screens = {},
  current = nil,
  current_name = nil,
}

function app.show(name, ...)
  app.current = app.screens[name]
  app.current_name = name
  if app.current.enter then app.current.enter(...) end
end

return app
