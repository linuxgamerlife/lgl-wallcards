--!nonstrict
-- Local image wallpaper browser.

local items = noctalia.state.get("wallcards.items") or {}
local status = noctalia.state.get("wallcards.status") or "loading"
local errorMessage = noctalia.state.get("wallcards.error") or ""
local directory = noctalia.state.get("wallcards.directory") or ""
local selectedPath = ""
local selectedIndex = 0
local livePreview = noctalia.getConfig("live_preview") == true
local render

local function clampColumns()
  local columns = tonumber(noctalia.getConfig("columns")) or 3
  return math.max(2, math.min(5, math.floor(columns)))
end

local function basename(path)
  return path:match("([^/]+)$") or path
end

local function findSelectedIndex()
  if selectedPath == "" then
    return 0
  end
  for index, item in ipairs(items) do
    if item.path == selectedPath then
      return index
    end
  end
  return 0
end

local function normalizeSelection()
  if #items == 0 then
    selectedIndex = 0
    selectedPath = ""
    return
  end
  local preserved = findSelectedIndex()
  if preserved > 0 then
    selectedIndex = preserved
  else
    selectedIndex = math.max(1, math.min(selectedIndex, #items))
    if selectedIndex == 0 then
      selectedIndex = 1
    end
    selectedPath = items[selectedIndex].path
  end
end

local function applySelected(closeAfter, quiet)
  if selectedIndex < 1 or items[selectedIndex] == nil then
    return
  end
  local path = items[selectedIndex].path
  if not noctalia.fileExists(path) then
    errorMessage = noctalia.tr("errors.file_missing")
    render()
    return
  end
  noctalia.setWallpaper(path)
  if not quiet then
    noctalia.notify(noctalia.tr("title"), noctalia.tr("notifications.applied", {
      name = items[selectedIndex].name,
    }))
  end
  if closeAfter then
    panel.close()
  end
end

local function selectIndex(index)
  if #items == 0 then
    return
  end
  selectedIndex = ((index - 1) % #items) + 1
  selectedPath = items[selectedIndex].path
  if livePreview then
    applySelected(false, true)
  end
  render()
end

local function selectPath(path)
  selectedPath = path
  normalizeSelection()
  if livePreview then
    applySelected(false, true)
  end
  render()
end

local function shuffle()
  if #items < 2 then
    return
  end
  local nextIndex = math.random(1, #items)
  if nextIndex == selectedIndex then
    nextIndex = (nextIndex % #items) + 1
  end
  selectIndex(nextIndex)
end

local function requestRefresh()
  status = "loading"
  errorMessage = ""
  noctalia.state.set("wallcards.scanRequest", noctalia.nowMs())
  render()
end

local function header()
  local position = #items > 0 and `{selectedIndex} / {#items}` or "0 / 0"
  return ui.row({ align = "center", gap = 8 }, {
    ui.glyph({ name = "cards", size = 22, color = "primary" }),
    ui.column({ gap = 2, flexGrow = 1 }, {
      ui.label({ text = noctalia.tr("title"), fontSize = 18, fontWeight = "bold" }),
      ui.label({
        text = directory ~= "" and directory or noctalia.tr("panel.no_directory"),
        color = "on_surface_variant",
        fontSize = 11,
        maxLines = 1,
      }),
    }),
    ui.label({ text = position, color = "on_surface_variant" }),
    ui.button({ glyph = "refresh", tooltip = noctalia.tr("actions.refresh"), onClick = requestRefresh }),
    ui.button({ glyph = "settings", tooltip = noctalia.tr("actions.settings"), onClick = function()
      noctalia.openSettings()
    end }),
    ui.button({ glyph = "close", tooltip = noctalia.tr("actions.close"), onClick = function()
      panel.close()
    end }),
  })
end

local function controls()
  return ui.row({ align = "center", gap = 8 }, {
    ui.button({ glyph = "chevron-left", text = noctalia.tr("actions.previous"), onClick = function()
      selectIndex(selectedIndex - 1)
    end }),
    ui.button({ glyph = "shuffle", text = noctalia.tr("actions.shuffle"), onClick = shuffle }),
    ui.button({ glyph = "chevron-right", text = noctalia.tr("actions.next"), onClick = function()
      selectIndex(selectedIndex + 1)
    end }),
    ui.spacer({ flexGrow = 1 }),
    ui.label({ text = noctalia.tr("panel.live_preview"), color = "on_surface_variant" }),
    ui.toggle({ checked = livePreview, onChange = function(value)
      livePreview = value == "true"
      render()
    end }),
    ui.button({ glyph = "photo", text = noctalia.tr("actions.apply"), onClick = function()
      applySelected(false, false)
    end }),
    ui.button({ glyph = "check", text = noctalia.tr("actions.apply_close"), onClick = function()
      applySelected(true, false)
    end }),
  })
end

local function wallpaperTile(item, tileWidth)
  local selected = item.path == selectedPath
  return ui.column({ gap = 5, align = "center", flexGrow = 1, key = item.path }, {
    ui.image({
      path = item.path,
      width = tileWidth,
      height = 150,
      fit = "cover",
      radius = 12,
      border = selected and "primary" or "outline",
      borderWidth = selected and 3 or 1,
      onClick = function()
        selectPath(item.path)
      end,
    }),
    ui.label({
      text = item.name,
      fontSize = 11,
      color = selected and "primary" or "on_surface_variant",
      fontWeight = selected and "bold" or "normal",
      maxLines = 1,
      maxWidth = tileWidth,
      textAlign = "center",
    }),
  })
end

local function wallpaperGrid()
  local columns = clampColumns()
  local tileWidth = math.floor((900 - ((columns - 1) * 12)) / columns)
  local rows = {}
  local index = 1
  while index <= #items do
    local children = {}
    for _column = 1, columns do
      local item = items[index]
      if item ~= nil then
        table.insert(children, wallpaperTile(item, tileWidth))
        index += 1
      else
        table.insert(children, ui.spacer({ flexGrow = 1 }))
      end
    end
    table.insert(rows, ui.row({ gap = 12, align = "start" }, children))
  end
  return ui.scroll({ flexGrow = 1, gap = 12, align = "stretch" }, rows)
end

local function body()
  if status == "loading" then
    return ui.column({ flexGrow = 1, align = "center", justify = "center", gap = 12 }, {
      ui.glyph({ name = "loader-2", size = 32, color = "primary" }),
      ui.label({ text = noctalia.tr("panel.loading"), color = "on_surface_variant" }),
    })
  elseif status == "error" then
    return ui.column({ flexGrow = 1, align = "center", justify = "center", gap = 12 }, {
      ui.glyph({ name = "alert-circle", size = 32, color = "error" }),
      ui.label({ text = errorMessage, color = "error", maxWidth = 680, textAlign = "center" }),
      ui.button({ glyph = "refresh", text = noctalia.tr("actions.try_again"), onClick = requestRefresh }),
    })
  elseif #items == 0 then
    return ui.column({ flexGrow = 1, align = "center", justify = "center", gap = 12 }, {
      ui.glyph({ name = "photo-off", size = 32, color = "on_surface_variant" }),
      ui.label({ text = noctalia.tr("panel.empty"), color = "on_surface_variant" }),
      ui.button({ glyph = "refresh", text = noctalia.tr("actions.refresh"), onClick = requestRefresh }),
    })
  end
  return wallpaperGrid()
end

render = function()
  normalizeSelection()
  panel.render(ui.column({ flexGrow = 1, gap = 12, align = "stretch" }, {
    header(),
    ui.separator(),
    body(),
    ui.separator(),
    controls(),
  }))
end

noctalia.state.watch("wallcards.items", function(value)
  items = type(value) == "table" and value or {}
  normalizeSelection()
  render()
end)

noctalia.state.watch("wallcards.status", function(value)
  status = value or "loading"
  render()
end)

noctalia.state.watch("wallcards.error", function(value)
  errorMessage = value or ""
  render()
end)

noctalia.state.watch("wallcards.directory", function(value)
  directory = value or ""
  render()
end)

function onOpen(_context)
  livePreview = noctalia.getConfig("live_preview") == true
  requestRefresh()
end

function onIpc(event, payload)
  if event == "refresh" then
    requestRefresh()
  elseif event == "next" then
    selectIndex(selectedIndex + 1)
  elseif event == "previous" then
    selectIndex(selectedIndex - 1)
  elseif event == "shuffle" then
    shuffle()
  elseif event == "apply" then
    applySelected(payload == "close", false)
  end
end

render()
