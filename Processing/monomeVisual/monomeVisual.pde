/*
 * Makey Makey Monome
 *
 * Jenna deBoisblanc
 * jdeboi.com
 * January 2014
 *
 */

import processing.serial.*;
Serial myPort;  // Create object from Serial class
int val;      // Data received from the serial port
 
import ddf.minim.*;
Minim minim;
AudioSample[] sounds;

int numRow = 8;
int numCol = 8;
int numButtons = numRow * numCol; 

int timeStamp;
int speed = 800;
int column = 0;

int triggerThresh = 200;

int[] rowTime;
int[] columnTime;
char[] rowLetters = {'a', 's', 'd', 'f', 'g', 'h', 'j', 'k'};

Button[] buttons;

int windowWidth = 700;
int windowHeight = 700;
int monomeWidth= 600;
int monomeHeight= monomeWidth;
int padding = 10;
int columnSpacing = 8;
int rowSpacing = 8;
int buttonWidth = (monomeWidth-2*padding-columnSpacing*9)/8;

int buttonHeight = (monomeHeight - rowSpacing*9-2*padding)/8;
int monomeX = (windowWidth - monomeWidth)/2;
int monomeY = (windowHeight - monomeHeight)/2;

// arrays for recording monome
int[] timeTriggered = new int[0];
int[] buttonTriggered = new int[0];
boolean record = false;
int startTime = 0;
String[] recording;
int index = 0;

void setup() {
  size(windowWidth, windowHeight, P3D);
  rowTime = new int[8];
  columnTime = new int[8];
  buttons = new Button[numButtons];
  
  // List all the available serial ports
  println(Serial.list());
  String portName = Serial.list()[0];
  myPort = new Serial(this, portName, 9600);
  
 loadSounds();
 createButtons();
 
 // load previous recording
 recording = loadStrings("recording.txt");

 
}

void draw() {
  background(255);
  updateButtons();
  drawMonome();
  sequence();
}

void updateButtons() {
  if ( myPort.available() > 0) {  // If data is available,
    val = myPort.read();         // read it and store it in val
    /* we add 1 to the button index value on the Arduino
    so that we can differentiate from a null serial transmission
     We add 64 to the index to indicate that the button is turning off
     */
    if (val > 64) buttons[val-65].switchOff();
    else if (val > 0) buttons[val-1].switchOn();
    recordButton(val);
  }
}

void sequence()  {
  if(millis() - timeStamp > speed) {
    highlight();
    column++;
    if(column==8) column = 0;
    timeStamp = millis();
  }
}

void highlight() {
  for(int i=0; i<8; i++) {
    buttons[column+i*8].highlight();
    if(column == 0) {
       buttons[7+i*8].unHighlight();
    }
    else buttons[column-1+i*8].unHighlight();
  }
}

void drawMonome() {
  //padding
  fill(#434343);
  rect(monomeX, monomeY, monomeWidth, monomeHeight);
  
  //middle
  fill(200);
  rect(monomeX+padding, monomeY+padding,monomeWidth-2*padding, monomeHeight-2*padding);
  
  for(int i=0; i<64; i++) {
    buttons[i].drawButton();
  }
}



void resetRow(int rowNum) {
  for(int i=(rowNum*8); i<(rowNum*8+8); i++) {
    buttons[i].pressed = false;
  }
}
          

void keyPressed() {
  if (keyCode == UP) {
    speed-=20;
    if (speed<0) speed=0;
  }
  else if (keyCode == DOWN) {
    speed+=20;
    if (speed>2000) speed=2000;
  }
  else if (key == 'c') {
    resetMonome();
  }
  else if (key == 'r') {
    startRecording();
  }
  else if (key == 's') {
    record=false;
    saveRecording();
  }
}



  
void mouseReleased() {
  for(int i=0; i<numButtons; i++) {
    if(buttons[i].contains()) { 
      buttons[i].switchState();
      if(buttons[i].state) recordButton(i+1);
      else recordButton(i+65); 
    }
  }
}

void loadSounds() {
   // see minim Processing example files for explanations
  minim = new Minim(this);
  // load sounds - filename, buffer size
  sounds = new AudioSample[8];
  sounds[0] = minim.loadSample("audio/0.wav", 512); // clap
  sounds[1] = minim.loadSample("audio/1.wav", 512); // hihatcl
  sounds[2] = minim.loadSample("audio/2.wav", 512); // hihatopen
  sounds[3] = minim.loadSample("audio/3.wav", 512); // kick
  sounds[4] = minim.loadSample("audio/4.wav", 512); // snare
  sounds[5] = minim.loadSample("audio/5.wav", 512); // starkick
  sounds[6] = minim.loadSample("audio/6.wav", 512); // tomhi
  sounds[7] = minim.loadSample("audio/7.wav", 512); // tomlow
}

void createButtons() {
  for(int i=0; i<64; i++) {
    buttons[i] = new Button (i, monomeX+padding+columnSpacing+columnSpacing*(i%8)+buttonWidth*(i%8),
    monomeY+padding+rowSpacing+rowSpacing*(i/8)+buttonWidth*(i/8), buttonWidth, buttonHeight);
  }
}
    
void resetMonome() {
  for (int i=0; i< numButtons; i++) {
   buttons[i].switchOff();
  }
} 

void startRecording() {
  record = true;
  startTime = millis();
  for (int i=0; i < numButtons; i++) {
    if (buttons[i].state) recordButton(i+1);
  }
}

void recordButton(int button) {
  if(record) {
    timeTriggered = append(timeTriggered, millis() - startTime);
    buttonTriggered = append(buttonTriggered, button);
  }  
}

void saveRecording() {
  String[] lines = new String[timeTriggered.length];
  for (int i = 0; i < timeTriggered.length; i++) {
    lines[i] = timeTriggered[i] + "\t" + buttonTriggered[i];
  }
  saveStrings("recording.txt", lines);
}

void playRecording() {
if (index < lines.length) {
    String[] pieces = split(lines[index], '\t');
    if (pieces.length == 2) {
      int x = int(pieces[0]) * 2;
      int y = int(pieces[1]) * 2;
      point(x, y);
    }
    // Go to the next line for the next run through draw()
    index = index + 1;
  }
}

