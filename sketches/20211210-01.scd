/*
Project idea for a generative strategy
☑1) A process generates parameters for a basic pattern, constrained random, for pitch and time,
switching parameters occasionally, as in sketchbook 20211206-01.scd. There will be a GUI, and
it will have a button I can push to save the current parameters into an array. When there are
parameters in the array, then I can also use a knob or slider on the GUI to determine the probability
that next swtich will generate a new one or use one from the array.
☑2) Other synth parameters to be controlled via LFOs
☑3) Synth processes straightforward but controllable, very few sound sources
☑4) Could be set to draw only from the parameters in the array, but have a trigger to generate
a new set on the next swtich only (but not add to the array automatically).
☑5) Could have the ability to clear stored pattern parameters
☑6) Could have the ability to save and restore stored pattern parameters
☑7) Could have the ability to play and stop from the gui
*/


(
var scale = Scale.locrian;
var stability = 0, tempo, nextFigure, thisFigure, newFigure;
var path = thisProcess.nowExecutingPath.dirname;
var w, tDisp1, tDisp2, bStor, bTrig, sRand, buttons, bSave, bLoad, bClear, bPlay, bStop, player, playing;

"../setup/Setup.scd".loadRelative;

e.player = ();
e.player.patterns = OrderedIdentitySet();

Window.closeAll;
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
.stringColor_(Color.white)
.background_(Color.black)
.font_(Font("Monaco", 96))
.string_("");

bStor = Button(w, Rect(200, 20, 100, 100))
.canFocus_(false)
.font_(Font("Monaco", 48))
.states_([["♲"]])
.action_({|v|
    if(thisFigure.notNil, {e.player.patterns.add(thisFigure)});
    tDisp1.string_(e.player.patterns.size);
    tDisp2.string_(e.player.patterns.size);
});

bTrig = Button(w, Rect(300, 20, 100, 100))
.canFocus_(false)
.font_(Font("Monaco", 48))
.states_([["☘"]])
.action_({|v|
    nextFigure = newFigure.()
});

sRand = Slider(w, Rect(200, 120, 200, 20))
.canFocus_(false)
.orientation_(\horizontal)
.action_({|v|
    stability = v.value;
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
.states_([["Play"]])
.action_({|v|
    player.reset.play;
    tDisp2.stringColor_(Color.white);
});

bStop = Button(w, Rect(480, 140, 120, 50))
.canFocus_(false)
.font_(Font("Monaco", 18))
.states_([["Stop"]])
.action_({|v|
    playing = false;
    tDisp2.stringColor_(Color.gray);
});

w.front;

newFigure = {
    (
        degrees: [0,2,5,6,8,11].scramble,
        durs: 2.pow((-4..1).scramble),
        velocities: [ 0.2, 0.6, 9 ].scramble,
    )
};

player = r{
    p.makeTempoClock.quant_(4);

    ~out = { \in.ar(0!2) };
    ~out[10] = \filter -> { |in| BHiPass4.ar(in, 40)}; ~out.set(\wet10, 1);
    ~a <>> ~out;
    ~out.play;
    ~lfo1 = {LFNoise2.kr(0.5).range(0, 2)};
    ~lfo2 = {LFNoise2.kr(0.5).range(0, 1)};
    ~lfo3 = {LFNoise2.kr(0.5).range(0, 0.5)};

    1.wait;
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


        tempo = [2, 1].wchoose([0.75, 0.25]);
        p.clock.tempo_(tempo);
        ~a[0] = Pbind(
            \instrument, \fm3mc_perc,
            \legato, Pfunc({rrand(0.01,1)}),
            \scale, scale,
            \root, 3,
            \degree, Pseq(thisFigure.degrees, inf),
            \dur, Pseq( thisFigure.durs, inf ),
            \octave, Pdup(4, Pseq([3,4,5], inf) ),
            \vel, Pdup(6, Pseq(thisFigure.velocities, inf)),
            \amp, 0.7,
            \mRatio1, Pseq( (3..5).scramble, inf ),
            \mRatio2, Pseq( (1..3).scramble, inf ),
            \mRatio3, Pseq( (3..5) / (1..3).scramble, inf ),
            \mIndex1, ~lfo1,
            \mIndex2, ~lfo2,
            \mIndex3, ~lfo3,
            \pan, 0,
        );
        [8, 16].choose.wait;
    };
    ~a.objects.do( _.stop );
    { tDisp2.string_("") }.defer;
    8.wait;
    "done".postln;
    ~a = 0;
    s.sync;
    // s.freeAll;
};

)
