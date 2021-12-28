(
var samplesFolder = "../audio";

//clean slate
e = ();
ProxySpace.pop;
topEnvironment.use{ ~envReady = nil };
p = nil;
Buffer.freeAll;
s.newBusAllocators;

//establish ProxySpace
p = ProxySpace.push(s);

s.waitForBoot({

    //load sound files into buffers
    s.sync;
    e.bf = ();
    PathName(PathName(thisProcess.nowExecutingPath).parentPath ++ samplesFolder).entries.do{
        |x|
        var ext = x.extension;
        if (x.isFile && ((ext == "wav") || (ext == "aiff")), {
            e.bf.add(x.fileNameWithoutExtension.asSymbol -> Buffer.read(s, x.fullPath));
            s.sync;
        });
    };

    //create wavetables
    s.sync;
    e.wt = ();
    e.wt.add('wt0' -> Buffer.loadCollection(s,
        Wavetable.sineFill(4096, [1, 0.2, 0.3, 0.4, 0.5, 0.3, 0.1, 0.05], 0!8))
    );
    e.wt.add('wt1' -> Buffer.loadCollection(s,
        Wavetable.sineFill(4096, [1, 0.5, 0.4, 0.3, 0.2, 0.1, 0.3, 0.05], [0, 0, pi, 0, 0, pi, 0, 0]))
    );

    //load stock SynthDefs

    s.sync;
    ("SynthDefs.scd").loadRelative;

    //install final limiter
    s.sync;
    ServerTree.removeAll;
    ServerTree.add({
        e.fx = ();
        e.fx.finalLimiter = Synth(\finalLimiter, [\out, 0], target: RootNode(s), addAction: \addToTail); s.sync;
    });
    s.freeAll;

    //all done
    s.sync;
    topEnvironment.use{ ~envReady = true };
    "Environment ready.".postln;
});
)
