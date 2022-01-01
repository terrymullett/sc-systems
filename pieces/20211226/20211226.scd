(
"../../setup/Setup.scd".loadRelative;
{
    var root = 58;
    var maxVoices = 5;
    var w, b, player, playing = false;

    0.1.wait;
    topEnvironment.use{ { ~envReady.isNil }.while{ 0.01.wait } };

    p.makeTempoClock(1).quant_(0);

    player = r{
        var voice = 0;
        var tune = (Pseq([[0], Pxrand([[-8],[0],[2],[4],[7],[11],[-12, 12],[-10,14],[-5,19]], inf)]) + root).asStream;
        playing = true;
        {playing}.while {
            {
                var note = tune.next;
                var time = [5, 4,3].choose, rpt = 9;
                var proxy = ("p" ++ voice.asString).asSymbol;
                var trend = Pgeom(1, 1/(2.sqrt), rpt).asStream;
                var factor;
                p[proxy].play;
                {notNil(factor = trend.next) && playing}.while {
                    p[proxy][0] = Pbind(
                        \instrument, \fm3mc_perc,
                        \dur, Pseq([time], rpt),
                        \midinote, note,
                        \amp, (110/Pkey(\freq)).pow(0.07) * (1/(2.sqrt)) * factor,
                        \vel, (1/(2.sqrt)) * factor,
                        \atk, (0.002/factor).squared,
                        \rel, Pkey(\dur) * 0.9,
                        \curve, -1,
                        \mRatio1, 4,
                        \mRatio2, 2,
                        \mRatio3, 1,
                        \mIndex1, 2.0.pow(factor),
                        \mIndex2, 1.0.pow(factor),
                        \mIndex3, 0.5.pow(factor),
                    );
                    p[proxy][100] = \filterIn -> {
                        |in|
                        LeakDC.ar(
                            LPF.ar(
                                in: Klank.ar(`[
                                    Array.geom(4, 120, 2.7),
                                    Array.fill(4, {|i| 0.9.pow(8 * (i + 1))}) * factor * 0.1,
                                    Array.geom(4, 0.125, 0.5) * factor,
                                ], in),
                                freq: (note.sort.reverse[0].midicps * 5.pow(factor)).clip(20, 20000);
                            )
                        )
                    };
                    p[proxy].set(\wet100, 0.5);
                    time.wait;
                };
            }.fork(p.clock);
            (10 - rrand(1, 8)).wait;
            voice = (voice + 1) % maxVoices;
        };
        p.free(fadeTime: 8);
        8.wait;
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
