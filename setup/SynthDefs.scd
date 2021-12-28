(
/*
Perc-enveloped mix of a Ringz filter and filtered pink noise.
*/
SynthDef(\highLonesome1, {
    //controls
    var out = \out.ir(0);                           // output bus
    var pan = \pan.kr(0);                           // synth pan position
    var freq = \freq.kr(440);                       // synth fundamental pitch
    var detune = \detuner.kr(0.01);                 // detune factor (using LFNoise2)
    var amp = \amp.kr(1);                           // synth output amplitude
    var vel = \vel.kr(1);                           // velocity
    var atk = \atk.kr(0.01);                        // envelope attack time
    var rel = \rel.kr(0.5);                         // envelope release time
    var curve = \curve.kr(4);                       // envelope attack curve
    var rq = \fEnvrq.kr(0.02);                      // Filter rq for pink noise envelope peak
    var rqDepth = \fEnvqDepth.kr(1.5);              // Factor to rq for envelope begin/end level
    var midEQ = \midEQ.kr(0);                       // Frequency for MidEQ center
    var midEQrq = \midEQrq.kr(3.5);                 // MidEQ reciprocal Q
    var midEQdb = \midEQdb.kr(0);                   // decibles boost/attenuation for the MidEQ
    var lpf = \lpf.kr(15000);                       // cutoff frequency for a resonant low pass filter
    var lpfRate = \lpfRate.kr(0);                   // cutoff frequency wander rate (using LFNoise2)
    var lpfDepth = \lpfDepth.kr(0);                 // cutoff frequency wander amount
    var lpfRq = \lpfRq.kr(1);                       // reciprocal quality of the resonant low pass filter
    var lpfRqRate = \lpfRqRate.kr(0);               // reciprocal quality wander rate (using LFNoise2)
    var lpfRqDepth = \lpfRqDepth.kr(0);             // reciprocal quality wander amount
    var ls = \ls.kr(100);                           // Low shelf filter cutoff frequency
    var lsdb = \lsdb.kr(0);                         // Low shelf filter gain boost/cut in dB
    var lsrs = \lsrs.kr(0.5);                       // Low shelf filter reciprocal of slope

    var env = Env.perc(
        attackTime: Rand(0.8,1.2) * atk,
        releaseTime: rel,
        curve: curve,
    ).kr(2).lag(0.01/vel) * vel.linexp(0, 1, 0.37, 1) * PinkNoise.ar(1!2).range( 0.1, 1 ).lag(0.01);

    var sig = Mix([
        (freq * LFNoise2.kr({Rand(0.08,0.11)}!6).bipolar(detune).midiratio).collect({
            arg n;
            var temp;
            temp = Ringz.ar(Impulse.ar(0), freq: n, decaytime: rel);
            temp = Pan2.ar(temp, Rand(-0.9,0.9));
            2.do({
                temp = temp * LFNoise2.kr(Rand(0.2,0.3)).range(4,8).dbamp;
                temp = temp.softclip;
            });
            temp;
        }).sum * env,
        (freq * LFNoise2.kr({Rand(0.08,0.11)}!6).bipolar(detune).midiratio).collect({
            arg n;
            var temp;
            temp = PinkNoise.ar(1);
            temp = BPF.ar(
                in: temp,
                freq: n,
                rq: env.pow(0.5).neg.range(rq, rq * rqDepth),
                mul: 1/0.02.sqrt);
            temp = Pan2.ar(temp, Rand(-0.9,0.9));
        }).sum * env,
    ]);

    if (midEQ == 0, {midEQ = freq * 5});
    sig = MidEQ.ar(sig, freq: midEQ.clip(20, 20000), rq: env.pow(0.5) * midEQrq + 0.1, db: midEQdb);
    sig = RLPF.ar(
        in: sig,
        freq: (lpf * (1 + LFNoise2.kr(lpfRate).bipolar(lpfDepth))).clip(50, 20000),
        rq: lpfRq * (1 + LFNoise2.kr(lpfRqRate).bipolar(lpfRqDepth)) * env.pow(0.5),
    );
    sig = BLowShelf.ar(in: sig, freq: ls, rs: lsrs, db: lsdb);

    sig = Balance2.ar(sig[0], sig[1], pan);
    Out.ar(out, LeakDC.ar(sig) * (amp * 0.2));
}).add;


/*
ASR-enveloped wavetable oscillator, morphs between wavetables in consecutive buffers.
The morphing is driven by an external control.
*/
SynthDef(\wtmorph0, {
    //controls
    var out = \out.ir(0);                           // output bus
    var amp = \amp.kr(1);                           // synth output amplitude
    var vel = \vel.kr(1);                           // velocity
    var pan = \pan.kr(0);                           // synth pan position
    var freq = \freq.kr(440);                       // synth main pitch
    var bufX = \bufX.kr(0);                         // the first of the consecutive buffers holding wavetables
    var bufY = \bufY.kr(1);                         // the last of the consecutive buffers holding wavetables
    var morph = \morph.kr(0);                       // morph position between wavetables, will be clipped to between bufX and bufY
    var atk = \atk.kr(0.01);                        // envelope attack time
    var sus = \sus.kr(1);                           // envelope sustain level
    var rel = \rel.kr(0.1);                         // envelope release time
    var curve = \curve.kr(1);                       // envelope segment curvature
    var gate = \gate.kr(1);                         // envelope gate
    var detuneRate = \detuneRate.kr(0.1);           // rate of lf quadratic noise for detuned chorus
    var detuneDepth = \detuneDepth.kr(0.2);         // strength of lf quadratic noise for detuned chorus
    var spread = \spread.kr(1);                     // stereo field spread for the chorus
    var midEQ = \midEQ.kr(0);                       // Frequency for MidEQ center
    var midEQrq = \midEQrq.kr(3.5);                 // MidEQ reciprocal Q
    var midEQdb = \midEQdb.kr(0);                   // decibles boost/attenuation for the MidEQ
    var lpf = \lpf.kr(15000);                       // cutoff frequency for a resonant low pass filter
    var lpfRate = \lpfRate.kr(0);                   // cutoff frequency wander rate (using LFNoise2)
    var lpfDepth = \lpfDepth.kr(0);                 // cutoff frequency wander amount
    var lpfRq = \lpfRq.kr(1);                       // reciprocal quality of the resonant low pass filter
    var lpfRqRate = \lpfRqRate.kr(0);               // reciprocal quality wander rate (using LFNoise2)
    var lpfRqDepth = \lpfRqDepth.kr(0);             // reciprocal quality wander amount
    var ls = \ls.kr(100);                           // Low shelf filter cutoff frequency
    var lsdb = \lsdb.kr(0);                         // Low shelf filter gain boost/cut in dB
    var lsrs = \lsrs.kr(0.5);                       // Low shelf filter reciprocal of slope

    var env = Env.asr(
        attackTime: atk,
        sustainLevel: sus,
        releaseTime: rel,
        curve: curve
    ).kr(2, gate).lag(0.01/vel) * vel.linexp(0, 1, 0.37, 1) * PinkNoise.ar(1!2).range( 0.1, 1 ).lag(0.01);

    var detuner = LFNoise2.kr(freq: detuneRate ! 8).bipolar(detuneDepth).midiratio;

    var sig = VOsc.ar(
        bufpos: Clip.kr(morph, bufX, bufY),
        freq: freq * detuner,
    );
    sig = Splay.ar(inArray: sig, spread: spread);

    if (midEQ == 0, {midEQ = freq * 5});
    sig = MidEQ.ar(sig, freq: midEQ.clip(20, 20000), rq: env.pow(0.5) * midEQrq + 0.1, db: midEQdb);
    sig = RLPF.ar(
        in: sig,
        freq: (lpf * (1 + LFNoise2.kr(lpfRate).bipolar(lpfDepth))).clip(20, 20000),
        rq: lpfRq * (1 + LFNoise2.kr(lpfRqRate).bipolar(lpfRqDepth)) * env.pow(0.5),
    );
    sig = BLowShelf.ar(in: sig, freq: ls, rs: lsrs, db: lsdb);

    sig = Balance2.ar(left: sig[0], right: sig[1], pos: pan);
    Out.ar(out, LeakDC.ar(sig) * env * amp);
}).add;


/*
ASR-enveloped wavetable oscillator, morphs between wavetables in consecutive buffers.
The morphing is driven by an internal LFBrownNoise2 Ugen, controllable rate.
*/
SynthDef(\wtmorph1, {
    //controls
    var out = \out.ir(0);                           // output bus
    var amp = \amp.kr(1);                           // synth output amplitude
    var vel = \vel.kr(1);                           // velocity
    var pan = \pan.kr(0);                           // synth pan position
    var freq = \freq.kr(440);                       // synth main pitch
    var morphRate = \morphRate.kr(1);               // the rate of the morphing brown noise signal
    var bufX = \bufX.kr(0);                         // the first of the consecutive buffers holding wavetables
    var bufY = \bufY.kr(1);                         // the last of the consecutive buffers holding wavetables
    var atk = \atk.kr(0.01);                        // envelope attack time
    var sus = \sus.kr(1);                           // envelope sustain level
    var rel = \rel.kr(0.1);                         // envelope release time
    var curve = \curve.kr(1);                       // envelope segment curvature
    var gate = \gate.kr(1);                         // envelope gate
    var detuneRate = \detuneRate.kr(0.1);           // rate of lf quadratic noise for detuned chorus
    var detuneDepth = \detuneDepth.kr(0.2);         // strength of lf quadratic noise for detuned chorus
    var spread = \spread.kr(1);                     // stereo field spread for the chorus
    var midEQ = \midEQ.kr(0);                       // Frequency for MidEQ center
    var midEQrq = \midEQrq.kr(3.5);                 // MidEQ reciprocal Q
    var midEQdb = \midEQdb.kr(0);                   // decibles boost/attenuation for the MidEQ
    var lpf = \lpf.kr(15000);                       // cutoff frequency for a resonant low pass filter
    var lpfRate = \lpfRate.kr(0);                   // cutoff frequency wander rate (using LFNoise2)
    var lpfDepth = \lpfDepth.kr(0);                 // cutoff frequency wander amount
    var lpfRq = \lpfRq.kr(1);                       // reciprocal quality of the resonant low pass filter
    var lpfRqRate = \lpfRqRate.kr(0);               // reciprocal quality wander rate (using LFNoise2)
    var lpfRqDepth = \lpfRqDepth.kr(0);             // reciprocal quality wander amount
    var ls = \ls.kr(100);                           // Low shelf filter cutoff frequency
    var lsdb = \lsdb.kr(0);                         // Low shelf filter gain boost/cut in dB
    var lsrs = \lsrs.kr(0.5);                       // Low shelf filter reciprocal of slope

    var env = Env.asr(
        attackTime: atk,
        sustainLevel: sus,
        releaseTime: rel,
        curve: curve
    ).kr(2, gate).lag(0.01/vel) * vel.linexp(0, 1, 0.37, 1) * PinkNoise.ar(1!2).range( 0.1, 1 ).lag(0.01);

    var detuner = LFNoise2.kr(freq: detuneRate ! 8).bipolar(detuneDepth).midiratio;

    var sig = VOsc.ar(
        bufpos: LFBrownNoise2.kr(morphRate).range(bufX, bufY),
        freq: freq * detuner,
    );
    sig = Splay.ar(inArray: sig, spread: spread);

    if (midEQ == 0, {midEQ = freq * 5});
    sig = MidEQ.ar(sig, freq: midEQ.clip(20, 20000), rq: env.pow(0.5) * midEQrq + 0.1, db: midEQdb);
    sig = RLPF.ar(
        in: sig,
        freq: (lpf * (1 + LFNoise2.kr(lpfRate).bipolar(lpfDepth))).clip(20, 20000),
        rq: lpfRq * (1 + LFNoise2.kr(lpfRqRate).bipolar(lpfRqDepth)) * env.pow(0.5),
    );
    sig = BLowShelf.ar(in: sig, freq: ls, rs: lsrs, db: lsdb);

    sig = Balance2.ar(left: sig[0], right: sig[1], pos: pan);
    Out.ar(out, LeakDC.ar(sig) * env * amp);
}).add;

/*
Bandpass-filtered Saw with a non-sustaining envelope, adapted from Eli Fieldsteel
*/
SynthDef(\bpfsaw, {
    //controls
    var out = \out.ir(0);                           // output bus
    var amp = \amp.kr(1);                           // synth output amplitude
    var vel = \vel.kr(1);                           // velocity
    var pan = \pan.kr(0);                           // synth pan position
    var freq = \freq.kr(440);                       // synth main pitch
    var detune = \detuner.kr(0);                    // detune factor (using LFNoise1)
    var atk = \atk.kr(2);                           // envelope attack time
    var sus = \sus.kr(0);                           // envelope sustain time
    var rel = \rel.kr(3);                           // envelope release time
    var curve1 = \curve1.kr(1);                     // envelope attack curve
    var curve2 = \curve2.kr(-1);                    // envelope release curve
    var bpfmin = \bpfmin.kr(500);                   // BPF cutoff freqency min (using LFNoise1)
    var bpfmax = \bpfmax.kr(2000);                  // BPF cutoff freqency max (using LFNoise1)
    var bpfhzmin = \bpfhzmin.kr(0.1);               // BPF cutoff freqency change rate min (using LFNoise1)
    var bpfhzmax = \bpfhzmax.kr(0.3);               // BPF cutoff freqency change rate max (using LFNoise1)
    var bpfrqmin = \bpfrqmin.kr(0.1);               // BPF reciprocal Q min (using LFNoise1)
    var bpfrqmax = \bpfrqmax.kr(0.2);               // BPF reciprocal Q max (using LFNoise1)
    var midEQ = \midEQ.kr(0);                       // Frequency for MidEQ center
    var midEQrq = \midEQrq.kr(3.5);                 // MidEQ reciprocal Q
    var midEQdb = \midEQdb.kr(0);                   // decibles boost/attenuation for the MidEQ
    var lpf = \lpf.kr(15000);                       // cutoff frequency for a resonant low pass filter
    var lpfRate = \lpfRate.kr(0);                   // cutoff frequency wander rate (using LFNoise2)
    var lpfDepth = \lpfDepth.kr(0);                 // cutoff frequency wander amount
    var lpfRq = \lpfRq.kr(1);                       // reciprocal quality of the resonant low pass filter
    var lpfRqRate = \lpfRqRate.kr(0);               // reciprocal quality wander rate (using LFNoise2)
    var lpfRqDepth = \lpfRqDepth.kr(0);             // reciprocal quality wander amount
    var ls = \ls.kr(100);                           // Low shelf filter cutoff frequency
    var lsdb = \lsdb.kr(0);                         // Low shelf filter gain boost/cut in dB
    var lsrs = \lsrs.kr(0.5);                       // Low shelf filter reciprocal of slope

    var env = Env(
            levels: [0, 1, 1, 0],
            times: [atk, sus, rel],
            curve: [curve1, 0, curve2]
    ).kr(2).lag(0.01/vel) * vel.linexp(0, 1, 0.37, 1) * PinkNoise.ar(1!2).range( 0.1, 1 ).lag(0.01);

    var sig = Saw.ar(freq: freq * ({ LFNoise1.kr(freq: 0.5, mul: detune).midiratio } ! 2));
    sig = BPF.ar(
        in: sig,
        freq: ({
            LFNoise1.kr(
                freq: LFNoise1.kr(4).exprange(lo: bpfhzmin, hi: bpfhzmax)
            ).exprange(lo: bpfmin, hi: bpfmax)
        } ! 2),
        rq: ({ LFNoise1.kr(freq: 0.1).exprange(lo: bpfrqmin, hi: bpfrqmax) }!2)
    );

    if (midEQ == 0, {midEQ = freq * 5});
    sig = MidEQ.ar(sig, freq: midEQ.clip(20, 20000), rq: env.pow(0.5) * midEQrq + 0.1, db: midEQdb);
    sig = RLPF.ar(
        in: sig,
        freq: (lpf * (1 + LFNoise2.kr(lpfRate).bipolar(lpfDepth))).clip(20, 20000),
        rq: lpfRq * (1 + LFNoise2.kr(lpfRqRate).bipolar(lpfRqDepth)) * env.pow(0.5),
    );
    sig = BLowShelf.ar(in: sig, freq: ls, rs: lsrs, db: lsdb);

    sig = Balance2.ar(left: sig[0], right: sig[1], pos: pan);
    Out.ar(out, LeakDC.ar(sig) * env * amp);
}).add;

/*
Pulsar synth using GrainSin and Env.perc with two formants correlated to the fundamental, adapted from
Alik Rustamoff, https://github.com/alikthename/Musical-Design-in-Supercollider/blob/master/1_sin_pulsar.sc
Envelope timing is tied to the fundamental frequency. This is moderately expensive in CPU terms, but sounds sweet.
*/
SynthDef(\sin_pulsar, {
    //controls
    var out = \out.ir(0);                           // output bus
    var pan = \pan.kr(0);                           // synth pan position
    var amp = \amp.kr(1);                           // synth output amplitude
    var vel = \vel.kr(1);                           // velocity
    var freq = \freq.kr(440);                       // synth fundamental pitch
    var formantA = \formantA.kr(2);                 // factor appled to frequency offset for first formant
    var formantB = \formantB.kr(6);                 // factor appled to frequency offset for second formant
    var overlapA = \overlapA.ar(2);                 // factor applied for grain width, first formant
    var overlapB = \overlapB.kr(2);                 // factor applied for grain width, second formant
    var midEQ = \midEQ.kr(0);                       // Frequency for MidEQ center
    var midEQrq = \midEQrq.kr(3.5);                 // MidEQ reciprocal Q
    var midEQdb = \midEQdb.kr(0);                   // decibles boost/attenuation for the MidEQ
    var lpf = \lpf.kr(15000);                       // cutoff frequency for a resonant low pass filter
    var lpfRate = \lpfRate.kr(0);                   // cutoff frequency wander rate (using LFNoise2)
    var lpfDepth = \lpfDepth.kr(0);                 // cutoff frequency wander amount
    var lpfRq = \lpfRq.kr(1);                       // reciprocal quality of the resonant low pass filter
    var lpfRqRate = \lpfRqRate.kr(0);               // reciprocal quality wander rate (using LFNoise2)
    var lpfRqDepth = \lpfRqDepth.kr(0);             // reciprocal quality wander amount
    var ls = \ls.kr(100);                           // Low shelf filter cutoff frequency
    var lsdb = \lsdb.kr(0);                         // Low shelf filter gain boost/cut in dB
    var lsrs = \lsrs.kr(0.5);                       // Low shelf filter reciprocal of slope

    var f_ = freq.clip(50, 1500);

    var env = Env.perc(
        attackTime: ( f_.linlin( 50, 1500, 0.1, 0.02) ),
        releaseTime: Rand(1,7)
    ).kr(2).lag(0.01/vel) * vel.linexp(0, 1, 0.37, 1) * PinkNoise.ar(1!2).range( 0.1, 1 ).lag(0.01);

    var sig = Mix([
        //fundamental
        GrainSin.ar(
            numChannels: 1,
            trigger: Impulse.ar(freq),
            dur: 1.5  * ( 0.05 + env.pow(0.5) ) * SinOsc.ar(env * 6, {Rand(0, 6.28)}.dup).range(0.87,1.15)  / freq,
            freq: freq * SinOsc.ar(env * 8, {Rand(0, 6.28)}.dup).range(0.9,Rand(1,1.5)),
            pan: PinkNoise.ar(0.5!2),
        ) * env.pow(0.7),
        //first formant
        GrainSin.ar(
            numChannels: 1,
            trigger: Impulse.ar(freq),
            dur:  overlapA * ( 0.05 + env.pow(0.5) ) * SinOsc.ar(env * 6, {Rand(0, 6.28)}.dup).range(0.87,1.15) / freq,
            freq: freq * ( formantA  * SinOsc.ar(env * 7, {Rand(0, 6.28)}.dup).range(0.9,1.1) ),
            pan: PinkNoise.ar(0.5!2),
        ) * env.pow(f_.linlin(50, 1500, 1.1, 1.5)),
        //second formant
        GrainSin.ar(
            numChannels: 1,
            trigger: Impulse.ar(freq + Rand(-3,3)),
            dur:  overlapB * ( 0.05 + env.pow(0.5)) * SinOsc.ar(env * 6, {Rand(0, 6.28)}.dup).range(0.87,1.15) / freq,
            freq: freq * ( formantB * SinOsc.ar(env * 8, {Rand(0, 6.28)}.dup).range(0.9,Rand(1,1.5)) ),
            pan: PinkNoise.ar(0.5!2),
        ) * env.pow(f_.linlin(50, 1500, 1.5, 2.5)),
    ]);

    if (midEQ == 0, {midEQ = freq * 5});
    sig = MidEQ.ar(sig, freq: midEQ.clip(20, 20000), rq: env.pow(0.5) * midEQrq + 0.1, db: midEQdb);
    sig = RLPF.ar(
        in: sig,
        freq: (lpf * (1 + LFNoise2.kr(lpfRate).bipolar(lpfDepth))).clip(20, 20000),
        rq: lpfRq * (1 + LFNoise2.kr(lpfRqRate).bipolar(lpfRqDepth)) * env.pow(0.5),
    );
    sig = BLowShelf.ar(in: sig, freq: ls, rs: lsrs, db: lsdb);

    sig = Balance2.ar(sig[0], sig[1], pan);
    Out.ar(out, LeakDC.ar(sig) * (amp * 0.25));
}).add;

/*
Pad synth with non-sustaining envelope, combines detuned sine, saw and filtered pink noise,
finishes with a resonant low pass filter. Adapted from Eli Fieldsteel. This will eat your CPU
for lunch if you let a bunch of instances overlap. In a pattern, be sensible with \dur, \sus,
\sustain etc.
*/
SynthDef.new(\chimes, {
    //controls
    var out = \out.ir(0);                           // output bus
    var pan = \pan.kr(0);                           // synth pan position
    var freq = \freq.kr(440);                       // synth fundamental pitch
    var detune = \detuner.kr(0.12);                 // detune factor (using LFNoise2)
    var amp = \amp.kr(1);                           // synth output amplitude
    var vel = \vel.kr(1);                           // velocity
    var atk = \atk.kr(0.002);                       // envelope attack time
    var sus = \sus.kr(0);                           // envelope sustain time
    var rel = \rel.kr(1);                           // envelope release time
    var midEQ = \midEQ.kr(0);                       // Frequency for MidEQ center
    var midEQrq = \midEQrq.kr(3.5);                 // MidEQ reciprocal Q
    var midEQdb = \midEQdb.kr(0);                   // decibles boost/attenuation for the MidEQ
    var lpf = \lpf.kr(15000);                       // cutoff frequency for a resonant low pass filter
    var lpfRate = \lpfRate.kr(0);                   // cutoff frequency wander rate (using LFNoise2)
    var lpfDepth = \lpfDepth.kr(0);                 // cutoff frequency wander amount
    var lpfRq = \lpfRq.kr(1);                       // reciprocal quality of the resonant low pass filter
    var lpfRqRate = \lpfRqRate.kr(0);               // reciprocal quality wander rate (using LFNoise2)
    var lpfRqDepth = \lpfRqDepth.kr(0);             // reciprocal quality wander amount
    var ls = \ls.kr(100);                           // Low shelf filter cutoff frequency
    var lsdb = \lsdb.kr(0);                         // Low shelf filter gain boost/cut in dB
    var lsrs = \lsrs.kr(0.5);                       // Low shelf filter reciprocal of slope

    var env = Env.new(
        levels: [0,1,1,0],
        times: [atk,sus,rel],
        curve: [2,0,-2]
    ).kr(2).lag(0.01/vel) * vel.linexp(0, 1, 0.37, 1) * PinkNoise.ar(1!2).range( 0.1, 1 ).lag(0.01);

    var sig = Mix([
        (freq * LFNoise2.kr({Rand(0.08,0.11)}!6).bipolar(detune).midiratio).collect({
            arg n;
            var temp;
            temp = SinOsc.ar(n);
            temp = Pan2.ar(temp, Rand(-0.9,0.9));
            2.do({
                temp = temp * LFNoise2.kr(Rand(0.2,0.3)).range(4,8).dbamp;
                temp = temp.softclip;
            });
            temp;
        }).sum * env,
        (freq * LFNoise2.kr({Rand(0.08,0.11)}!6).bipolar(detune).midiratio).collect({
            arg n;
            var temp;
            temp = VarSaw.ar(n, Rand(0.0,1.0), Rand(0.0,0.0001));
            temp = Pan2.ar(temp, Rand(-0.9,0.9));
            2.do({
                temp = temp * LFNoise2.kr(Rand(0.2,0.3)).range(10,15).dbamp;
                temp = temp.tanh;
            });
            temp;
        }).sum * env,
        (freq * LFNoise2.kr({Rand(0.08,0.11)}!6).bipolar(detune).midiratio).collect({
            arg n;
            var temp;
            temp = PinkNoise.ar(1);
            temp = BPF.ar(temp, n, 0.02, 1/0.02.sqrt);
            temp = Pan2.ar(temp, Rand(-0.9,0.9));
        }).sum * env,
    ]);

    if (midEQ == 0, {midEQ = freq * 5});
    sig = MidEQ.ar(sig, freq: midEQ.clip(20, 20000), rq: env.pow(0.5) * midEQrq + 0.1, db: midEQdb);
    sig = RLPF.ar(
        in: sig,
        freq: (lpf * (1 + LFNoise2.kr(lpfRate).bipolar(lpfDepth))).clip(20, 20000),
        rq: lpfRq * (1 + LFNoise2.kr(lpfRqRate).bipolar(lpfRqDepth)) * env.pow(0.5),
    );
    sig = BLowShelf.ar(in: sig, freq: ls, rs: lsrs, db: lsdb);

    sig = Balance2.ar(sig[0], sig[1], pan);
    Out.ar(out, LeakDC.ar(sig) * (amp * 0.2));
}).add;

/*
Perc-enveloped FM synth with 3 modulators correlated to the single carrier,
adapted from Alik Rustamoff.
*/
SynthDef.new(\fm3mc_perc, {
    //controls
    var out = \out.ir(0);                           // output bus
    var pan = \pan.kr(0);                           // synth pan position
    var freq = \freq.kr(440);                       // synth fundamental pitch
    var amp = \amp.kr(1);                           // synth output amplitude
    var vel = \vel.kr(1);                           // velocity
    var atk = \atk.kr(0.01);                        // envelope attack time
    var rel = \rel.kr(4);                           // envelope release time
    var curve = \curve.kr(-4);                      // envelope attack curve
    var mRatio1 = \mRatio1.kr(2);                   // fm mod ratio, first modulator
    var mIndex1 = \mIndex1.kr(1);                   // fm mod index, first modulator
    var mRatio2 = \mRatio2.kr(2);                   // fm mod ratio, second modulator
    var mIndex2 = \mIndex2.kr(0.6);                 // fm mod index, second modulator
    var mRatio3 = \mRatio3.kr(4);                   // fm mod ratio, third modulator
    var mIndex3 = \mIndex3.kr(0.3);                 // fm mod index, third modulator
    var midEQ = \midEQ.kr(0);                       // Frequency for MidEQ center
    var midEQrq = \midEQrq.kr(3.5);                 // MidEQ reciprocal Q
    var midEQdb = \midEQdb.kr(0);                   // decibles boost/attenuation for the MidEQ
    var lpf = \lpf.kr(15000);                       // cutoff frequency for a resonant low pass filter
    var lpfRate = \lpfRate.kr(0);                   // cutoff frequency wander rate (using LFNoise2)
    var lpfDepth = \lpfDepth.kr(0);                 // cutoff frequency wander amount
    var lpfRq = \lpfRq.kr(1);                       // reciprocal quality of the resonant low pass filter
    var lpfRqRate = \lpfRqRate.kr(0);               // reciprocal quality wander rate (using LFNoise2)
    var lpfRqDepth = \lpfRqDepth.kr(0);             // reciprocal quality wander amount
    var ls = \ls.kr(100);                           // Low shelf filter cutoff frequency
    var lsdb = \lsdb.kr(0);                         // Low shelf filter gain boost/cut in dB
    var lsrs = \lsrs.kr(0.5);                       // Low shelf filter reciprocal of slope

    var env = Env.perc(
        attackTime: Rand(0.8,1.2) * atk,
        releaseTime: rel,
        curve: curve,
    ).kr(2).lag(0.01/vel) * vel.linexp(0, 1, 0.37, 1) * PinkNoise.ar(1!2).range( 0.1, 1 ).lag(0.01);

    var sig = SinOsc.ar(
        freq
        + LFTri.ar(env.pow(0.5) * LFNoise1.kr(0.3).range(1,5), Rand(0.0,2pi), mul: env.pow(0.2) *  freq * 0.005)
        + [
            SinOsc.ar(freq * mRatio1 + { Rand(-3,3) }.dup) * freq * mIndex1 * env.pow(0.8),
            SinOsc.ar(freq * mRatio2 + { Rand(-3,3) }.dup) * freq * mIndex2 * env.pow(1.4),
            SinOsc.ar(freq * mRatio3 + { Rand(-3,3) }.dup) * freq * mIndex3 * env.pow(2.5),
            WhiteNoise.ar(freq/8!2).lag(0.001),
        ].sum
    ) * env;
    sig = HPF.ar(sig, freq);

    if (midEQ == 0, {midEQ = freq * 5});
    sig = MidEQ.ar(sig, freq: midEQ.clip(20, 20000), rq: env.pow(0.5) * midEQrq + 0.1, db: midEQdb);
    sig = RLPF.ar(
        in: sig,
        freq: (lpf * (1 + LFNoise2.kr(lpfRate).bipolar(lpfDepth))).clip(20, 20000),
        rq: lpfRq * (1 + LFNoise2.kr(lpfRqRate).bipolar(lpfRqDepth)) * env.pow(0.5),
    );
    sig = BLowShelf.ar(in: sig, freq: ls, rs: lsrs, db: lsdb);

    sig = Balance2.ar(sig[0], sig[1], pan);
    Out.ar(out, LeakDC.ar(sig) * amp * 0.3);
}).add;

/*
ASR-enveloped buffer playback synth for mono buffers
*/
SynthDef(\pb1, {
    //controls
    var out = \out.ir(0);                           // output bus
    var amp = \amp.kr(1);                           // synth output amplitude
    var pan = \pan.kr(0);                           // synth pan position
    var buf = \buf.ir(0);                           // buffer containing the audio to play
    var rate = \rate.ir(1);                         // buffer playback rate factor
    var spos = \spos.ir(0);                         // play start position in the buffer
    var loop = \loop.kr(1);                         // 0 to not loop, 1 to loop the buffer
    var atk = \atk.kr(0.01);                        // envelope attack time
    var sus = \sus.kr(1);                           // envelope sustain level
    var rel = \rel.kr(0.1);                         // envelope release time
    var curve = \curve.kr(1);                       // envelope segment curvature
    var gate = \gate.kr(1);                         // envelope gate

    var env = Env.asr(
        attackTime: atk,
        sustainLevel: sus,
        releaseTime: rel,
        curve: curve
    ).kr(doneAction: 2, gate: gate);

    var sig = PlayBuf.ar(
        numChannels: 1,
        bufnum: buf,
        rate: BufRateScale.ir(buf) * rate,
        trigger: 1,
        startPos: spos,
        loop: loop,
    );

    sig = Pan2.ar(sig, pan);
    Out.ar(out, LeakDC.ar(sig) * env * amp);
}).add;

/*
ASR-enveloped buffer playback synth for stereo buffers.
*/
SynthDef(\pb2, {
    //controls
    var out = \out.ir(0);                           // output bus
    var amp = \amp.kr(1);                           // synth output amplitude
    var pan = \pan.kr(0);                           // synth pan position
    var buf = \buf.ir(0);                           // buffer containing the audio to play
    var rate = \rate.ir(1);                         // buffer playback rate factor
    var spos = \spos.ir(0);                         // play start position in the buffer
    var loop = \loop.kr(1);                         // 0 to not loop, 1 to loop the buffer
    var atk = \atk.kr(0.01);                        // envelope attack time
    var sus = \sus.kr(1);                           // envelope sustain level
    var rel = \rel.kr(0.1);                         // envelope release time
    var curve = \curve.kr(1);                       // envelope segment curvature
    var gate = \gate.kr(1);                         // envelope gate

    var env = Env.asr(
        attackTime: atk,
        sustainLevel: sus,
        releaseTime: rel,
        curve: curve
    ).kr(doneAction: 2, gate: gate);

    var sig = PlayBuf.ar(
        numChannels: 2,
        bufnum: buf,
        rate: BufRateScale.ir(buf) * rate,
        trigger: 1,
        startPos: spos,
        loop: loop,
    );

    sig = Balance2.ar(sig[0], sig[1], pan);
    Out.ar(out, LeakDC.ar(sig) * env * amp);
}).add;

/*
Nasty old Shroeder reverb adapted from James McCartney. Uses ReplaceOut (the output is fully wet).
*/
SynthDef(\schroederReverb, {
    //controls
    |in|                                            // input/output bus
    var hpf = \hpf.kr(50);                          // high pass filter cutoff frequency for the output
    var lpf = \lpf.kr(6000);                        // low pass filter cutoff frequency for the output
    var lpf1 = \lpf1.kr(2000);                      // low pass filter cutoff frequency for the Comb array
    var decay = \decay.kr(0.5);                     // reverberation decay time
    var predelay = \predelay.kr(0.05);              // reverb pre-delay

    var sig = DelayN.ar(In.ar(in, 2), predelay);
    sig = LPF.ar(Mix.ar(Array.fill(6, { CombL.ar(sig, 0.1, LFNoise1.kr(0.1.rand, 0.04, 0.05), decay) })), lpf1) / 6;
    4.do({ sig = AllpassN.ar(sig, 0.050, [0.050.rand, 0.050.rand], decay) });
    ReplaceOut.ar(in, LeakDC.ar(HPF.ar(LPF.ar(sig, lpf), hpf)));
}).add;

/*
Main output limiter using ReplaceOut, adapted from Batlib StageLimiter
*/
SynthDef(\finalLimiter, {
    //controls
    var out = \out.ir(0);                           // input/output bus

    var sig = In.ar(out, 2);
    sig = Select.ar(CheckBadValues.ar(sig, 0, 0), [sig, DC.ar(0), DC.ar(0), sig]);
    ReplaceOut.ar(out, Limiter.ar(LeakDC.ar(sig))) ;
}).add;
)

