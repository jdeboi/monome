(complete) Makey Makey Monome
==============

Jenna deBoisblanc<br>
2014<br>
[jdeboi.com](http://jdeboi.com/makey-makey-monome/)

**Overview:** All the files you need to build an RBG LED backlit touchscreen MaKey MaKey Monome that interfaces with Processing - an elegant, complex visual programming language.
<hr>

**Arduino**: makey_makey_monome.ino is code that sends serial data to the Processing sketch to generate sound and turn buttons on/off.

1. Install the [Arduino IDE](http://arduino.cc/en/Main/Software) if you haven't already.
2. Install the [Sparkfun MaKey MaKey addon](https://learn.sparkfun.com/tutorials/makey-makey-advanced-guide/installing-the-arduino-addon) in order to upload Arduino code to the MaKey MaKey board.

**Processing**: Look for the Processing folder in the root directory of the GitHub repository. The file, monome.pde, is a monome visualizer sketch that interacts with the MaKey MaKey Monome via serial communication. This sketch generates sound, plays/records up to 10 recordings (saved in the "recording" directory), adjusts the speed of the sequencer with the slider, and much more.  

1. Install [Processing](https://www.processing.org/download/) if you haven't already.
2. Run monome.pde in Processing.
