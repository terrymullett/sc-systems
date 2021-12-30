/*
"Oh, to" v3 Dec 2021
*/
"../setup/Setup.scd".loadRelative;

(
e.wt = Buffer.allocConsecutive(3, s, 8192);
["AKWF_0001", "AKWF_0006", "AKWF_0115"].do {
    |which, i|
    e.wt[i].read(thisProcess.nowExecutingPath.dirname +/+ "../wt/" +/+ which ++ ".wav.wtable");
};
)

~lfo0 = { LFBrownNoise2.kr(1!2).range(e.wt[0].bufnum, e.wt[2].bufnum) };
~lfo1 = { SinOsc.kr(0.1).range(600, 800) };
~lfo2 = { SinOsc.kr(0.3).range(0.5, 1.5) };
~lfo3 = { LFNoise2.kr(0.5).bipolar(0.3) };

~a.play;
~a.vol_(1);

(
~a[0] = \mix -> { VOsc.ar(bufpos: ~lfo0, freq: \freq.kr(32.midicps + [-12.5, 12.5])).tanh };
~a.set(\mix0, -12.dbamp);
// ~a.set(\mix0, 0);

~a[1] = \mix -> { PinkNoise.ar!2 };
~a.set(\mix1, -12.dbamp);
// ~a.set(\mix1, 0);

~a[2] = \mix -> {
    Pan2.ar(
        in: PlayBuf.ar(
            numChannels: 1,
            bufnum: e.bf['oxygen-concentrator'].bufnum,
            rate: BufRateScale.ir(e.bf['oxygen-concentrator']),
            loop: 1,
        ),
        pos: ~lfo3,
        level: ~lfo2
    );
};
~a.set(\mix2, -3.dbamp);
// ~a.set(\mix2, 0);

~a[100] = \filterIn -> { |in| LeakDC.ar(BPF.ar(in: in, freq: ~lfo1, rq: ~lfo2)) };
~a.set(\wet100, 0.85);

~a[200] = \filterIn -> {
    |in|
    LeakDC.ar(
        LPF.ar(
            in: Klank.ar(`[
                Array.geom(4, 83.853989, pi),
                Array.fill(4, {|i| 0.95.pow(8 * (i + 1))}) * 0.1,
                Array.geom(4, 0.125, 0.5),
            ], in),
            freq: 2600
        )
    )
};
~a.set(\wet200, 0.55);
)

~a.gui
