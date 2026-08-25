# SuperCollider project workflow

## Install the project tools

1. Install these repositories at the indicated locations:

   - [projectTemplate](https://github.com/caseyanderson/projectTemplate): `~/projectTemplate`
   - [midiFighterControllerPanel](https://github.com/caseyanderson/midiFighterControllerPanel): `~/midiFighterControllerPanel`
   - [gainStageDoctor](https://github.com/caseyanderson/gainStageDoctor): `~/gainStageDoctor`
   - [reaperSessionBridge](https://github.com/caseyanderson/reaperSessionBridge): `~/reaperSessionBridge`

2. In REAPER, open **Actions → Show action list**.
3. Choose **New action → Load ReaScript**.
4. Load `~/reaperSessionBridge/reaperSessionSetup.lua`.
5. Confirm that **Synchronize SuperCollider recording tracks** appears in the action list.
6. Choose **New action → Load ReaScript** again.
7. Load `~/reaperSessionBridge/reaperAudioDeviceDiagnostic.lua`.
8. Optionally assign the setup action a keyboard shortcut or toolbar button.

## Configure audio routing

1. Configure the platform’s audio routing.

   On Windows, select these devices in REAPER:

   ```text
   Audio system: ASIO
   Input device: ASIO Voicemeeter Virtual ASIO
   Output device: ASIO Voicemeeter Virtual ASIO
   ```

   Leave input monitoring off for the Voicemeeter configuration.

   On macOS, create an aggregate device named `BlackHole + MixPre` with BlackHole 16ch first and MixPre-3M after it. Select that aggregate device in REAPER. Input monitoring must be on.

2. Use the following recording-channel mapping:

   | SuperCollider output | REAPER input |
   |---:|---:|
   | 0 | 1 |
   | 1 | 2 |
   | 2 | 3 |
   | 3 | 4 |

3. On macOS, route the REAPER master to:

   ```text
   17: Out 1 (MixPre-3M) / Out 2 (MixPre-3M)
   ```

   The REAPER session action configures this route automatically.

4. Run `~/reaperSessionBridge/reaperAudioDeviceDiagnostic.lua` from REAPER’s action list and confirm that it reports the intended input and output device.

## Configure the MIDI controllers

1. Open MIDI Fighter Utility.
2. Configure each Twister encoder switch as **Note Toggle**.
3. Enable **Momentary CC** for Spectra.
4. Disable Spectra **Spark** animation.
5. Connect the Twister and Spectra before starting SuperCollider.
6. Open the controller panel in prototype mode.
7. Activate each Twister knob and Spectra pad the project will use. Inactive controls do not pass physical input to the project.
8. Activate a Twister knob with its encoder switch or GUI activation control. Activate a Spectra pad with its GUI activation control.

## Start a new project

1. Copy the `~/projectTemplate` directory.
2. Rename the copied directory for the new project.
3. Open `project_config.scd` in the copied directory.
4. Find the project identity section near the top:

   ```supercollider
   ~projectName = \projectTemplate;
   ~projectTitle = "Project Template";
   ```

5. Replace `\projectTemplate` and `"Project Template"` with the new project's SuperCollider name and display title.
6. In the shared-tool path section immediately below it, confirm that the shared tools point to their home-directory installations:

   ```supercollider
   ~homeDir = Platform.userHomeDir;
   ~controllerDir = ~homeDir +/+ "midiFighterControllerPanel";
   ~gainStageDoctorDir = ~homeDir +/+ "gainStageDoctor";
   ~reaperSessionBridgeDir = ~homeDir +/+ "reaperSessionBridge";
   ```

7. Find the existing controller configuration:

   ```supercollider
   ~projectControllerConfig = (
       mode: \performance,
       controllers: \both,
       twisterActive: [0],
       spectraActive: [0]
   );
   ```

8. Change `mode` to `\prototype` while deciding which controls the project needs. Leave `controllers`, `twisterActive`, and `spectraActive` in this existing block and update their values as the project develops.
9. Find the existing gain-stage, REAPER publication, and input settings:

    ```supercollider
    ~useGainStageDoctor = true;
    ~publishReaperSession = false;
    ~projectInputMode = \spectra;
    ```

10. Leave `~useGainStageDoctor` enabled when using the standard gain-stage workflow.
11. Leave `~publishReaperSession` set to `false` while prototyping.
12. Set `~projectInputMode` to the existing `\keyboard`, `\spectra`, or `\none` option appropriate for the current prototype.
13. Do not add a project path to `project.scd`. Its existing startup code determines the copied project's directory automatically:

    ```supercollider
    ~projectDir = PathName(thisProcess.nowExecutingPath).pathOnly;
    (~projectDir +/+ "project_config.scd").load;
    ```

14. Run `project.scd`.
15. Confirm that SuperCollider posts `<Project Title> is ready.` and opens the project in prototype mode.

## Open a prototype REAPER session

1. Open `project_config.scd` and confirm that `~publishReaperSession = false`.
2. Run `project.scd` so the project clears any previous manifest.
3. Open a REAPER project.
4. Run **Synchronize SuperCollider recording tracks**.
5. Confirm that REAPER creates four armed tracks with the following names and inputs:

   | Track name | SuperCollider output | REAPER mono input |
   |---|---:|---:|
   | `sc out 0` | 0 | 1 |
   | `sc out 1` | 1 | 2 |
   | `sc out 2` | 2 | 3 |
   | `sc out 3` | 3 | 4 |

6. Use the monitoring state required by the platform's audio-routing configuration.

## Test the starter sound

1. Run the copied project’s `project.scd`.
2. With the default Spectra input configuration, press Spectra pad 0.
3. Move Twister knob 0 to change the example sound’s amplitude.
4. Adjust makeup gain and output trim.
5. Confirm that the sound reaches `sc out 0` in REAPER at a usable level.

## Develop SynthDefs and tasks

1. Open the copied `project_synthDefs.scd`.
2. Locate the starter SynthDef and modify or replace it with the project's SynthDefs.
3. Preserve the template's initialization and cleanup structure around the SynthDef definitions.
4. When the project requires tasks, routines, Patterns, or other sequencing behavior, add clearly named project files beside the other `.scd` project files.
5. Open `project.scd` and add each new file to the existing project-file loading section at the startup stage where it is needed.
6. Continue using SuperCollider hardware outputs 0 through 3 while deciding which sounds need separate REAPER recording tracks.
7. Test each sound's output, stopping behavior, and project cleanup while developing it.

## Define recording sources and outputs

1. Decide which project roles need separate REAPER tracks.
2. Open `project_init.scd`.
3. Locate the existing `~projectSources` array.
4. Modify the starter source entry and add or remove source entries until the array contains one entry for each independently recorded project role.
5. For each source entry, replace the starter `name` with the short canonical project-role name that should appear on its REAPER track.
6. Replace the starter `label` with the name that should appear in the controller and gain-stage interfaces.
7. Assign each source a unique zero-based `hardwareOut` from 0 through 3.
8. Keep the existing gain-stage fields in each source entry and adjust their values for that source when needed.
9. Keep or modify the existing `twisterMap` in each source entry while developing its controls.
10. Run `project.scd`.
11. Trigger each source and confirm that it reaches the prototype REAPER track corresponding to its zero-based `hardwareOut`.

## Map Twister and Spectra controls

1. Keep the controller panel in prototype mode while developing mappings. To change the currently running panel, evaluate:

   ```supercollider
   ~projectSetPanelMode.(\prototype);
   ```

2. Assign Twister controls by source column:

   | Source column | Knobs |
   |---:|---|
   | 0 | 0, 4, 8, 12 |
   | 1 | 1, 5, 9, 13 |
   | 2 | 2, 6, 10, 14 |
   | 3 | 3, 7, 11, 15 |

3. Open `project_init.scd`.
4. Locate `twisterMap` inside each entry of the existing `~projectSources` array.
5. Modify those entries to assign the source's Twister knobs, Synth arguments, GUI labels, and value ranges.
6. Open `project_actions.scd` when adding or changing the project actions triggered by controllers or other inputs.
7. Open the active `project_input_*.scd` file when changing how keyboard or Spectra input calls those actions.
8. Test each mapped knob and pad with the project running.

## Set recording levels

1. Set `amp` to the loudest musical performance level expected from the source.
2. Trigger several representative sounds or gestures.
3. Add makeup gain only when the source needs compensation or additional drive.
4. Set output trim for the desired final REAPER recording level.
5. Confirm that the post-trim meter remains below clipping.
6. Confirm that each source reaches only its intended REAPER track.

## Generate and apply the REAPER configuration

1. Open `project_init.scd` and confirm that `~projectSources` contains the intended source names and output assignments.
2. Open `project_config.scd`.
3. Change `~publishReaperSession` from `false` to `true`.
4. Run `project.scd` again to publish the current source configuration.
5. Return to the existing REAPER project containing the prototype tracks.
6. Run **Synchronize SuperCollider recording tracks** and choose **Yes** for the displayed project title.
7. Review the resulting track names, inputs, and track count against `~projectSources`.
8. The action must leave unrelated REAPER tracks untouched.

## Change an existing REAPER configuration

1. Open `project_init.scd` and edit `~projectSources`.
2. Change source names, source count, or `hardwareOut` assignments as required.
3. Leave `~publishReaperSession = true` in `project_config.scd`.
4. Run `project.scd` to regenerate the manifest.
5. Run **Synchronize SuperCollider recording tracks** in REAPER.
6. Choose **Yes** for the displayed project title.
7. Review the updated track names, inputs, and track count.
8. If a surplus bridge-managed track contains media, move or remove that media before running the action again. The bridge does not remove a managed track containing media.

## Return to REAPER prototype tracks

1. Run **Synchronize SuperCollider recording tracks**.
2. If a manifest is present, choose **No** when asked whether to use it.
3. The bridge-managed tracks return to `sc out 0` through `sc out 3` without changing unrelated tracks.

## Switch the controller panel to performance mode

1. While still in prototype mode, activate the Twister knobs and Spectra pads the finished project should use.
2. Open `project_config.scd` and find the existing controller configuration:

   ```supercollider
   ~projectControllerConfig = (
       mode: \prototype,
       controllers: \both,
       twisterActive: [0],
       spectraActive: [0]
   );
   ```

3. Change `mode` to `\performance`.
4. Set `twisterActive` and `spectraActive` to the controls that should be active when the project starts.
5. Set `controllers` to `\twister`, `\spectra`, or `\both` for the required performance interface.
6. Run `project.scd` again. The project now opens directly in performance mode with only the configured controls.
7. To switch the currently running panel without restarting the project, evaluate:

   ```supercollider
   ~projectSetPanelMode.(\performance);
   ```

## Verify a recording session

1. Trigger each source independently.
2. Confirm that each source reaches only its intended REAPER track and that the loudest expected sounds do not clip.
3. Make and play back a short test recording.
4. Run the SuperCollider project cleanup before starting another project.

