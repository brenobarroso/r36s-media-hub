-- Theme manager: Dark, AMOLED (pure #000000), Light.
local Theme = {
  current_name = "dark",
}

Theme.palettes = {
  dark = {
    name        = "Escuro (Dark)",
    bg          = { 0.055, 0.065, 0.095 },
    panel       = { 0.095, 0.115, 0.165 },
    panel2      = { 0.140, 0.165, 0.230 },
    accent      = { 0.20, 0.82, 0.64 },
    text        = { 0.94, 0.96, 0.98 },
    dim         = { 0.58, 0.63, 0.72 },
    faint       = { 0.28, 0.32, 0.41 },
    card_bg     = { 0.085, 0.105, 0.150 },
    card_sel    = { 0.120, 0.170, 0.240 },
    card_border = { 0.20, 0.82, 0.64 },
  },
  amoled = {
    name        = "Preto Puro (AMOLED)",
    bg          = { 0.00, 0.00, 0.00 },
    panel       = { 0.05, 0.05, 0.06 },
    panel2      = { 0.10, 0.10, 0.12 },
    accent      = { 0.00, 0.92, 0.75 },
    text        = { 1.00, 1.00, 1.00 },
    dim         = { 0.65, 0.65, 0.68 },
    faint       = { 0.20, 0.20, 0.22 },
    card_bg     = { 0.04, 0.04, 0.05 },
    card_sel    = { 0.09, 0.11, 0.13 },
    card_border = { 0.00, 0.92, 0.75 },
  },
  light = {
    name        = "Claro (Light)",
    bg          = { 0.92, 0.93, 0.94 },
    panel       = { 0.84, 0.86, 0.88 },
    panel2      = { 0.76, 0.78, 0.82 },
    accent      = { 0.06, 0.55, 0.45 },
    text        = { 0.10, 0.12, 0.16 },
    dim         = { 0.38, 0.42, 0.48 },
    faint       = { 0.65, 0.68, 0.72 },
    card_bg     = { 0.98, 0.98, 0.99 },
    card_sel    = { 0.86, 0.92, 0.90 },
    card_border = { 0.06, 0.55, 0.45 },
  },
}

Theme.list = { "dark", "amoled", "light" }

function Theme.get()
  return Theme.palettes[Theme.current_name] or Theme.palettes.dark
end

function Theme.set(name)
  if Theme.palettes[name] then
    Theme.current_name = name
  else
    Theme.current_name = "dark"
  end
  return Theme.get()
end

function Theme.cycle()
  local cur = Theme.current_name
  for i, n in ipairs(Theme.list) do
    if n == cur then
      local nxt = Theme.list[(i % #Theme.list) + 1]
      return Theme.set(nxt)
    end
  end
  return Theme.set("dark")
end

return Theme
