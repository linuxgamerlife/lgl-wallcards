--!nonstrict
-- Wallcards bar widget.

local glyph = noctalia.getConfig("glyph") or "cards"

local function render()
  barWidget.setGlyph(glyph)
  barWidget.setTooltip(noctalia.tr("widget.tooltip"))
end

function update()
  render()
  noctalia.setUpdateInterval(5000)
end

function onClick()
  noctalia.togglePanel("lgl/wallcards:browser")
end

function onRightClick()
  noctalia.openSettings()
end

function onIpc(event, _payload)
  if event == "open" or event == "toggle" then
    noctalia.togglePanel("lgl/wallcards:browser")
  elseif event == "refresh" then
    noctalia.state.set("wallcards.scanRequest", noctalia.nowMs())
  end
end

render()
