/*
 ************************************************
 ********** MAKEY MAKEY PAPER MONOME ************
 ************************************************
 //MAKER////////////
 Jenna deBoisblanc
 http://jdeboi.com
 start date: January 2014
 Instructable:
 GitHub repo:
 
 //DESCRIPTION//////
 My objective for this project was to build a monome- http://monome.org/ -
 (basically a programmable array of backlit buttons that's used
 to compose electronic music or mix video) using tools and processes 
 that were so simple, a third grader could build it.
 
 The Makey Makey turns conductive objects- in my case, conductive paint patches- 
 into keyboard input. The board, however, only has less than 24 iniputs, and I wanted to 
 build an 8x8 monome = 64 buttons. My solution was to hook 8 alligator clips to columns, 
 8 to rows, and when the intersection of a row and column was pressed, a monome button
 changes states,
 
 I used Adafruit Neopixels- RGB LEDs that are individually addressible but only 
 need 1 digital out- arranged in an 8x8 zigzag matrix to light up the squares when 
 pressed.
 
 //CREDIT///////////
 Special thanks to Kevin Matulef for his Makey Makey and 
 Amanda Ghassaei, one of my best friends, for introducing
 me to monomes and the Maker Movement.
 
 Code adapted from:
 1. MaKey MaKey FIRMWARE v1.4.1
 by: Eric Rosenbaum, Jay Silver, and Jim Lindblom
 http://makeymakey.com
 2. Adafruit Neopixel library
 http://learn.adafruit.com/adafruit-neopixel-uberguide/neomatrix-library
 
 */

/////////////////////////
// DEBUG DEFINITIONS ////               
/////////////////////////
//#define DEBUG
//#define DEBUG2 
//#define DEBUG3 
//#define DEBUG_TIMING
#define SERIAL9600
#define DEBUG_MONOME

////////////////////////
// DEFINED CONSTANTS////
////////////////////////
#define BUFFER_LENGTH    3     // 3 bytes gives us 24 samples
#define NUM_ROWS         8
#define NUM_COLUMNS      8
#define NUM_INPUTS       NUM_ROWS+NUM_COLUMNS      // 8 rows, 8 columns
#define NUM_BUTTONS      NUM_ROWS * NUM_COLUMNS    // 64 buttons
#define TARGET_LOOP_TIME 744  // (1/56 seconds) / 24 samples = 744 microseconds per sample 

//#define SERIAL9600
#include "settings.h"

/////////////////////////
// MAKEY MAKEY STRUCT ///
/////////////////////////
typedef struct {
  byte pinNumber;
  int keyCode;
  int timePressed;
  byte measurementBuffer[BUFFER_LENGTH]; 
  boolean oldestMeasurement;
  byte bufferSum;
  boolean pressed;
  boolean prevPressed;
} 
MakeyMakeyInput;
MakeyMakeyInput inputs[NUM_INPUTS];

/////////////////////////
// BUTTON STRUCT ////////
/////////////////////////
typedef struct {
  boolean pressed;
  boolean state;
} 
Button;
Button buttons [NUM_BUTTONS];

/////////////////////////
// NEOPIXELS ////////////
/////////////////////////
// http://learn.adafruit.com/adafruit-neopixel-uberguide/neomatrix-library
// set the Neopixel pin to 18 - A0
#define NEO_PIN 0
#include <Adafruit_NeoPixel.h>
Adafruit_NeoPixel strip = Adafruit_NeoPixel(NUM_BUTTONS, NEO_PIN, NEO_GRB + NEO_KHZ800);
uint16_t ledColor = 255;  


///////////////////////////////////
// VARIABLES //////////////////////
///////////////////////////////////
int bufferIndex = 0;
byte byteCounter = 0;
byte bitCounter = 0;

int pressThreshold;
int releaseThreshold;
int triggerThresh = 200;
boolean inputChanged;


/*
  KEY MAPPINGS
  0-5, pin D0 to D5
  6 - click button pad 
  7 - space button pad
  8 - down arrow pad
  12 - up arrow pad
  13 - left arrow pad
  15 - right arrow pad
  18-23, pin A0 to A5
*/

int pinNumbers[NUM_INPUTS] = {        
  // Rows ///////////////////////// 
  8,     // down arrow pad
  15,    // right arrow pad
  7,     // space button pad 
  5,     // pin D5
  4,     // pin D4
  3,     // pin D3
  2,     // pin D2
  1,     // pin D1
  // Columns ///////////////////////
  12,     // up arrow pad
  13,     // left arrow pad
  18,     //A0
  19,     //A1
  20,     //A2
  21,     //A3
  22,     //A4
  23     //A5
};

/* 
// input status LED pin numbers
const int inputLED_a = 9;
const int inputLED_b = 10;
const int inputLED_c = 11;
*/

// LED that indicates when key is pressed
const int outputK = 16;
byte ledCycleCounter = 0;

// timing
int loopTime = 0;
int prevTime = 0;
int loopCounter = 0;


///////////////////////////
// FUNCTIONS //////////////
///////////////////////////
void initializeArduino();
void initializeInputs();
void initializeNeopixels();
void updateMeasurementBuffers();
void updateBufferSums();
void updateBufferIndex();
void updateInputStates();
void addDelay();
void updateOutLED();
void setNeopixel();

//////////////////////
// SETUP /////////////
//////////////////////
void setup() 
{
  initializeArduino();
  initializeInputs();
  initializeNeopixels();
  delay(100);
}

////////////////////
// MAIN LOOP ///////
////////////////////
void loop() 
{
  updateMeasurementBuffers();
  updateBufferSums();
  updateBufferIndex();
  updateInputStates();
  updateOutLED();
  addDelay();
}

//////////////////////////
// INITIALIZE ARDUINO
//////////////////////////
void initializeArduino() {
#ifdef SERIAL9600
  Serial.begin(9600);  
#endif
  /* Set up input pins 
   DEactivate the internal pull-ups, since we're using external resistors */
  for (int i=0; i<NUM_INPUTS; i++)
  {
    pinMode(pinNumbers[i], INPUT);
    digitalWrite(pinNumbers[i], LOW);
  }

  /* 
  // LEDs that we aren't using... 
  pinMode(inputLED_a, INPUT);
  pinMode(inputLED_b, INPUT);
  pinMode(inputLED_c, INPUT);
  digitalWrite(inputLED_a, LOW);
  digitalWrite(inputLED_b, LOW);
  digitalWrite(inputLED_c, LOW);
  */
  
  pinMode(outputK, OUTPUT);
  digitalWrite(outputK, LOW);


#ifdef DEBUG
  delay(4000); // allow us time to reprogram in case things are freaking out
#endif
}

///////////////////////////
// INITIALIZE INPUTS
///////////////////////////
void initializeInputs() {

  float thresholdPerc = SWITCH_THRESHOLD_OFFSET_PERC;
  float thresholdCenterBias = SWITCH_THRESHOLD_CENTER_BIAS/50.0;
  float pressThresholdAmount = (BUFFER_LENGTH * 8) * (thresholdPerc / 100.0);
  float thresholdCenter = ( (BUFFER_LENGTH * 8) / 2.0 ) * (thresholdCenterBias);
  pressThreshold = int(thresholdCenter + pressThresholdAmount);
  releaseThreshold = int(thresholdCenter - pressThresholdAmount);

#ifdef DEBUG
  Serial.println(pressThreshold);
  Serial.println(releaseThreshold);
#endif

  for (int i=0; i<NUM_INPUTS; i++) {
    inputs[i].pinNumber = pinNumbers[i];
    inputs[i].keyCode = keyCodes[i];

    for (int j=0; j<BUFFER_LENGTH; j++) {
      inputs[i].measurementBuffer[j] = 0;
    }
    inputs[i].oldestMeasurement = 0;
    inputs[i].bufferSum = 0;

    inputs[i].pressed = false;
    inputs[i].prevPressed = false;

#ifdef DEBUG
    Serial.println(i);
#endif

  }
}


///////////////////////////
// INITIALIZE Neopixels
///////////////////////////
void initializeNeopixels() {
  strip.begin();
  strip.show(); // Initialize all pixels to 'off'
  rainbow(20);
  clearNeopixels();
}



//////////////////////////////
// UPDATE MEASUREMENT BUFFERS
//////////////////////////////
void updateMeasurementBuffers() {

  for (int i=0; i<NUM_INPUTS; i++) {

    // store the oldest measurement, which is the one at the current index,
    // before we update it to the new one 
    // we use oldest measurement in updateBufferSums
    byte currentByte = inputs[i].measurementBuffer[byteCounter];
    inputs[i].oldestMeasurement = (currentByte >> bitCounter) & 0x01; 

    // make the new measurement
    boolean newMeasurement = digitalRead(inputs[i].pinNumber);

    // invert so that true means the switch is closed, i.e. touched
    newMeasurement = !newMeasurement; 

    // store it    
    if (newMeasurement) {
      currentByte |= (1<<bitCounter);
    } 
    else {
      currentByte &= ~(1<<bitCounter);
    }
    inputs[i].measurementBuffer[byteCounter] = currentByte;
  }
}

///////////////////////////
// UPDATE BUFFER SUMS
///////////////////////////
void updateBufferSums() {

  // the bufferSum is a running tally of the entire measurementBuffer
  // add the new measurement and subtract the old one

  for (int i=0; i<NUM_INPUTS; i++) {
    byte currentByte = inputs[i].measurementBuffer[byteCounter];
    boolean currentMeasurement = (currentByte >> bitCounter) & 0x01; 
    if (currentMeasurement) {
      inputs[i].bufferSum++;
    }
    if (inputs[i].oldestMeasurement) {
      inputs[i].bufferSum--;
    }
  }  
}

///////////////////////////
// UPDATE BUFFER INDEX
///////////////////////////
void updateBufferIndex() {
  bitCounter++;
  if (bitCounter == 8) {
    bitCounter = 0;
    byteCounter++;
    if (byteCounter == BUFFER_LENGTH) {
      byteCounter = 0;
    }
  }
}

///////////////////////////
// UPDATE INPUT STATES
///////////////////////////
void updateInputStates() {
  inputChanged = false;
  for (int i=0; i<NUM_INPUTS; i++) {
    inputs[i].prevPressed = inputs[i].pressed; // store previous pressed state (only used for mouse buttons)
    if (inputs[i].pressed) {
      if (inputs[i].bufferSum < releaseThreshold) {  
        inputChanged = true;
        inputs[i].pressed = false;
               
        
        /* TODO - can we reset the entire column or row here rather than updating the entire monome?
        One problem may be the fact that keys are constantly released- if, for example, another
        key is triggered (holding two keys at once), it's possible that the key release is flickered
        between the two keys. Effect: LED cell that flickers on/off rather than solid color.
        */
        
        if(i<8) resetRow(i);
        else resetColumn(i);
        updateMonome();
      }
    } 
    else if (!inputs[i].pressed) {
      if (inputs[i].bufferSum > pressThreshold) {  // input becomes pressed
        inputChanged = true;
        inputs[i].pressed = true; 
        updateMonome(); 
      }
    }
  }
#ifdef DEBUG3
  if (inputChanged) {
    Serial.println("change");
  }
#endif
}


///////////////////////////
// UPDATE MONOME
///////////////////////////
void updateMonome() {
  for(int i=0; i<8; i++) {
    if(inputs[i].pressed){
      for(int j=0; j<8; j++) {
        if(inputs[j+8].pressed) {
          int index = i*8 + j;
          if (!buttons[index].pressed) {
            if(!buttons[index].state) { 
              buttons[index].state = true;
              setNeopixel(index, true);
#ifdef SERIAL9600 
              // add 1 to differentiate index from 0 bytes of serial data
              Serial.write(index+1);
#endif              
#ifdef DEBUG_MONOME
              Serial.print("button ");
              Serial.print(index);
              Serial.println(" ON");
#endif
            }
            else {
              buttons[index].state = false;
              setNeopixel(index, false);
#ifdef SERIAL9600              
              Serial.write(index+65);
#endif  
#ifdef DEBUG_MONOME
              Serial.print("button ");
              Serial.print(index);
              Serial.println(" OFF");
#endif
            }
            buttons[index].pressed = true;
          }
        }
      }
    }
  }
}

void resetRow(int rowNum) {
  for(int i=(rowNum*8); i<(rowNum*8+8); i++) {
    buttons[i].pressed = false;
  }
}

void resetColumn(int column) {
  for(int i=column; i<8; i++) {
    buttons[i*8+column].pressed = false;
  }
}



///////////////////////////
// UPDATE NEOPIXELS
///////////////////////////
void setNeopixel(int i, boolean state) {
  if(state) {
    // since we zig zag Neopixels in array, test if this is an even or odd row
    if((i/8)%2 == 0) strip.setPixelColor(i, ledColor);
    // the math here takes into account that we're zigzagging
    else strip.setPixelColor((i/8)*8 + 7 - (i%8), ledColor);
  }
  else {
    if((i/8)%2 == 0) strip.setPixelColor(i, 0);
    else strip.setPixelColor((i/8)*8 + 7 - (i%8), 0);
  }
  strip.show();
}

///////////////////////////
// ADD DELAY
///////////////////////////
void addDelay() {

  loopTime = micros() - prevTime;
  if (loopTime < TARGET_LOOP_TIME) {
    int wait = TARGET_LOOP_TIME - loopTime;
    delayMicroseconds(wait);
  }

  prevTime = micros();

#ifdef DEBUG_TIMING
  if (loopCounter == 0) {
    int t = micros()-prevTime;
    Serial.println(t);
  }
  loopCounter++;
  loopCounter %= 999;
#endif

}


///////////////////////////
// UPDATE OUT LED
///////////////////////////
void updateOutLED() {
  boolean keyPressed = 0;
  for (int i=0; i<NUM_INPUTS; i++) {
    if (inputs[i].pressed) {
        keyPressed = 1;
#ifdef DEBUG
        Serial.print("Key ");
        Serial.print(i);
        Serial.println(" pressed");
#endif
    }
  }

  if (keyPressed) {
    digitalWrite(outputK, HIGH);
  }
  else {       
    digitalWrite(outputK, LOW);
  }
}

// Input a value 0 to 255 to get a color value.
// The colours are a transition r - g - b - back to r.
uint32_t Wheel(byte WheelPos) {
  if(WheelPos < 85) {
   return strip.Color(WheelPos * 3, 255 - WheelPos * 3, 0);
  } else if(WheelPos < 170) {
   WheelPos -= 85;
   return strip.Color(255 - WheelPos * 3, 0, WheelPos * 3);
  } else {
   WheelPos -= 170;
   return strip.Color(0, WheelPos * 3, 255 - WheelPos * 3);
  }
}

void rainbow(uint8_t wait) {
  uint16_t i, j;

  for(j=0; j<256; j++) {
    for(i=0; i<strip.numPixels(); i++) {
      strip.setPixelColor(i, Wheel((i+j) & 255));
    }
    strip.show();
    delay(wait);
  }
}

void clearNeopixels() {
  for(int i=0; i<NUM_BUTTONS; i++) {
    strip.setPixelColor(i, 0);
  }
  strip.show();
}




