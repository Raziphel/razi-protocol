-- Shared visual vocabulary for every Razi Protocol runtime panel.
-- Uses native Factorio GUI widgets; no polling animations or external assets.
local theme = {}

theme.colors = {
  calidus = {r = 0.91, g = 0.71, b = 0.38},
  solaris = {r = 1, g = 0.53, b = 0.27},
  nyxaris = {r = 0.55, g = 0.66, b = 0.95},
  vibrant = {r = 0.55, g = 0.88, b = 0.76},
  beetlejuice = {r = 0.96, g = 0.51, b = 0.49},
  ["deep-space"] = {r = 0.71, g = 0.63, b = 0.96},
  text = {r = 0.95, g = 0.94, b = 0.90},
  muted = {r = 0.67, g = 0.69, b = 0.72},
  done = {r = 0.54, g = 0.83, b = 0.56},
  active = {r = 1, g = 0.79, b = 0.39},
  locked = {r = 0.58, g = 0.61, b = 0.66},
  accent = {r = 0.74, g = 0.66, b = 0.96}
}

theme.icons = {
  calidus = "item/calidus-tech-card",
  solaris = "item/solaris-tech-card",
  nyxaris = "item/nyxaris-tech-card",
  vibrant = "item/vibrant-tech-card",
  beetlejuice = "item/beetlejuice-tech-card",
  ["deep-space"] = "item/deep-space-tech-card"
}

function theme.tint(chapter_id)
  return theme.colors[chapter_id] or theme.colors.accent
end

function theme.label(parent, caption, options)
  options = options or {}
  local label = parent.add{
    type = "label",
    caption = caption,
    tooltip = options.tooltip
  }
  label.style.single_line = options.single_line == true
  label.style.maximal_width = options.width or 710
  if options.bold then label.style.font = "default-bold" end
  label.style.font_color = options.color or theme.colors.text
  if options.margin then label.style.margin = options.margin end
  if options.padding then label.style.padding = options.padding end
  return label
end

function theme.heading(parent, caption, chapter_id)
  return theme.label(parent, caption, {
    bold = true,
    color = theme.tint(chapter_id),
    margin = {5, 0, 4, 0}
  })
end

function theme.caption(parent, caption)
  return theme.label(parent, caption, {color = theme.colors.muted, width = 680})
end

function theme.row(parent, spacing)
  local row = parent.add{type = "flow", direction = "horizontal"}
  row.style.vertical_align = "center"
  row.style.horizontal_spacing = spacing or 10
  return row
end

function theme.column(parent, spacing)
  local column = parent.add{type = "flow", direction = "vertical"}
  column.style.vertical_spacing = spacing or 6
  return column
end

function theme.card(parent, options)
  options = options or {}
  local card = parent.add{
    type = "frame",
    direction = "vertical",
    style = "inside_shallow_frame"
  }
  card.style.padding = options.padding or 10
  card.style.margin = {0, 0, 5, 0}
  card.style.horizontally_stretchable = true
  card.style.vertical_spacing = 5
  return card
end

function theme.badge(parent, text, kind, color)
  local palettes = {
    completed = theme.colors.done,
    active = theme.colors.active,
    locked = theme.colors.locked,
    branch = theme.colors.nyxaris,
    landing = theme.colors.vibrant,
    project = theme.colors.solaris
  }
  local badge = theme.label(parent, "  " .. text .. "  ", {
    bold = true,
    color = color or palettes[kind] or theme.colors.muted,
    single_line = true
  })
  badge.style.padding = {1, 4}
  return badge
end

function theme.progress(parent, completed, total, width)
  local denominator = math.max(1, total or 0)
  local value = math.max(0, math.min(1, (completed or 0) / denominator))
  local row = theme.row(parent, 8)
  local bar = row.add{type = "progressbar", value = value}
  bar.style.width = width or 250
  bar.style.height = 12
  theme.caption(row, string.format("%d / %d  (%d%%)", completed or 0, total or 0, math.floor(value * 100 + 0.5)))
  return bar
end

function theme.button(parent, name, caption, selected, tooltip)
  local button = parent.add{
    type = "button",
    name = name,
    caption = caption,
    tooltip = tooltip
  }
  button.style.padding = {5, 10}
  if selected then
    button.enabled = false
  end
  return button
end

function theme.planet_icon(parent, planet, size)
  local path = "space-location/" .. planet
  if helpers and helpers.is_valid_sprite_path and helpers.is_valid_sprite_path(path) then
    local icon = parent.add{type = "sprite", sprite = path}
    icon.style.size = size or 38
    return icon
  end
  return nil
end

function theme.chapter_icon(parent, chapter_id, size)
  local path = theme.icons[chapter_id]
  if path and helpers and helpers.is_valid_sprite_path and helpers.is_valid_sprite_path(path) then
    local icon = parent.add{type = "sprite", sprite = path}
    icon.style.size = size or 36
    return icon
  end
  return nil
end

function theme.rule(parent)
  return parent.add{type = "line"}
end

function theme.stat(parent, label, value, color)
  local card = theme.card(parent, {padding = 9})
  theme.label(card, value, {bold = true, color = color or theme.colors.text, single_line = true})
  theme.caption(card, label)
  return card
end

function theme.status(complete, started)
  if complete then return "COMPLETE", "completed" end
  if started then return "IN PROGRESS", "active" end
  return "LOCKED", "locked"
end

return theme
