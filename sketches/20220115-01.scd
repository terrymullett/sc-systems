"../setup/Setup.scd".loadRelative;

(
p.fadeTime_(2);
p.quant_(0);

~tri = { LFTri.ar(0.1).range(0.03, 0.2) };
~sweep = { SinOsc.ar(0.3) * 0.75 };
~wobble = { SinOsc.ar(SinOsc.ar(1.exp).range(5000, 6100)) };
~wander = { SinOsc.ar(SinOsc.ar(2.sqrt)) };

~a.ar(2);
~a.play;

~a[100] = \filterIn -> { |in| CombL.ar(in) };

~a[200] =\filterIn -> {
    |in|
    LeakDC.ar(
        LPF.ar(
            in: Klank.ar(`[
                Array.geom(4, 125, 2.9),
                Array.fill(4, {|i| 0.9.pow(8 * (i + 1))}),
                Array.geom(4, 0.125, 0.5),
            ], in),
            freq: \lpf.kr(5000);
        )
    )
};
~a.map(\wet200, ~tri);
~a.map(\lpf, ~wobble);

~a[300] = \filterIn -> { |in| HPF.ar(in, 50) };
)

(
~a[0] = \mix -> {
    var sig = Decay.ar(Dust.ar(1, mul: 0.7) ! 2, 0.2, BrownNoise.ar).lag(LFNoise0.kr(0.2).range(0.001, 0.003));
    Balance2.ar(sig[0], sig[1], \pos.kr(0), 0.7);
};
~a.map(\pos, ~sweep);
)

(
~a[1] = \mix -> {
    Decay.ar(
        in: Impulse.ar(0.0625, mul: 0.5) ! 2,
        decayTime: 0.3,
        mul: WhiteNoise.ar).lag(0.001)
};
)

(
~a[2] = \mix -> {
    Decay.ar(
        in: CoinGate.ar(LFNoise1.kr(0.05).range(0.75, 0.95), Impulse.ar(10, mul: 0.7) ! 2),
        decayTime: 0.5,
        mul: PinkNoise.ar).lag(LFNoise0.kr(0.6).range(0.004, 0.008))
};
)

(
~a[3] = \mix -> {
    Pan2.ar(
        in: Decay.ar(
            in: CoinGate.ar(0.95, Impulse.ar(2pi)),
            decayTime: 1/2pi,
            mul: LFTri.ar(36.midicps, mul: 0.5)
        ).lag(0.003),
        pos: \pan.kr(0)) };
~a.map(\pan, ~wander);
)

ProxyMixer(p);

