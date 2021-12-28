(
{
    var scale = Scale.major, root = 1;
    var voices = [
        (delay: 4.0, degree: 2, dur: 19.7),
        (delay: 8.1, degree: 4, dur: 17.8),
        (delay: 5.6, degree: 6, dur: 21.3),
        (delay: 12.6, degree: 7, dur: 22.1),
        (delay: 9.2, degree: 8, dur: 18.4),
        (delay: 14.1, degree: 9, dur: 20.0),
        (delay: 3.1, degree: 11, dur: 17.7),
    ];

    var w, b, play, stop;

    "../../setup/Setup.scd".loadRelative;
    topEnvironment.use { {~envReady.isNil}.while {0.1.wait}};

    p.clear;
    p.fadeTime_(2);
    p.makeTempoClock;
    p.clock.tempo_(1);
    ~out = { \in.ar(0!2) };
    ~out.play;
    ~out[10] = \filterIn -> {
        |in|
        //controls
        var hpf = \hpf.kr(50);                  // high pass filter cutoff frequency for the output
        var lpf = \lpf.kr(6000);                // low pass filter cutoff frequency for the output
        var lpf1 = \lpf1.kr(2000);              // low pass filter cutoff frequency for the Comb array
        var decay = \decay.kr(0.5);             // reverberation decay time
        var predelay = \predelay.kr(0.05);      // reverb pre-delay

        var sig = DelayN.ar(in, predelay);
        sig = LPF.ar(Mix.ar(Array.fill(16, { CombL.ar(sig, 0.1, LFNoise1.kr(0.1.rand, 0.04, 0.05), decay) })), lpf1);
        8.do({ sig = AllpassN.ar(sig, 0.050, [0.050.rand, 0.050.rand], decay) });
        LeakDC.ar(HPF.ar(LPF.ar(sig, lpf), hpf));
    };
    ~out.set(\wet10, 0.1);
    ~out[20] = \filter -> { |in| BHiPass4.ar(in, 40)}; ~out.set(\wet20, 1);
    ~a.ar(2);
    ~a <>> ~out;
    ~lfo0 = {LFNoise2.kr(0.5).bipolar(0.5)};
    ~lfo1 = {LFNoise2.kr(0.5).range(0, 0.2)};


    play = r{
        var voicesArray = Array.new(voices.size);
        voices.size.do { |nextVoice, i|
            voicesArray= voicesArray.add({
                voices[nextVoice][\delay].wait;
                ~a[nextVoice] = Pbind(
                    \instrument, \chimes,
                    \amp, 0.2,
                    \scale, scale,
                    \root, root,
                    \octave, 4,
                    \degree, voices[nextVoice][\degree],
                    \dur, voices[nextVoice][\dur],
                    \vel, Pwhite(0.4, 0.6, inf),
                    \atk, 0.25,
                    \rel, 3,
                    \sus, 2,
                    \pan, ~lfo0,
                    \detuner, ~lfo1,
                    \lpf, Pkey(\freq) * 4,
                    \rq, 0.5,
                );
            });
        };
        voicesArray.fork(clock: p.clock);
        "all voices started".postln;
        { b.valueAction_(2) }.defer;
    };

    stop = r{
        voices.size.do{|i| ~a[i].stop; 0.5.wait};
        ~a.free(fadeTime: 2);
        { b.valueAction_(0) }.defer;
    };

    Window.allWindows.do{|x| if( x.name == "Control", {x.close})};
    w = Window.new("Control", Rect(50,100,256,256), resizable: false);
    b = Button(w, Rect(0, 0, 256, 256))
    .font_(Font("Monaco", 60))
    .canFocus_(false)
    .states_([["Play"],["Starting"],["Stop"],["Stopping"]])
    .action_({|v|
        switch (v.value,
            {1}, {
                play.reset.play(p.clock);
                b.enabled_(false);
            },
            {2}, {
                b.enabled_(true);
            },
            {3}, {
                stop.reset.play(p.clock);
                b.enabled_(false);
            },
            {0}, {
                b.enabled_(true);
            },
        );
    });
    w.front;

}.fork(AppClock);
)