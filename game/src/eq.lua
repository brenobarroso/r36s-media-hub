-- Equalizer presets using OpenAL EFX (LÖVE 11+)
local EQ = {
  current = 1,
  effect_name = "mediahub_eq",
  supported = false,
  presets = {
    { id = "flat", name = "Desligado (Flat)", settings = nil },
    {
      id = "bass",
      name = "Bass Boost",
      settings = {
        type = "equalizer",
        low_gain = 2.5,
        low_cutoff = 250,
        low_mid_gain = 1.1,
        high_mid_gain = 0.9,
        high_gain = 0.9,
      }
    },
    {
      id = "rock",
      name = "Rock",
      settings = {
        type = "equalizer",
        low_gain = 2.0,
        low_cutoff = 200,
        low_mid_gain = 0.8,
        high_mid_gain = 1.4,
        high_gain = 1.8,
        high_cutoff = 6000,
      }
    },
    {
      id = "pop",
      name = "Pop",
      settings = {
        type = "equalizer",
        low_gain = 1.4,
        low_cutoff = 250,
        low_mid_gain = 1.5,
        high_mid_gain = 1.3,
        high_gain = 1.2,
      }
    },
    {
      id = "vocal",
      name = "Voz / Acústico",
      settings = {
        type = "equalizer",
        low_gain = 0.7,
        low_mid_gain = 1.8,
        low_mid_frequency = 1000,
        high_mid_gain = 1.7,
        high_mid_frequency = 3000,
        high_gain = 1.1,
      }
    },
    {
      id = "elec",
      name = "Eletrônica",
      settings = {
        type = "equalizer",
        low_gain = 2.8,
        low_cutoff = 280,
        low_mid_gain = 0.8,
        high_mid_gain = 1.2,
        high_gain = 2.2,
        high_cutoff = 7500,
      }
    }
  }
}

function EQ.init()
  if love.audio and love.audio.isEffectsSupported then
    local ok, supp = pcall(love.audio.isEffectsSupported)
    EQ.supported = ok and supp
  end
end

function EQ.get_preset_name()
  local p = EQ.presets[EQ.current]
  return p and p.name or "Flat"
end

function EQ.apply(source)
  if not source or not EQ.supported then return end
  local p = EQ.presets[EQ.current]
  if not p or not p.settings then
    -- Flat / disabled: remove effect from source
    pcall(function()
      source:setEffect(EQ.effect_name, false)
    end)
    return
  end

  pcall(function()
    love.audio.setEffect(EQ.effect_name, p.settings)
    source:setEffect(EQ.effect_name, true)
  end)
end

function EQ.set_preset(idx_or_id, source)
  if type(idx_or_id) == "string" then
    for i, p in ipairs(EQ.presets) do
      if p.id == idx_or_id then
        EQ.current = i
        break
      end
    end
  elseif type(idx_or_id) == "number" then
    if idx_or_id >= 1 and idx_or_id <= #EQ.presets then
      EQ.current = idx_or_id
    end
  end

  if source then
    EQ.apply(source)
  end
end

function EQ.next(source)
  EQ.current = (EQ.current % #EQ.presets) + 1
  if source then
    EQ.apply(source)
  end
  return EQ.get_preset_name()
end

return EQ
