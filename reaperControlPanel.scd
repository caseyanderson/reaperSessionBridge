(
///////// REAPER CONTROL PANEL

~reaperControlWindow.tryPerform(\close);

~reaperControlPanel = (
    address: NetAddr(
        "127.0.0.1",
        8000
    ),

    readManifest: {
        var manifest;
        var manifestPath;

        manifestPath =
        ~reaperSessionBridge.tryPerform(
            \at,
            \manifestPath
        );

        manifest = (
            project: "No published project",
            sources: List.new
        );

        if(
            manifestPath.notNil
            and: { File.exists(manifestPath) },
            {
                File.readAllString(manifestPath)
                .split(Char.nl)
                .do { |line|
                    var fields;

                    fields = line.split(Char.tab);

                    if(fields[0] == "project", {
                        manifest[\project] =
                        fields[1];
                    });

                    if(fields[0] == "source", {
                        manifest[\sources].add((
                            name: fields[1],
                            hardwareOut:
                            fields[2].asInteger
                        ));
                    });
                };
            }
        );

        manifest;
    },

    sendAction: { |oscPath|
        ~reaperControlPanel[\address].sendMsg(
            oscPath,
            1.0
        );
    },

    open: {
        var actionRows;
        var actionSpecs;
        var manifest;
        var sourceViews;

        manifest =
        ~reaperControlPanel[\readManifest].();

        sourceViews =
        manifest[\sources].collect { |source|
            StaticText()
            .string_(
                source[\name]
                ++ ": SuperCollider output "
                ++ source[\hardwareOut]
            );
        };

        if(sourceViews.isEmpty, {
            sourceViews = [
                StaticText()
                .string_("No published recording sources")
            ];
        });

        actionSpecs = [
            [
                "Setup Session",
                "/reaper/sessionSetup"
            ],
            [
                "Insert Marker",
                "/reaper/insertMarker"
            ],
            [
                "Reset Project Session",
                "/reaper/resetProjectSession"
            ],
            [
                "Set Time Selection",
                "/reaper/setTimeSelectionFromCursor"
            ],
            [
                "Find Seamless Loop",
                "/reaper/findSeamlessLoop"
            ]
        ];

        actionRows =
        actionSpecs.clump(2).collect { |row|
            HLayout(*row.collect { |action|
                Button()
                .states_([
                    [action[0]]
                ])
                .action_({
                    ~reaperControlPanel[
                        \sendAction
                    ].(action[1]);
                });
            });
        };

        ~reaperControlWindow =
        Window(
            "REAPER Control Panel",
            Rect(100, 100, 460, 300)
        )
        .layout_(VLayout(*(
            [
                StaticText()
                .string_(manifest[\project])
                .align_(\center)
            ]
            ++ sourceViews
            ++ actionRows
        )))
        .front;
    }
);

~reaperControlPanel[\open].();
)
