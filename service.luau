--!nonstrict
-- Discovers supported images and publishes a serializable wallpaper index.

local DEFAULT_EXTENSIONS = { "png", "jpg", "jpeg", "webp" }

local function normalizeExtensions(value)
  local result = {}
  local source = type(value) == "table" and value or DEFAULT_EXTENSIONS
  for _, extension in ipairs(source) do
    if type(extension) == "string" then
      local normalized = noctalia.string.trim(extension):lower():gsub("^%.", "")
      if normalized ~= "" then
        result[normalized] = true
      end
    end
  end
  return result
end

local function extensionOf(name)
  return name:match("%.([^./]+)$")
end

local function joinPath(directory, name)
  if directory:sub(-1) == "/" then
    return directory .. name
  end
  return directory .. "/" .. name
end

local function parentDirectory(path)
  local withoutTrailingSlash = path:gsub("/+$", "")
  return withoutTrailingSlash:match("^(.*)/[^/]+$") or ""
end

local function usableDirectory(path)
  if type(path) ~= "string" or path == "" then
    return nil
  end
  local expanded = noctalia.expandPath(path):gsub("^file://", "")
  local info = noctalia.fileInfo(expanded)
  if info ~= nil and info.isDir == true then
    return expanded
  end
  if info ~= nil and info.isDir ~= true then
    local parent = parentDirectory(expanded)
    local parentInfo = parent ~= "" and noctalia.fileInfo(parent) or nil
    if parentInfo ~= nil and parentInfo.isDir == true then
      return parent
    end
  end
  return nil
end

local function resolveWallpaperDirectory()
  local override = noctalia.getConfig("wallpaper_directory")
  if type(override) == "string" and override ~= "" then
    return usableDirectory(override), noctalia.expandPath(override)
  end

  local configured = noctalia.wallpaperDirectory()
  local resolved = usableDirectory(configured)
  if resolved ~= nil then
    return resolved, configured
  end

  local fallback = noctalia.expandPath("~/Pictures/Wallpapers")
  return usableDirectory(fallback), configured or fallback
end

local function publishError(message)
  noctalia.state.set("wallcards.items", {})
  noctalia.state.set("wallcards.error", message)
  noctalia.state.set("wallcards.status", "error")
end

local function sortItems(items)
  local order = noctalia.getConfig("sort_order") or "name"
  table.sort(items, function(a, b)
    if order == "newest" and a.mtime ~= b.mtime then
      return a.mtime > b.mtime
    elseif order == "oldest" and a.mtime ~= b.mtime then
      return a.mtime < b.mtime
    end
    return a.name:lower() < b.name:lower()
  end)
end

local function persistIndex(items)
  local dataDir = noctalia.pluginDataDir()
  if dataDir == nil then
    return
  end
  local encoded = noctalia.json.encode(items, true)
  if encoded ~= nil then
    noctalia.writeFile(joinPath(dataDir, "wallpapers.json"), encoded)
  end
end

local function scan()
  noctalia.state.set("wallcards.status", "loading")
  noctalia.state.set("wallcards.error", "")

  local directory, attemptedDirectory = resolveWallpaperDirectory()
  if directory == nil then
    noctalia.state.set("wallcards.directory", attemptedDirectory or "")
    publishError(noctalia.tr("errors.no_directory"))
    return
  end
  noctalia.state.set("wallcards.directory", directory)

  local names, listError = noctalia.listDir(directory)
  if names == nil then
    publishError(listError or noctalia.tr("errors.read_failed"))
    return
  end

  local extensions = normalizeExtensions(noctalia.getConfig("image_extensions"))
  local items = {}
  for _, name in ipairs(names) do
    local extension = extensionOf(name)
    if extension ~= nil and extensions[extension:lower()] == true then
      local path = joinPath(directory, name)
      local info = noctalia.fileInfo(path)
      if info ~= nil and info.isDir ~= true then
        table.insert(items, {
          name = name,
          path = path,
          size = info.size or 0,
          mtime = info.mtime or 0,
        })
      end
    end
  end

  sortItems(items)
  persistIndex(items)
  noctalia.state.set("wallcards.items", items)
  noctalia.state.set("wallcards.scannedAt", noctalia.nowMs())
  noctalia.state.set("wallcards.status", "ready")
end

noctalia.state.watch("wallcards.scanRequest", function(_value)
  scan()
end)

function onConfigChanged()
  scan()
end

function onIpc(event, _payload)
  if event == "refresh" then
    scan()
  end
end

scan()
