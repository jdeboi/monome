/*
 * Makey Makey Monome 
 *
 * Original Sketch:
 * Jenna deBoisblanc
 * http://jdeboi.com
 * October 2014
 *
 * Updated Sketch:
 * David Cool
 * http://davidcool.com
 * http://generactive.net
 * http://mystic.codes
 * December 2015

	* Updates:
	- Fixed recording feature so it work on screen & with monome
	- Fixed bug where first monome button press wouldn't register
	- Fixed bug where serial selection list would have double entries
	- Changed button colors on screen and changed to matching colors on monome
	

  Overview: this sketch sends and receives serial data to the 
  MaKey MaKey Monome to control sounds and LEDs. This Processing
  sketch is also standalone, so you can mix sounds without the
  instrument.
 
  Instructions:
  Pressing the numbers 0-9 on your keyboard toggles between 10 
  different recording files. Switch to different files to play, 
  record, or take snapshots.
  
  Keyboard shortcuts:
  'c' - clears the monome
  'r' - starts recording and keeps a timestamp of when you click or
        touch a button. When you hit the play button, the monome
        will replay the sequence of buttons based on the time at
        which you hit them.
  's' - a snapshot is different from a recording in that it only
        captures the state of the monome when you hit the snapshot
        button (i.e. can replay a sequence of button toggles)
  'p' - plays a recording
  
   To add new sounds:
   Simply replace the files in the 'audio' folder with any .wav files
   labeled 0.wav through 7.wav. Included in the audio folder are
   subfolders with a variety of different sounds. Copy paste those 
   into the audio or find your own unique .wav files.
  
   To save recording files:
   Simply move the files in the recording directory to a new 
   folder, and keep recording new .txt files. 
*/


////////////////////////////////////////
//VARIABLES & LIBRARIES///////////////////////
/////////////////////////////////////////////////////

///////////////////////////////
// EDIT THESE NUMBERS TO CHANGE
// THE NUMBER OF BUTTONS ON THE
// MONOME. MAKE SURE TO INCLUDE
// SOUNDFILES IN loadSounds()
int numRows = 8;
int numCols = 8;
///////////////////////////////

// variables to keep track of buttons
final int REC = 0;
final int SNAP = 1;
final int PLAY = 2;
final int CLR = 3;

// Serial for communicating with Arduino
import processing.serial.*;
Serial myPort;  // Create object from Serial class
int val;      // Data received from the serial port
int useSerial = -1;

// Sound 
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;
Minim minim;
AudioSample[] sounds;

// buttons
int numButtons = numRows*numCols;
Button[] buttons;
int numMenuButtons = 4;
MenuButton[] menuButtons;
int menuX = 100;
int menuY = 40;
int menuW=50;
int menuH=50;
int spacing = 10;

// window and monome dimensions
int windowWidth = 700;
int windowHeight = 700;
int monomeWidth= 500;
int monomeHeight= monomeWidth;
int padding = 10;
int columnSpacing = 8;
int rowSpacing = 8;
int buttonWidth = (monomeWidth-2*padding-columnSpacing*(numCols+1))/numCols;
int buttonHeight = (monomeHeight - rowSpacing*(numRows+1)-2*padding)/numRows;
int monomeX = (windowWidth - monomeWidth)/2;
int monomeY = (windowHeight - monomeHeight)/2;

// sequence variables
int timeStamp;
int tempo = 120;
int column = 0;

// saving variables
int[] timeTriggered = new int[0];
int[] buttonTriggered = new int[0];
boolean record = false;
int startTime = 0;
String[] file;
int index = 0;
boolean playing = false;
int playStartTime = 0;
int fileIndex = 1;

// tempo slide bar
Slider slider;
int maxTempo = 400;
int minTempo = 60;
int sliderX = 400;
int sliderY = 75;
int sliderW = monomeX + monomeWidth - sliderX;
int sliderH = 15;

int count = 0;

////////////////////////////////////////
//SETUP///////////////////////////////////////
/////////////////////////////////////////////////////
void setup() {
  size(700, 700, P3D);
  //fullScreen(P3D);
  buttons = new Button[numButtons];
  menuButtons = new MenuButton[numMenuButtons];
  slider = new Slider(sliderX, sliderY, sliderW, sliderH, minTempo, maxTempo, tempo);
 
 // initialize functions 
 loadSounds();
 loadMenuButtons();
 createButtons();

 // load a file
 file = loadStrings("files/file"+ fileIndex + ".txt");
 
}

////////////////////////////////////////
//DRAWING/////////////////////////////////////
/////////////////////////////////////////////////////
void draw() {
  background(255);
  
  if ( useSerial < 0){
    getSerialPort();
    //println(useSerial);
    return;
  }
  
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
  drawTempo();
}

void drawButtons() {
  for(int i=0; i<numButtons; i++) {
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
  textSize(12);
  text("FILE " + fileIndex, sliderX, sliderY-30);
}

void drawTempo() {
  fill(0);
  textSize(12);
  text("TEMPO " + tempo, sliderX, sliderY-10);
}
  
  
////////////////////////////////////////
//SEQUENCER///////////////////////////////////
/////////////////////////////////////////////////////  
void sequence()  {
  if(millis() - timeStamp > getDelay()) {
    highlight();
    // let the Arduino know which column to highlight
    if( useSerial > 0 ) myPort.write(column + 130);
    column++;
    if(column==numCols) column = 0;
    timeStamp = millis();
  }
}

void highlight() {
  for(int i=0; i<numRows; i++) {
    buttons[column+i*numCols].highlight();
    if(column == 0) {
       buttons[(numRows-1)+i*numCols].unHighlight();
    }
    else buttons[column-1+i*numCols].unHighlight();
  }
}  
 
 
////////////////////////////////////////
//UPDATING////////////////////////////////////
/////////////////////////////////////////////////////         
void resetMonome() {
  for (int i=0; i< numButtons; i++) {
   buttons[i].switchOff();
   sendToMonome(i);
  }
} 

void updateButtons() {
  if ( useSerial > 0 && myPort.available() > 0) {  // If data is available
    if (count == 0) {
    	count++;
    }

    val = myPort.read();         // read it and store it in val
    /* 
    We add 1 to the button index value on the Arduino
    so that we can differentiate from a null serial transmission
    We add numButtons to the index to indicate that the button is turning off
     */
      if (val > numButtons) {
      	buttons[val-(numButtons+1)].switchOff();
      	recordButton(val-(numButtons+1));
      	// send on/off info to console
      	println("off");
      	println("val: " + val);
      	println();
      }
      else if (val > 0) {
      	buttons[val-1].switchOn();
      	recordButton(val-1);
      	// send on/off info to console
      	println("on");
      	println("val: " + (val));
      	println();
      }
  }
}

void checkButtonClick() {
  for(int i=0; i<numButtons; i++) {
    if(buttons[i].contains()) { 
      buttons[i].switchState();
      recordButton(i);
      sendToMonome(i);
      //send on/off info to console
      if (buttons[i].state) {
      	println("on");
      	println("val: " + (i + 1));
      } else {
      	println("off");
      	println("val: " + ((i + 1) + numButtons));
      }
      println();
    }
  }
}

int getDelay() {
  return int(60*1000.0/tempo);
}

////////////////////////////////////////
//RECORDING///////////////////////////////////
/////////////////////////////////////////////////////
/* 
   a funciton that keeps track of what buttons are pushed
   and when they're pushed so that you can replay - in time -
   the same sounds at the corresponding time
*/ 
void startRecording() {
  record = true;
  startTime = millis();
  clearRecordingArrays();
  // save the tempo
  timeTriggered = append(timeTriggered, startTime);
  buttonTriggered = append(buttonTriggered, tempo);
  for (int i=0; i < numButtons; i++) {
    if (buttons[i].state) recordButton(i+1);
  }
}

void recordButton(int button) {
  if(record) {
    int val;
    if (buttons[button].state) val = button+1;
    else val = button + numButtons+1;
    timeTriggered = append(timeTriggered, millis() - startTime);
    println("time: " + (millis() - startTime));
    buttonTriggered = append(buttonTriggered, val);
    //println("button: " + val);
  }  
}

void stopRecording() {
  record=false;
  menuButtons[0].switchOff();
}

void clearRecordingArrays() {
  timeTriggered = new int[0];
  buttonTriggered = new int[0];
}

void takeSnapshot() {
  record = true;
  startTime = millis();
  clearRecordingArrays();
  // save the tempo
  timeTriggered = append(timeTriggered, startTime);
  buttonTriggered = append(buttonTriggered, tempo);
  for (int i=0; i < numButtons; i++) {
    if (buttons[i].state) recordButton(i);
  }
  record = false;
  saveRecording();
}

// this function saves the recording arrays to a file
void saveRecording() {
  String[] lines = new String[timeTriggered.length];
  for (int i = 0; i < timeTriggered.length; i++) {
    lines[i] = timeTriggered[i] + "\t" + buttonTriggered[i];
    println(lines[i]);
  }
  String fileName = "files/file" + fileIndex + ".txt";
  saveStrings(fileName, lines);
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
  String fileName = "files/file" + fileIndex + ".txt";
  if(fileExists(fileName)) file = loadStrings(fileName);
  else stopPlaying();
}

void checkPlaying() {
  if (index == 0) {
    if(file.length>0) {
      String[] buttonEvent = split(file[0], '\t');
      tempo = int(buttonEvent[1]);
      index++;
    }
    else {
      stopPlaying();
    }
  }
  else if (index < file.length) {
    String[] buttonEvent = split(file[index], '\t');
    if (millis() - playStartTime > int(buttonEvent[0])) {
      int value = int(buttonEvent[1]);
      if (value > numButtons) {
        buttons[value-(numButtons+1)].switchOff();
        sendToMonome(value-(numButtons+1));
      }
      else if (value > 0) {
        buttons[value-1].switchOn();
        sendToMonome(value-1);
      }
      
      
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
      triggerMenuButton(i);
    }
  }
}

void triggerMenuButton(int n) {
  // record
  if (n==REC) {
    if(menuButtons[REC].state) startRecording();
    else {
      stopRecording();
      saveRecording();
    }
  }
  // snapshot
  else if (n==SNAP) {
    // if we were recording, just take a recording not a snapshot
    if (record) {
      stopRecording();
      saveRecording();
    }
    else takeSnapshot();
  }
  // play
  else if (n==PLAY) {
    if(menuButtons[PLAY].state) startPlaying();
    else stopPlaying();
  }
  // clear
  else if (n==CLR) {
    stopPlaying();
    stopRecording();
    resetMonome();
    //if( useSerial > 0 ) myPort.write(129);
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
    tempo = slider.getSliderVal();
  }
}

void mouseReleased() {
  checkButtonClick();
  checkMenuButtonClick();
  slider.draggable = false;
}

void keyPressed() {
  if (keyCode == UP) {
    tempo++;
    if (tempo>maxTempo) tempo=maxTempo;
    slider.setSliderVal(tempo);
  }
  else if (keyCode == DOWN) {
    tempo--;
    if (tempo<minTempo) tempo=minTempo;
    slider.setSliderVal(tempo);
  }
  else if (key == 'c') {
    triggerMenuButton(CLR);
  }
  else if (key == 'r') {
    menuButtons[REC].switchState();
    triggerMenuButton(REC);
  }
  else if (key == 's') {
    triggerMenuButton(SNAP);
  }
  else if (key == 'p') {
    menuButtons[PLAY].switchState();
    triggerMenuButton(PLAY);
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

// shout-out to Cole Wiley- I fudged the pull request cuz I'm a
// GitHub newb
void getSerialPort(){
  String[] ports = Serial.list();
  int i;
  int x = 20;
  int y0 = 50;
  fill(0);
  text("Select serial port:", x, 30);
  Button[] setupButtons = new Button[(ports.length/2)+1];
  for(i = 0; i < (ports.length/2); i++){
    setupButtons[i] = new Button(i, x, 30*i+y0, 20, 20);
    fill(0);
    text(ports[i], x+30, 30*i+y0+15);
  }
  setupButtons[i] = new Button(i, x, 30*i+y0, 20, 20);
  fill(0);
  text("No serial", x+30, 30*i+y0+15);
  delay(10);
  for(Button button:setupButtons) {
    if(button.contains()){
      button.state = true;
      button.highlight = true;
      if(mousePressed) {
        if( button.n == (ports.length/2) ){
          useSerial = 0;
          return;
        } else {
          useSerial = button.n;
          myPort = new Serial(this, ports[button.n], 57600);
          return;
        }
      }
    }
    else{
      button.state = false;
      button.highlight = false;
    }
    button.drawButton();
  }
  return;
}


void loadSounds() {
   // see minim Processing example files for explanations
  minim = new Minim(this);
  sounds = new AudioSample[numRows];
  // load sounds - filename, buffer size
  //print("Loading sounds: ");
  for(int i=0; i<numRows; i++) {
    //print(i + " ");
    String f = "audio/" + i + ".wav";
    sounds[i] = minim.loadSample(f, 512);
  }
  //println();
}

void createButtons() {
  for(int i=0; i<numButtons; i++) {
    buttons[i] = new Button (i, monomeX+padding+columnSpacing+columnSpacing*(i%numCols)+buttonWidth*(i%numCols),
    monomeY+padding+rowSpacing+rowSpacing*(i/numRows)+buttonWidth*(i/numRows), buttonWidth, buttonHeight);
  }
}

void loadMenuButtons() {
  // record
  menuButtons[0] = new MenuButton(0, menuX, menuY, menuW, menuH, "RECORD", "icons/record0.png", "icons/record1.png");
  // snapshot
  menuButtons[1] = new MenuButton(1, menuX+menuW+spacing, menuY, menuW, menuH, "SNAPSHOT", "icons/camera.png", "icons/camera.png");
  // play
  menuButtons[2] = new MenuButton(2, menuX+2*(menuW+spacing), menuY, menuW, menuH, "PLAY", "icons/play.png", "icons/pause.png");
  // clear
  menuButtons[3] = new MenuButton(3, menuX+3*(menuW+spacing), menuY, menuW, menuH,"CLEAR", "icons/reset.png", "icons/reset.png");
}


void sendToMonome(int b) {
  if( useSerial > 0 ) {
    if(buttons[b].state) myPort.write(b+1);
    else myPort.write(b+numButtons+1); 
  }
}