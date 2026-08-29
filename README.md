# reaperSessionBridge

Cross-platform synchronization of REAPER recording tracks with SuperCollider recording sources.

reaperSessionBridge is designed to work with [projectTemplate](https://github.com/caseyanderson/projectTemplate), [midiFighterControllerPanel](https://github.com/caseyanderson/midiFighterControllerPanel), and [gainStageDoctor](https://github.com/caseyanderson/gainStageDoctor).

See the [projectTemplate README](https://github.com/caseyanderson/projectTemplate#readme) for the complete installation, prototyping, performance, and recording workflow.

## Requirements

- [SuperCollider](https://supercollider.github.io/): tested with version 3.13.0
- [REAPER](https://www.reaper.fm/): tested with version 7
- Windows: Voicemeeter Virtual ASIO
- macOS: an aggregate device named `BlackHole + MixPre`

## Files

- `sessionSetup.lua`: synchronizes bridge-managed REAPER recording tracks
- `audioDeviceDiagnostic.lua`: reports REAPER’s audio-device configuration
- `reaperSessionManifest.scd`: publishes and clears SuperCollider recording manifests

## Install the REAPER actions

1. In REAPER, open **Actions → Show action list**
2. Choose **New action → Load ReaScript**
3. Load `~/reaperSessionBridge/sessionSetup.lua`
4. Confirm that **Synchronize SuperCollider recording tracks** appears in the action list
5. Choose **New action → Load ReaScript**
6. Load `~/reaperSessionBridge/audioDeviceDiagnostic.lua`

REAPER runs the current contents of these files. Updated versions do not need to be added to the action list again.

## Prototype tracks

When no project manifest is available, the synchronization action creates four bridge-managed tracks:

| Track name | SuperCollider output | REAPER mono input |
|---|---:|---:|
| `sc out 0` | 0 | 1 |
| `sc out 1` | 1 | 2 |
| `sc out 2` | 2 | 3 |
| `sc out 3` | 3 | 4 |

These tracks provide a temporary routing configuration while a project’s recording sources are still being determined.

## Project manifests

A manifest provides:

- The project title
- The number of independent recording sources
- The name of each recording source
- The zero-based SuperCollider hardware output assigned to each source

The bridge supports one to four sources using unique SuperCollider outputs from `0` through `3`.

When a manifest exists, the REAPER action asks whether to apply it. Choosing **Yes** synchronizes the bridge-managed tracks with the manifest. Choosing **No** uses the four prototype tracks.

## SuperCollider interface

Load the manifest helper:

```supercollider
~reaperSessionBridgeDir =
    Platform.userHomeDir +/+ "reaperSessionBridge";

(~reaperSessionBridgeDir
    +/+ "reaperSessionManifest.scd").load;
```

Publish the current recording configuration:

```supercollider
~reaperSessionBridge[\publish].(
    ~projectTitle,
    ~projectSources
);
```

Each source requires a name and zero-based hardware output:

```supercollider
(
    name: \sourceName,
    hardwareOut: 0
)
```

Clear the current manifest:

```supercollider
~reaperSessionBridge[\clear].();
```

## Platform behavior

### Windows

For Voicemeeter Virtual ASIO, bridge-managed tracks are:

- Armed for recording
- Assigned to the corresponding mono input
- Configured with input monitoring off

### macOS

For the `BlackHole + MixPre` aggregate device, bridge-managed tracks are:

- Armed for recording
- Assigned to the corresponding mono input
- Configured with input monitoring on

The synchronization action routes the REAPER master to:

```text
17: Out 1 (MixPre-3M) / Out 2 (MixPre-3M)
```

## Managed-track safety

The action changes only tracks marked as bridge-managed.

It can:

- Rename managed tracks
- Change their mono inputs
- Change their monitoring state
- Arm them for recording
- Add or remove empty managed tracks to match the requested configuration

It does not change unrelated tracks.

A managed track containing media is not removed automatically.

## Audio-device diagnostic

Run `audioDeviceDiagnostic.lua` from REAPER’s action list to display:

- Operating system
- Audio mode
- Input device
- Output device

The diagnostic reports the current REAPER configuration but does not change it.

## Verify the bridge

1. Open an empty REAPER project
2. Run **Synchronize SuperCollider recording tracks** without a manifest
3. Confirm that four prototype tracks appear
4. Publish a test manifest from SuperCollider
5. Run the synchronization action again
6. Choose **Yes** for the displayed project title
7. Confirm that the track names, inputs, monitoring states, and track count match the manifest
8. Confirm that unrelated REAPER tracks remain unchanged
