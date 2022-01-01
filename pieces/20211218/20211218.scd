(
"../../setup/Setup.scd".loadRelative;
{
    var numVoices = 12;
    var notesSelection = [0, 1, 5, 6];
    var octavesSelection = [3, 4, 5, 6];
    var dursSelection = 2.pow((-2..2)) * 4;
    var root = 4;

    var w, b, player, playing = false;

    topEnvironment.use{ { ~envReady.isNil }.while{ 0.1.wait } };

    p.clear;
    p.fadeTime_(2);

    ~out = { \in.ar(0!2) };
    ~out[100] = \filterIn -> {
        |in|
        //controls
        var hpf = \hpf.kr(50);                  // high pass filter cutoff frequency for the output
        var lpf = \lpf.kr(4000);                // low pass filter cutoff frequency for the output
        var lpf1 = \lpf1.kr(2000);              // low pass filter cutoff frequency for the Comb array
        var decay = \decay.kr(0.5);             // reverberation decay time
        var predelay = \predelay.kr(0.05);      // reverb pre-delay

        var sig = DelayN.ar(in, predelay);
        sig = LPF.ar(Mix.ar(Array.fill(16, { CombL.ar(sig, 0.1, LFNoise1.kr(0.1.rand, 0.04, 0.05), decay) })), lpf1);
        8.do({ sig = AllpassN.ar(sig, 0.050, [0.050.rand, 0.050.rand], decay) });
        LeakDC.ar(HPF.ar(LPF.ar(sig, lpf), hpf));
    };
    ~out.set(\wet100, 0.1);
    ~out[200] = \filter -> { |in| LeakDC.ar(BHiPass4.ar(in, 40))}; ~out.set(\wet200, 1);
    ~a.ar(2);
    ~a <>> ~out;
    ~out.play;

    player = r{
        playing = true;
        {playing}.while {
            var notes, octave, durs, spacing, slot = 0;
            notes = notesSelection.rotate((notesSelection.size - 1).xrand2());
            notes = notes.keep(rrand(1, notes.size - 1));
            if (0.5.coin, { notes = notes.reverse });
            octave = octavesSelection.wchoose([1,4,2,0.5].normalizeSum);
            durs = dursSelection.scramble.keep(notes.size);
            spacing = ((durs.sum)/(1.exp));
            {
                var amp = -20.dbamp;
                var lpfFactor = 3;
                var rq = 0.25;
                var detuner = 0.1;
                var mySlot = slot;
                {playing && (amp > -60.dbamp) }.while {
                    ~a[mySlot] = Pbind(
                        \instrument, \chimes,
                        \dur, Pseq(durs, 1),
                        \note, Pseq(notes, 1),
                        \root, root,
                        \atk, 0.5,
                        \rel, Pkey(\dur) * 0.75,
                        \octave, octave,
                        \amp, amp,
                        \lpf, Pkey(\freq) * lpfFactor,
                        \rq, rq,
                        \detuner, detuner,
                    );
                    spacing.wait;
                    amp = 0.5 * amp;
                    lpfFactor = 0.75 * lpfFactor;
                    rq = rq * 1.25;
                    detuner = detuner * 1.15;
                };
                ~a.removeAt(mySlot);
            }.fork;
            slot = (slot + 1) % numVoices;
            (spacing * 1.exp).wait;
        };
        numVoices.do{|i| ~a[i].free(fadeTime: 0.5); 0.25.wait};
        ~a.free(fadeTime: 4);
        4.wait;
        { b.valueAction_(0) }.defer;
    };

    Window.allWindows.do{|x| if( x.name == "Control", {x.close})};
    w = Window.new("Control", Rect(50,(Window.screenBounds.height-300),256,256), resizable: false);
    b = Button(w, Rect(0, 0, 256, 256))
    .font_(Font("Monaco", 60))
    .canFocus_(false)
    .states_([["Play"],["Stop"],["Stopping"]])
    .action_({|v|
        switch (v.value,
            {1}, {
                player.reset.play;
            },
            {2}, {
                playing = false;
                b.enabled_(false);
            },
            {0}, {
                b.enabled_(true);
            },
        );
    });
    w.front;
    s.makeGui

}.fork(AppClock);
)
