# reaperSessionBridge

A small cross-platform bridge for configuring REAPER recording tracks from a SuperCollider project.

SuperCollider publishes a project manifest containing source names and zero-based hardware outputs. The REAPER action reads that manifest and synchronizes only the recording tracks it manages. When no manifest exists, the action creates four prototype tracks named `sc out 0` through `sc out 3`.

## Requirements

- SuperCollider
- REAPER
- Windows audio routing through Voicemeeter Virtual ASIO, or
- macOS audio routing through a `BlackHole + MixPre` aggregate device

The current workflow has been tested with SuperCollider 3.13 and REAPER 7.

## Install the REAPER actions

1. Clone or place this repository at:

   ```text
   ~/reaperSessionBridge
   ```

2. In REAPER, open **Actions → Show action list**.
3. Choose **New action → Load ReaScript**.
4. Load:

   ```text
   ~/reaperSessionBridge/reaperSessionSetup.lua
   ```

5. Optionally load the audio-device diagnostic:

   ```text
   ~/reaperSessionBridge/reaperAudioDeviceDiagnostic.lua
   ```

## SuperCollider integration

A SuperCollider project loads:

```supercollider
~reaperSessionBridgeDir =
    Platform.userHomeDir +/+ "reaperSessionBridge";

(~reaperSessionBridgeDir
    +/+ "reaperSessionManifest.scd").load;
```

The project can then publish its current recording configuration:

```supercollider
~reaperSessionBridge[\publish].(
    ~projectTitle,
    ~projectSources
);
```

Each source requires:

```supercollider
(
    name: \sourceName,
    hardwareOut: 0
)
```

SuperCollider hardware outputs are zero-based. The bridge supports one to four sources using unique outputs from `0` through `3`.

A new project can clear the manifest while its source configuration is still being developed:

```supercollider
~reaperSessionBridge[\clear].();
```

## Files

- `reaperSessionSetup.lua` — synchronizes managed REAPER recording tracks
- `reaperAudioDeviceDiagnostic.lua` — reports REAPER’s current audio-device configuration
- `reaperSessionManifest.scd` — publishes or clears the SuperCollider session manifest
- `WORKFLOW.md` — usage instructions from initial project prototyping through finalized recording mappings

## Usage

See [WORKFLOW.md](WORKFLOW.md) for the complete project workflow.
