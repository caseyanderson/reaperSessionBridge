(
///////// REAPER SESSION MANIFEST

var manifestPath;

manifestPath =
Platform.userHomeDir +/+ "supercollider_reaper_session.tsv";

~reaperSessionBridge = (
    manifestPath: manifestPath,

    clear: {
        if(File.exists(manifestPath), {
            File.delete(manifestPath);

            if(File.exists(manifestPath), {
                ("Could not remove REAPER session manifest: "
                    ++ manifestPath).error;
            }, {
                "REAPER session manifest cleared.".postln;
            });
        });
    },

    publish: { |projectTitle, sources|
        var hardwareOutputs, manifestFile;

        case
        { projectTitle.isNil } {
            "REAPER session manifest requires a project title.".error;
        }
        { sources.isNil } {
            "REAPER session manifest requires a source collection.".error;
        }
        { sources.isEmpty } {
            "REAPER session manifest requires at least one source.".error;
        }
        { sources.size > 4 } {
            "REAPER session manifest supports at most four sources.".error;
        }
        {
            sources.any { |source|
                source[\name].isNil
                or: { source[\hardwareOut].isNil }
            }
        } {
            "Each REAPER source requires name and hardwareOut.".error;
        }
        {
            sources.any { |source|
                source[\hardwareOut] < 0
                or: { source[\hardwareOut] > 3 }
            }
        } {
            "REAPER source hardwareOut must be between 0 and 3.".error;
        }
        {
            hardwareOutputs =
            sources.collect { |source|
                source[\hardwareOut]
            };

            hardwareOutputs.asSet.size
            != hardwareOutputs.size
        } {
            "REAPER sources must use unique hardwareOut values.".error;
        }
        { true } {
            manifestFile = File(manifestPath, "w");

            if(manifestFile.isOpen.not, {
                ("Could not write REAPER session manifest: "
                    ++ manifestPath).error;
            }, {
                protect {
                    manifestFile.write("schema\t1\n");

                    manifestFile.write(
                        "project\t"
                        ++ projectTitle.asString
                        ++ "\n"
                    );

                    sources.do { |source|
                        manifestFile.write(
                            "source\t"
                            ++ source[\name].asString
                            ++ "\t"
                            ++ source[\hardwareOut].asString
                            ++ "\n"
                        );
                    };
                } {
                    manifestFile.close;
                };

                ("REAPER session manifest written: "
                    ++ manifestPath).postln;
            });
        };
    }
);
)
