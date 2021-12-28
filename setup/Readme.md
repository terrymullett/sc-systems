## SynthDef controls

I use some standards to help make swapping SynthDefs out easier.

Low pass filter on the output:
* lpf: cutoff frequency
* lpfRate: rate to modulate cutoff frequency
* lpfDepth: amount to modulate cutoff frequency
* lpfRq: rq of the filter if UGen supports
* lpfRqRate: rate to modulate rq, if Ugn supports rq

Mid EQ on the output:
* midEQ: center frequency for the Mid EQ
* midEQrq: rq for the Mid EQ
* midEQdb: gain/attenuation in db of the Mid EQ

Low Shelf on the output:
* ls: cutoff frequnecy for low shelf
* lsdb: gain/attenuation for low shelf
* lsrs: reciprocal slope for low shelf

