# Generative strategy
FM chimes repeat a note while fading, notes chosen at random from a chord in 3 octaves that works out to be something like B♭maj7add9/D more or less. Begins deterministically with B♭ when *Play* is pressed, and continues randomly until *Stop* is pressed.

New notes join in at random but quantized times, with a maximum of 5 at a time. Each chime repeats in an interval of either 3, 4 or 5 beats and repeats 9 times while fading the volume, velocity, attack and modulation indices. 

Each chime also includes a bank of resonant filters in lieu of reverb. The way I did it was probably pretty wasteful of CPU, but I wanted the parameters of the filter bank to also decay as the repeats fade away. The frequency characteristics of the filters remain constant, but the gain and ring time decay.