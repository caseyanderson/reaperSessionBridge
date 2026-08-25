local _, mode = reaper.GetAudioDeviceInfo("MODE")
local _, inputDevice = reaper.GetAudioDeviceInfo("IDENT_IN")
local _, outputDevice = reaper.GetAudioDeviceInfo("IDENT_OUT")

reaper.MB(
    "Operating system: " .. reaper.GetOS()
        .. "\nAudio mode: " .. mode
        .. "\nInput device: " .. inputDevice
        .. "\nOutput device: " .. outputDevice,
    "REAPER Audio Device",
    0
)
