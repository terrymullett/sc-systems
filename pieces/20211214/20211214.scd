(
var stability = 0, path = thisProcess.nowExecutingPath.dirname, tempo, nextFigure, thisFigure, w, tDisp1, tDisp2,
bStor, bTrig, sRand, buttons, bSave, bLoad, bClear, bPlay, bRec, player, playing, newFigure, tempoFunc, pattern;

{
    "../../setup/Setup.scd".loadRelative;
    topEnvironment.use { {~envReady.isNil}.while {0.1.wait}};

    /*
    set the strategies for varying the melody and rhythm of figures
    */
    newFigure = {
        (
            degrees: Pseq([0,2,5,6,8,11].scramble, inf),
            durs: Pseq( 2.pow((-4..1).scramble), inf ),
            velocities:  Pdup(6, Pseq([ 0.2, 0.6, 0.9 ].scramble, inf)),
        )
    };

    /*
    set the strategy for determining and varying tempo
    */
    tempoFunc = {[2, 1].wchoose([0.75, 0.25])};

    /*
    set the overall pattern definition, keys included will have to be determined by the
    SynthDef chosen for \instrument. Set the scale and root degree here too. LFOs used in
    the pattern can be set up a few lines below
    */
    pattern = {
        Pbind(
            \instrument, \highLonesome1,
            \scale, Scale.enigmatic, \root, 3,
            \degree, thisFigure.degrees, \dur, thisFigure.durs, \vel, thisFigure.velocities,
            \octave, Pdup(4, Pseq([3,4,5], inf) ),
            \legato, Pfunc({rrand(0.01,1)}),
            \amp, 0.1,
            \rel, 4,
            \pan, ~lfo0,
            \detuner, ~lfo1,
        );
    };

    /*
    set up LFOs
    */
    ~lfo0 = {LFNoise2.kr(0.5).bipolar(0.5)};
    ~lfo1 = {LFNoise2.kr(0.5).range(0, 0.2)};

    e.player = ();
    e.player.patterns = OrderedIdentitySet();

    Window.allWindows.do{|x| if( x.name == "Control", {x.close})};
    w = Window("Control", Rect(10, 150, 600, 190), resizable: false);
    e.player.win = w;

    StaticText(w, Rect(0, 0, 200, 20))
    .canFocus_(false)
    .align_(\center)
    .font_(Font("Monaco"))
    .string_("then");

    StaticText(w, Rect(200, 0, 200, 20))
    .canFocus_(false)
    .align_(\center)
    .font_(Font("Monaco"))
    .string_("certainty");

    StaticText(w, Rect(400, 0, 200, 20))
    .canFocus_(false)
    .align_(\center)
    .font_(Font("Monaco"))
    .string_("now");

    tDisp1 = StaticText(w, Rect(0, 20, 200, 120))
    .canFocus_(false)
    .align_(\center)
    .stringColor_(Color.white)
    .background_(Color.black)
    .font_(Font("Monaco", 96))
    .string_(e.player.patterns.size);

    tDisp2 = StaticText(w, Rect(400, 20, 200, 120))
    .canFocus_(false)
    .align_(\center)
    .stringColor_(Color.new255(134, 215, 47))
    .background_(Color.black)
    .font_(Font("Monaco", 96))
    .string_("");

    sRand = Slider(w, Rect(200, 20, 200, 20))
    .canFocus_(false)
    .orientation_(\horizontal)
    .action_({|v|
        stability = v.value;
    });

    bStor = Button(w, Rect(200, 40, 100, 100))
    .canFocus_(false)
    .font_(Font("Monaco", 48))
    .states_([["♲"]])
    .action_({|v|
        if(thisFigure.notNil, {e.player.patterns.add(thisFigure)});
        tDisp1.string_(e.player.patterns.size);
        tDisp2.string_(e.player.patterns.size);
    });

    bTrig = Button(w, Rect(300, 40, 100, 100))
    .canFocus_(false)
    .font_(Font("Monaco", 48))
    .states_([["☘"]])
    .action_({|v|
        nextFigure = newFigure.()
    });

    bClear = Button(w, Rect(0, 140, 120, 50))
    .canFocus_(false)
    .font_(Font("Monaco", 18))
    .states_([["Clear"]])
    .action_({|v|
        e.player.patterns = OrderedIdentitySet();
        tDisp1.string_(0)
    });

    bSave = Button(w, Rect(120, 140, 120, 50))
    .canFocus_(false)
    .font_(Font("Monaco", 18))
    .states_([["Save"]])
    .action_({|v|
        var f;
        FileDialog({|fname|
            var name;
            if (fname.endsWith(".scd"), {name = fname}, {name = fname ++ ".scd"});
            f = File(name, "w");
            f.write(e.player.patterns.asCompileString ++ "\n");
            f.close();
        }, fileMode: 0, acceptMode: 1, stripResult: true, path: path);
    });

    bLoad = Button(w, Rect(240, 140, 120, 50))
    .canFocus_(false)
    .font_(Font("Monaco", 18))
    .states_([["Load"]])
    .action_({|v|
        FileDialog({|fname|
            e.player.patterns = fname.load;
            tDisp1.string_(e.player.patterns.size);
        }, fileMode: 1, acceptMode: 0, stripResult: true, path: path);
    });

    bPlay = Button(w, Rect(360, 140, 120, 50))
    .canFocus_(false)
    .font_(Font("Monaco", 18))
    .states_([["Play"],["Stop"],["Stopping"]])
    .action_({|v|
        switch (v.value,
            {1}, {
                player.reset.play;
                tDisp2.stringColor_(Color.new255(134, 215, 47));
            },
            {2}, {
                playing = false;
                tDisp2.stringColor_(Color.gray);
                bPlay.enabled_(false);
            },
            {0}, {
                tDisp2.string_("").stringColor_(Color.new255(134, 215, 47));
                bPlay.enabled_(true);
            },
        );
    });

    bRec = Button(w, Rect(480, 140, 120, 50))
    .canFocus_(false)
    .font_(Font("Monaco", 18))
    .states_([["Record", Color.black],["Rec Stop", Color.red]])
    .action_({|v|
        switch(v.value,
            {1}, { s.record; },
            {0}, { s.stopRecording;},
        );
    });

    w.front;

    player = r{
        p.makeTempoClock.quant_(4);

        ~out = { \in.ar(0!2) };
        ~out[100] = \filterIn -> {
            |in|
            var sig = NHHall.ar(
                in: in,
                rt60: 2,
                stereo: 0.5,
                lowFreq: 200,
                lowRatio: 0.5,
                hiFreq: 3000,
                hiRatio: 0.5,
                earlyDiffusion: 0.5,
                lateDiffusion: 0.5,
                modRate: 0.2,
                modDepth: 0.3
            );
            sig = CombL.ar(sig, 0.1, LFNoise2.ar(freq: 0.1).range(0, 0.01), 0.03);
            LeakDC.ar(HPF.ar(LPF.ar(sig, 4000), 20));
        };
        ~out.set(\wet100, 0.075);
        ~out[200] = \filter -> { |in| LeakDC.ar(BHiPass4.ar(in, 40))}; ~out.set(\wet200, 1);
        ~a <>> ~out;
        ~out.play;

        playing = true;
        {playing}.while{
            if (e.player.patterns.size > 0, {
                if (nextFigure.isNil, {
                    if (stability.coin, {
                        var whichOne = e.player.patterns.size.rand;
                        thisFigure = e.player.patterns.asArray[whichOne].copy;
                        { tDisp2.string_((whichOne + 1).asString) }.defer;
                    }, {
                        thisFigure = newFigure.();
                        { tDisp2.string_("new") }.defer;
                    });
                }, {
                    thisFigure = nextFigure.copy;
                    nextFigure = nil;
                    { tDisp2.string_("new") }.defer;
                });
            }, {
                thisFigure = newFigure.();
                { tDisp2.string_("new") }.defer;
            }
            );
            tempo = tempoFunc.();
            p.clock.tempo_(tempo);
            ~a[0] = pattern.();
            [8, 16].choose.wait;
        };
        ~a.objects.do( _.stop );
        ~a.free(fadeTime: 2);
        2.wait;
        { bPlay.valueAction_(0) }.defer;
        "done".postln;
        s.sync;
    };
}.fork(AppClock);
)
