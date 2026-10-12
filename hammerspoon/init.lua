hs.autoLaunch(true)

local blockedOutputName = "C24F390"
local preferredOutputNames = { "External Headphones", "LG ULTRAWIDE", "MacBook Pro Speakers" }

local function switchAwayFromBlockedOutput()
  local currentOutput = hs.audiodevice.defaultOutputDevice()
  if not currentOutput or currentOutput:name() ~= blockedOutputName then return end

  for _, outputName in ipairs(preferredOutputNames) do
    local candidate = hs.audiodevice.findOutputByName(outputName)
    if candidate then
      candidate:setDefaultOutputDevice()
      candidate:setDefaultEffectDevice()
      return
    end
  end
end

hs.audiodevice.watcher.setCallback(function(event)
  if event == "dOut" or event == "sOut" then switchAwayFromBlockedOutput() end
end)
hs.audiodevice.watcher.start()
switchAwayFromBlockedOutput()
