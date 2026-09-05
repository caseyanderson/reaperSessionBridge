local bridgeField = "P_EXT:reaperSessionBridge"
local windowsDevice = "ASIO Voicemeeter Virtual ASIO"
local macDevice = "CoreAudio BlackHole + MixPre"
local manifestName = "supercollider_reaper_session.tsv"

local function stop(message)
    reaper.MB(
        message,
        "REAPER Session Setup",
        0
    )
end

local function readManifest(path)
    local file = io.open(path, "r")

    if not file then
        return nil
    end

    local manifest = {
        schema = nil,
        project = nil,
        sources = {}
    }

    for line in file:lines() do
        local fields = {}

        for field in (line .. "\t"):gmatch("(.-)\t") do
            fields[#fields + 1] = field
        end

        if fields[1] == "schema" then
            manifest.schema = tonumber(fields[2])
        elseif fields[1] == "project" then
            manifest.project = fields[2]
        elseif fields[1] == "source" then
            manifest.sources[#manifest.sources + 1] = {
                name = fields[2],
                output = tonumber(fields[3])
            }
        end
    end

    file:close()
    return manifest
end

local function validateManifest(manifest)
    if manifest.schema ~= 1 then
        return "Unsupported or missing manifest schema."
    end

    if not manifest.project or manifest.project == "" then
        return "The manifest does not contain a project title."
    end

    if #manifest.sources < 1 then
        return "The manifest does not contain any recording sources."
    end

    if #manifest.sources > 4 then
        return "The manifest contains more than four recording sources."
    end

    local outputs = {}

    for _, source in ipairs(manifest.sources) do
        if not source.name or source.name == "" then
            return "A manifest source does not have a name."
        end

        if not source.output
            or source.output < 0
            or source.output > 3
            or source.output % 1 ~= 0
        then
            return "A manifest source has an invalid SuperCollider output."
        end

        if outputs[source.output] then
            return "Multiple manifest sources use the same SuperCollider output."
        end

        outputs[source.output] = true
    end

    return nil
end

local function prototypeSources()
    local sources = {}

    for output = 0, 3 do
        sources[#sources + 1] = {
            name = "sc out " .. output,
            output = output
        }
    end

    return sources
end

local function managedOutput(track)
    local _, value = reaper.GetSetMediaTrackInfo_String(
        track,
        bridgeField,
        "",
        false
    )

    return tonumber(value:match("^schema:1;output:(%d+)$"))
end

local function ensureMasterHardwareOutput()
    local masterTrack = reaper.GetMasterTrack(0)
    local hardwareOutputCount =
        reaper.GetTrackNumSends(masterTrack, 1)
    local blackHoleOutputIndex = nil
    local mixPreDestination = 16

    for sendIndex = 0, hardwareOutputCount - 1 do
        local sourceChannels = reaper.GetTrackSendInfo_Value(
            masterTrack,
            1,
            sendIndex,
            "I_SRCCHAN"
        )

        local destinationChannels = reaper.GetTrackSendInfo_Value(
            masterTrack,
            1,
            sendIndex,
            "I_DSTCHAN"
        )

        if sourceChannels == 0
            and destinationChannels == mixPreDestination
        then
            reaper.SetTrackSendInfo_Value(
                masterTrack,
                1,
                sendIndex,
                "B_MUTE",
                0
            )

            return
        end

        if sourceChannels == 0
            and destinationChannels == 0
        then
            blackHoleOutputIndex = sendIndex
        end
    end

    if blackHoleOutputIndex then
        reaper.SetTrackSendInfo_Value(
            masterTrack,
            1,
            blackHoleOutputIndex,
            "I_DSTCHAN",
            mixPreDestination
        )

        reaper.SetTrackSendInfo_Value(
            masterTrack,
            1,
            blackHoleOutputIndex,
            "B_MUTE",
            0
        )

        return
    end

    local sendIndex =
        reaper.CreateTrackSend(masterTrack, nil)

    reaper.SetTrackSendInfo_Value(
        masterTrack,
        1,
        sendIndex,
        "I_SRCCHAN",
        0
    )

    reaper.SetTrackSendInfo_Value(
        masterTrack,
        1,
        sendIndex,
        "I_DSTCHAN",
        mixPreDestination
    )
end

local operatingSystem = reaper.GetOS()
local _, audioMode = reaper.GetAudioDeviceInfo("MODE")
local _, inputDevice = reaper.GetAudioDeviceInfo("IDENT_IN")
local _, outputDevice = reaper.GetAudioDeviceInfo("IDENT_OUT")
local audioDeviceInfoAvailable =
    audioMode ~= ""
    or inputDevice ~= ""
    or outputDevice ~= ""
local userHome
local pathSeparator
local inputMonitoring
local configureMasterOutput = false

if operatingSystem == "Win64" then
    if audioDeviceInfoAvailable
        and (
            audioMode ~= "ASIO"
            or inputDevice ~= windowsDevice
            or outputDevice ~= windowsDevice
        )
    then
        stop(
            "Configure REAPER to use Voicemeeter Virtual ASIO."
                .. "\n\nDetected mode: " .. tostring(audioMode)
                .. "\nDetected input: " .. tostring(inputDevice)
                .. "\nDetected output: " .. tostring(outputDevice)
        )
        return
    end

    userHome = os.getenv("USERPROFILE")
    pathSeparator = "\\"
    inputMonitoring = 0
elseif operatingSystem:match("^macOS") then
    if audioDeviceInfoAvailable
        and (
            inputDevice ~= macDevice
            or outputDevice ~= macDevice
        )
    then
        stop(
            "Configure REAPER to use BlackHole + MixPre."
                .. "\n\nDetected input: " .. tostring(inputDevice)
                .. "\nDetected output: " .. tostring(outputDevice)
        )
        return
    end

    userHome = os.getenv("HOME")
    pathSeparator = "/"
    inputMonitoring = 1
    configureMasterOutput = true
else
    stop(
        "Unsupported operating system: "
            .. tostring(operatingSystem)
    )
    return
end

if not userHome or userHome == "" then
    stop("The operating system did not provide a user-home directory.")
    return
end

local manifestPath =
    userHome .. pathSeparator .. manifestName
local manifest = readManifest(manifestPath)
local desiredSources

if manifest then
    local manifestError = validateManifest(manifest)

    if manifestError then
        stop(
            manifestError
                .. "\n\nManifest: "
                .. manifestPath
        )
        return
    end

    local choice = reaper.MB(
        "Use the manifest for \""
            .. manifest.project
            .. "\"?"
            .. "\n\nYes: configured project tracks"
            .. "\nNo: four prototype tracks"
            .. "\nCancel: make no changes",
        "REAPER Session Setup",
        3
    )

    if choice == 2 then
        return
    elseif choice == 6 then
        desiredSources = manifest.sources
    else
        desiredSources = prototypeSources()
    end
else
    desiredSources = prototypeSources()
end

local managedTracks = {}
local managedByOutput = {}

for trackIndex = 0, reaper.CountTracks(0) - 1 do
    local track = reaper.GetTrack(0, trackIndex)
    local output = managedOutput(track)

    if output then
        if managedByOutput[output] then
            stop(
                "Multiple bridge-managed tracks claim SC output "
                    .. output
                    .. "."
            )
            return
        end

        managedTracks[#managedTracks + 1] = {
            track = track,
            output = output
        }

        managedByOutput[output] = track
    end
end

local desiredOutputs = {}

for _, source in ipairs(desiredSources) do
    desiredOutputs[source.output] = true
end

for _, managed in ipairs(managedTracks) do
    if not desiredOutputs[managed.output]
        and reaper.CountTrackMediaItems(managed.track) > 0
    then
        local _, trackName = reaper.GetSetMediaTrackInfo_String(
            managed.track,
            "P_NAME",
            "",
            false
        )

        stop(
            "The surplus bridge-managed track \""
                .. trackName
                .. "\" contains media and was not removed."
                .. "\n\nMove or remove its media, then run setup again."
        )
        return
    end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

if configureMasterOutput then
    ensureMasterHardwareOutput()
end

for _, managed in ipairs(managedTracks) do
    if not desiredOutputs[managed.output] then
        reaper.DeleteTrack(managed.track)
    end
end

for _, source in ipairs(desiredSources) do
    local track = managedByOutput[source.output]

    if not track then
        reaper.InsertTrackAtIndex(
            reaper.CountTracks(0),
            true
        )

        track = reaper.GetTrack(
            0,
            reaper.CountTracks(0) - 1
        )
    end

    reaper.GetSetMediaTrackInfo_String(
        track,
        "P_NAME",
        source.name,
        true
    )

    reaper.GetSetMediaTrackInfo_String(
        track,
        bridgeField,
        "schema:1;output:" .. source.output,
        true
    )

    reaper.SetMediaTrackInfo_Value(
        track,
        "I_RECINPUT",
        source.output
    )

    reaper.SetMediaTrackInfo_Value(
        track,
        "I_RECMODE",
        0
    )

    reaper.SetMediaTrackInfo_Value(
        track,
        "I_RECARM",
        1
    )

    reaper.SetMediaTrackInfo_Value(
        track,
        "I_RECMON",
        inputMonitoring
    )
end

reaper.PreventUIRefresh(-1)
reaper.TrackList_AdjustWindows(false)
reaper.UpdateArrange()
reaper.Undo_EndBlock(
    "Synchronize SuperCollider recording tracks",
    -1
)
