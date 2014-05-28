/**
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

int windowWidth = 600;
int windowHeight = 600;
int monomeWidth= 460;
int monomeHeight= monomeWidth;
int padding = 10;
int columnSpacing = 8;
int rowSpacing = 8;
int buttonWidth = (monomeWidth-2*padding-columnSpacing*9)/8;

int buttonHeight = (monomeHeight - rowSpacing*9-2*padding)/8;
int monomeX = (windowWidth - monomeWidth)/2;
int monomeY = (windowHeight - monomeHeight)/2;



void setup() {
  size(windowWidth, windowHeight, P3D);
  rowTime = new int[numRow];
  columnTime = new int[numCol];
  buttons = new Button[numButtons];
  
  // List all the available serial ports
  println(Serial.list());
  String portName = Serial.list()[0];
  myPort = new Serial(this, portName, 9600);
  
 loadSounds();

  for(int i=0; i<64; i++) {
    buttons[i] = new Button (i, monomeX+padding+columnSpacing+columnSpacing*(i%8)+buttonWidth*(i%8),
    monomeY+padding+rowSpacing+rowSpacing*(i/8)+buttonWidth*(i/8), buttonWidth, buttonHeight);
  }
  for(int i=0; i<8; i++) {
    rowTime[i] = millis();
    columnTime[i] = millis();
  }
}

void draw() {
  background(255);
  checkButtons();
  drawMonome();
  sequence();
}

void checkButtons() {
  if ( myPort.available() > 0) {  // If data is available,
    val = myPort.read();         // read it and store it in val
  }
  /* we add 1 to the button index value on the Arduino
   so that we can differentiate from a null serial transmission
   We add 64 to the index to indicate that the button is turning off
   */
  if (val > 64) buttons[val-65].switchOff();
  else if (val > 0) buttons[val-1].switchOn();
}

void updateMonome() {
  for(int i=0; i<numRow; i++) {
    if(millis() - rowTime[i] < triggerThresh){
      for(int j=0; j<numCol; j++) {
        if(millis() - columnTime[j] < triggerThresh) {
          checkButton(i*numRow + j);
        }
        else {
          buttons[i*numRow+j].pressed = false;
        }
      }
    }
    else {
      resetRow(i);
    }
  }
}

void sequence()  {
  if(millis() - timeStamp > speed) {
    highlight();
    column++;
    if(column==numCol) column = 0;
    timeStamp = millis();
  }
}

void highlight() {
  for(int i=0; i<8; i++) {
    buttons[column+i*numRow].highlight();
    if(column == 0) {
       buttons[7+i*numRow].unHighlight();
    }
    else buttons[column-1+i*numRow].unHighlight();
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


void checkButton(int button) {
  if (!buttons[button].pressed) {
    buttons[button].switchState();
    buttons[button].pressed = true;
  }
}

void resetRow(int rowNum) {
  for(int i=(rowNum*numRow); i<(rowNum*numRow+numRow); i++) {
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
  else if (key == 'r') {
    resetMonome();
  }
  else {
    for(int i=0; i<8; i++) {
      if (key == rowLetters[i]) {
        rowTime[i] = millis();
      }
      else if ((key-49) == i) {
        columnTime[i] = millis();
      }
    }
    updateMonome();
  }
}



  
void mouseReleased() {
  for(int i=0; i<numButtons; i++) {
    if(buttons[i].contains()) buttons[i].switchState();
  }
  updateMonome();
}

void loadSounds() {
   // see minim Processing example files for explanations
  minim = new Minim(this);
  // load sounds - filename, buffer size
  sounds = new AudioSample[numRow];
  sounds[0] = minim.loadSample("audio/clap.wav", 512);
  sounds[1] = minim.loadSample("audio/hihatcl.wav", 512);
  sounds[2] = minim.loadSample("audio/hihatopen.wav", 512);
  sounds[3] = minim.loadSample("audio/kick.wav", 512);
  sounds[4] = minim.loadSample("audio/snare.wav", 512);
  sounds[5] = minim.loadSample("audio/starkick.wav", 512);
  sounds[6] = minim.loadSample("audio/tomhi.wav", 512);
  sounds[7] = minim.loadSample("audio/tomlow.wav", 512);
}
    
void resetMonome() {
  for (int i=0; i< numButtons; i++) {
   buttons[i].switchOff();
  }
} 


