/*
 * Makey Makey Monome 
 *
 * Jenna deBoisblanc
 * http://jdeboi.com
 * June 2014
 *
 */


////////////////////////////////////////
//VARIABLES & LIBRARIES///////////////////////
/////////////////////////////////////////////////////
// Serial for communicating with Arduino
import processing.serial.*;
Serial myPort;  // Create object from Serial class
int val;      // Data received from the serial port

// Sound 
import ddf.minim.*;
Minim minim;
AudioSample[] sounds;

// buttons
int numButtons = 64;
Button[] buttons;
int numMenuButtons = 4;
MenuButton[] menuButtons;

// window and monome dimensions
int windowWidth = 700;
int windowHeight = 700;
int monomeWidth= 500;
int monomeHeight= monomeWidth;
int padding = 10;
int columnSpacing = 8;
int rowSpacing = 8;
int buttonWidth = (monomeWidth-2*padding-columnSpacing*9)/8;
int buttonHeight = (monomeHeight - rowSpacing*9-2*padding)/8;
int monomeX = (windowWidth - monomeWidth)/2;
int monomeY = (windowHeight - monomeHeight)/2;

// sequence variables
int timeStamp;
int speed = 800;
int column = 0;

// recording variables
int[] timeTriggered = new int[0];
int[] buttonTriggered = new int[0];
boolean record = false;
int startTime = 0;
String[] recording;
int index = 0;
boolean playing = false;
int playStartTime = 0;
int fileIndex = 0;
int fileLabelX = 400;
int fileLabelY = 55;

// speed slide bar
Slider slider;
int maxSpeedDelay = 1000;
int minSpeedDelay = 30;

////////////////////////////////////////
//SETUP///////////////////////////////////////
/////////////////////////////////////////////////////
void setup() {
  size(windowWidth, windowHeight, P3D);
  buttons = new Button[numButtons];
  menuButtons = new MenuButton[numMenuButtons];
  slider = new Slider(400, 65, 160, 15, minSpeedDelay, maxSpeedDelay, 800);
  
  // List all the available serial ports
  println(Serial.list());
  String portName = Serial.list()[0];
  myPort = new Serial(this, portName, 9600);
  
 loadSounds();
 loadMenuButtons();
 createButtons();
 
 // load previous recording
 recording = loadStrings("recordings/recording0.txt");
 
}

////////////////////////////////////////
//DRAWING/////////////////////////////////////
/////////////////////////////////////////////////////
void draw() {
  background(255);
  updateButtons();
  slider.drawSlider();
  drawFileNumber();
  if (playing) {
    checkPlaying();
  }
  drawMonome();
  sequence();
}

void drawMonome() {
  //padding
  fill(#434343);
  rect(monomeX, monomeY, monomeWidth, monomeHeight);
  
  //middle
  fill(200);
  rect(monomeX+padding, monomeY+padding,monomeWidth-2*padding, monomeHeight-2*padding);
  
  drawButtons();
  drawMenuButtons();
}

void drawButtons() {
  for(int i=0; i<64; i++) {
    buttons[i].drawButton();
  }  
}

void drawMenuButtons() {
  for(int i=0; i<numMenuButtons; i++) {
    menuButtons[i].drawButton();
  }
}

void drawFileNumber() {
  fill(#434343);
  //rect(x, y-20, 100, 20);
  fill(0);
  text("RECORDING "+fileIndex, fileLabelX, fileLabelY);
}
  
////////////////////////////////////////
//SEQUENCER///////////////////////////////////
/////////////////////////////////////////////////////  
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
 
 
////////////////////////////////////////
//UPDATING////////////////////////////////////
/////////////////////////////////////////////////////         
void resetMonome() {
  for (int i=0; i< numButtons; i++) {
   buttons[i].switchOff();
  }
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

void checkButtonClick() {
  for(int i=0; i<numButtons; i++) {
    if(buttons[i].contains()) { 
      buttons[i].switchState();
      if(buttons[i].state) recordButton(i+1);
      else recordButton(i+65); 
    }
  }
}


////////////////////////////////////////
//RECORDING///////////////////////////////////
/////////////////////////////////////////////////////
void startRecording() {
  record = true;
  startTime = millis();
  // clear the record arrays
  timeTriggered = new int[0];
  buttonTriggered = new int[0];
  // save the speed
  timeTriggered = append(timeTriggered, startTime);
  buttonTriggered = append(buttonTriggered, speed);
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

void stopRecording() {
  record=false;
  menuButtons[0].switchOff();
}


////////////////////////////////////////
//SAVING//////////////////////////////////////
/////////////////////////////////////////////////////
void saveRecording() {
  String[] lines = new String[timeTriggered.length];
  for (int i = 0; i < timeTriggered.length; i++) {
    lines[i] = timeTriggered[i] + "\t" + buttonTriggered[i];
  }
  String recordingFileName = "recordings/recording" + fileIndex + ".txt";
  saveStrings(recordingFileName, lines);
}


////////////////////////////////////////
//PLAYING/////////////////////////////////////
/////////////////////////////////////////////////////
void startPlaying() {
  resetMonome();
  stopRecording();
  menuButtons[2].switchOn();
  index = 0;
  playStartTime = millis();
  playing = true;
  String recordingFileName = "recordings/recording" + fileIndex + ".txt";
  if(fileExists(recordingFileName)) recording = loadStrings(recordingFileName);
  else stopPlaying();
}

void checkPlaying() {
  if (index == 0) {
    if(recording.length>0) {
      String[] buttonEvent = split(recording[0], '\t');
      speed = int(buttonEvent[1]);
      index++;
    }
    else {
      stopPlaying();
    }
  }
  else if (index < recording.length) {
    String[] buttonEvent = split(recording[index], '\t');
    if (millis() - playStartTime > int(buttonEvent[0])) {
      int value = int(buttonEvent[1]);
      if (value > 64) buttons[value-65].switchOff();
      else if (value > 0) buttons[value-1].switchOn();
      // Go to the next line for the next run through draw()
      index++;
    }
  }
  else stopPlaying();
}

void stopPlaying() {
  playing = false;
  menuButtons[2].switchOff();
}


////////////////////////////////////////
//MENU BUTTONS////////////////////////////////
/////////////////////////////////////////////////////
void checkMenuButtonClick() {
  for(int i=0; i<numMenuButtons; i++) {
    if(menuButtons[i].contains()) { 
      menuButtons[i].switchState();
      triggerMenuButton(i, menuButtons[i].state);
    }
  }
}

void triggerMenuButton(int n, boolean s) {
  // record
  if (n==0) {
    if(s) startRecording();
    else stopRecording();
  }
  // save
  else if (n==1) {
    stopRecording();
    saveRecording();
  }
  // play
  else if (n==2) {
    if(s) startPlaying();
    else stopPlaying();
  }
  // clear
  else if (n==3) {
    stopPlaying();
    stopRecording();
    resetMonome();
  }
  else {}
}

boolean fileExists(String filename) {
  File f = new File(sketchPath(filename));
  if(!f.exists()) return false;
  return true;
}


////////////////////////////////////////
//KEY & MOUSE/////////////////////////////////
/////////////////////////////////////////////////////
void mousePressed() {
  if(slider.contains()) slider.draggable = true;
}


void mouseDragged() {
  if (slider.draggable) {
    slider.updateSliderPosMouse();
    speed = slider.getSliderVal();
    println(speed);
  }
}

void mouseReleased() {
  checkButtonClick();
  checkMenuButtonClick();
  slider.draggable = false;
}

void keyPressed() {
  if (keyCode == UP) {
    speed-=20;
    if (speed<minSpeedDelay) speed=minSpeedDelay;
    slider.setSliderVal(speed);
  }
  else if (keyCode == DOWN) {
    speed+=20;
    if (speed>maxSpeedDelay) speed=maxSpeedDelay;
    slider.setSliderVal(speed);
  }
  else if (key == 'c') {
    resetMonome();
  }
  else if (key == 'r') {
    if(record) record=false;
    else startRecording();
  }
  else if (key == 's') {
    record=false;
    saveRecording();
  }
  else if (key == 'p') {
    if(playing) {
      playing = false;
      stopPlaying();
    }
    else startPlaying();
  }
  else if (key == '0') {
    fileIndex = 0;
  }
  else if (key == '1') {
    fileIndex = 1;
  }
  else if (key == '2') {
    fileIndex = 2;
  }
  else if (key == '3') {
    fileIndex = 3;
  }
  else if (key == '4') {
    fileIndex = 4;
  }
  else if (key == '5') {
    fileIndex = 5;
  }
  else if (key == '6') {
    fileIndex = 6;
  }
  else if (key == '7') {
    fileIndex = 7;
  }
  else if (key == '8') {
    fileIndex = 8;
  }
  else if (key == '9') {
    fileIndex = 9;
  }
}


////////////////////////////////////////
//INITIALIZING////////////////////////////////
/////////////////////////////////////////////////////
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

void loadMenuButtons() {
  int menuX = 100;
  int menuY = 40;
  int menuW=50;
  int menuH=50;
  int spacing = 10;
  // record
  menuButtons[0] = new MenuButton(0, menuX, menuY, menuW, menuH, "RECORD", "icons/record0.png", "icons/record1.png");
  // save
  menuButtons[1] = new MenuButton(1, menuX+menuW+spacing, menuY, menuW, menuH, "SAVE", "icons/save.png", "icons/save.png");
  // play
  menuButtons[2] = new MenuButton(2, menuX+2*(menuW+spacing), menuY, menuW, menuH, "PLAY", "icons/play.png", "icons/pause.png");
  // clear
  menuButtons[3] = new MenuButton(3, menuX+3*(menuW+spacing), menuY, menuW, menuH,"RESET", "icons/reset.png", "icons/reset.png");
}
