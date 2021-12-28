# Generative strategy
Strategy creates simple figures at a slow tempo from a randomized pattern. The figures are finite, playing either 1 or 2 times and then stopping. 

At random intervals between 1 and 8 seconds a new figure is generated. After a configured maximum number of figures exist, any new one replaces the oldest existing one. If the figure being replaced is still playing, it is cross-faded to its replacement. 

The maximum number of figures is set to 8 by default, but can be changed in the first line of code. 

Figures are generated using notes selected from the leading whole tone scale, root at E♭, and those settings can be customized in the second line of code.

The GUI is a simple Play/Stop button. If Stop is pressed, the text changes to Stopping and the control is disabled while resources are being cleaned up before it changes back to Play and is enabled again.

There's no Record button on this one; use the IDE's UI for the server recording if desired.
