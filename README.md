Makey Makey Monome
==============

Original Project:
Jenna deBoisblanc<br>
2014<br>
[jdeboi.com](http://jdeboi.com/makey-makey-monome/)

Updated Project:<br>
David Cool<br>
http://davidcool.com<br>
http://generactive.net<br>
http://mystic.codes<br>
December 2015<br>

Processing Updates:
- Fixed recording feature so it works with Processing sketch & monome interaction
- Fixed bug where first monome button press wouldn't register
- Fixed bug where serial selection list would have double entries
- Changed button colors on screen and changed to matching colors on monome

TODO:
- Would love to add toggle for multiple 8 instrument screens so you could layer samples

Arduino Updates:
- Added rainbow loop when no serial data is detected
- Changed initialization to R / G / B color wipe
- Added a button reset to loop (fixes buttons left on when exiting processing)

TODO:
- Figure out big lag when "waking" from rainbow loop when serial is detected (use interrupts?)

**Objective**: Build an uber kid-friendly monome (a complex electronic music instrument).
<hr>

**Arduino Uno**: code (simple and complete) for Arduinos that uses capacitive sensing to determine if monome keys are pressed.

**MaKey MaKey**: code (simple and complete) for the MaKey MaKey to build a touchscreen monome.

**Processing**: code that takes serial data sent from the Arduino/MaKey MaKey and creates a visualization of the monome as well as generates music.