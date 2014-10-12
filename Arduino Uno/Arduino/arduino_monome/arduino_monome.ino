/*
 ************************************************
 ********* CONDUCTIVE ARDUINO MONOME ************
 ************************************************
 //MAKER////////////
 Jenna deBoisblanc
 http://jdeboi.com
 start date: October 2014
 
 //DESCRIPTION//////
 My objective for this project was to build a monome- http://monome.org/ -
 (basically a programmable array of backlit buttons that's used
 to compose electronic music or mix video) using tools and processes 
 that were so simple, a third grader could build it.
 
 This sketch relies on capacitive sensors (copper tape attached to Arduino pins
 using jumpers). Sound is produced by the monomeVisual Processing sketch.
 
 I used Adafruit Neopixels- RGB LEDs that are individually addressible but only 
 need 1 digital out- arranged in an 8x8 zigzag matrix to light up the squares when 
 pressed.
 
 //CREDIT///////////
 Special thanks to Amanda Ghassaei, one of my best friends, for introducing
 me to monomes and the Maker Movement.
 
 Code shout-outs:
 1. MaKey MaKey FIRMWARE v1.4.1
 by: Eric Rosenbaum, Jay Silver, and Jim Lindblom http://makeymakey.com
 2. Capacitive sensor code: http://playground.arduino.cc/Code/CapacitiveSensor
 3. Adafruit Neopixel library
 http://learn.adafruit.com/adafruit-neopixel-uberguide/neomatrix-library
 */

/////////////////////////
// DEBUG DEFINITIONS ////               
/////////////////////////
//#define DEBUG
//#define DEBUG2 
//#define DEBUG3 
//#define DEBUG_TIMING
//#define DEBUG_MONOME

////////////////////////
// DEFINED CONSTANTS////
////////////////////////
#define NUM_ROWS         8
#define NUM_COLUMNS      8
#define NUM_INPUTS       NUM_ROWS+NUM_COLUMNS      // 8 rows, 8 columns
#define NUM_BUTTONS      NUM_ROWS * NUM_COLUMNS    // 64 buttons

#define SERIAL9600
#include "settings.h"

/////////////////////////
// MAKEY MAKEY STRUCT ///
/////////////////////////
typedef struct {
  byte pinNumber;
  int keyCode;
  int timePressed;
  float movingAverage;
  boolean pressed;
  boolean prevPressed;
} 
MakeyMakeyInput;
MakeyMakeyInput inputs[NUM_INPUTS];

// create some buttons to keep track of LED states
typedef struct {
  boolean pressed;
  boolean state;
  boolean highlight;
}
Button;
Button buttons [NUM_BUTTONS];
uint32_t ledColor = 0;
uint32_t ledHighlightColor = 0;
uint32_t ledHighlightOnColor = 0;

/*
/////////////////////////
// NEOPIXELS ////////////
/////////////////////////
// http://learn.adafruit.com/adafruit-neopixel-uberguide/neomatrix-library
// set the Neopixel pin to 0 - D0
#define NEO_PIN 12
#include <Adafruit_NeoPixel.h>
Adafruit_NeoPixel strip = Adafruit_NeoPixel(NUM_BUTTONS, NEO_PIN, NEO_GRB + NEO_KHZ800);
*/


///////////////////////////////////
// VARIABLES //////////////////////
///////////////////////////////////
float movingAverageFactor = 1;
byte inByte;

float pressThreshold = 4.5;
float releaseThreshold = 3.6;
int triggerThresh = 200;
boolean inputChanged;

int pinNumbers[NUM_INPUTS] = {        
  // Rows ///////////////////////// 
  2,    
  3,    
  4,    
  5,      
  // Columns ///////////////////////
  9,     
  8,     
  7,     
  6     
};


// LED that indicates when key is pressed
const int outputK = 13;
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
void updateMovingAverage();
void updateInputStates();
void addDelay();
void updateOutLED();
void updateNeopixels();

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
  checkSerialInput();
  updateMovingAverage();
  updateInputStates();
  updateOutLED();
}

//////////////////////////
// INITIALIZE ARDUINO
//////////////////////////
void initializeArduino() {
  Serial.begin(9600);  
  while (!Serial) {
    ; // wait for serial port to connect. Needed for Leonardo only
  }
  /* Set up input pins 
   DEactivate the internal pull-ups, since we're using external resistors */
  for (int i=0; i<NUM_INPUTS; i++)
  {
    pinMode(pinNumbers[i], INPUT);
    digitalWrite(pinNumbers[i], LOW);
  }
  
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

  for (int i=0; i<NUM_INPUTS; i++) {
    inputs[i].pinNumber = pinNumbers[i];
    inputs[i].keyCode = keyCodes[i];
    inputs[i].movingAverage = 0;
    
    inputs[i].pressed = false;
    inputs[i].prevPressed = false;

#ifdef DEBUG
    Serial.println(i);
#endif

  }
}

void checkSerialInput() {
  /*
    here is what the incoming serial data means
    0 => no incoming serial data
    1-64 => strip.setPixelColor(i, ledColor) where i is between 0-63 (turn LED on)
    65-129 => strip.setPixelColor(i, 0) where i is between 0-63 (turn LED off)
    129 => clear monome
    130-137 => highlight columns 0-7
    >138 => corresponds to a color change of the LEDs
  */
  if (Serial.available() > 0) {
    // get incoming byte:
    inByte = Serial.read();
      
    // turn LED on
    if (inByte < NUM_BUTTONS + 1) {
      buttons[inByte-1].state = true;
      //updateNeopixels;
    }
    // turn LED off
    else if (inByte > NUM_BUTTONS && inByte < NUM_BUTTONS*2 + 1) {
      buttons[inByte-(NUM_BUTTONS+1)].state = false;
      //updateNeopixels();
    }
    // clear monome
    else if (inByte == NUM_BUTTONS*2 + 1) clearMonome();
    // highlight column
    else if (inByte > NUM_BUTTONS*2+1 && inByte < (NUM_BUTTONS)*2+2+NUM_COLUMNS) highlightColumn(inByte-(NUM_BUTTONS*2+2));
    // change ledColor
    //else ledColor = inByte - NUM_BUTTONS*2+2+NUM_COLUMNS;
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
  setColors();
}


///////////////////////////
// UPDATE INPUT STATES
///////////////////////////
void updateInputStates() {
  inputChanged = false;
  for (int i=0; i<NUM_INPUTS; i++) {
    inputs[i].prevPressed = inputs[i].pressed; // store previous pressed state (only used for mouse buttons)
    if (inputs[i].pressed) {
      if (inputs[i].movingAverage < releaseThreshold) {  
        inputChanged = true;
        inputs[i].pressed = false;
               
        
        /* TODO - can we reset the entire column or row here rather than updating the entire monome?
        One problem may be the fact that keys are constantly released- if, for example, another
        key is triggered (holding two keys at once), it's possible that the key release is flickered
        between the two keys. Effect: LED cell that flickers on/off rather than solid color.
        */
        
        if(i< NUM_ROWS) resetRow(i);
        else resetColumn(i);
        updateMonome();
      }
    } 
    else if (!inputs[i].pressed) {
      if (inputs[i].movingAverage > pressThreshold) {  // input becomes pressed
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
  for(int i=0; i< NUM_ROWS; i++) {
    if(inputs[i].pressed){
      for(int j=0; j< NUM_COLUMNS; j++) {
        // in original monome, input[0]-input[7] were rows, input[8]-input[15] were columns
        if(inputs[j+ NUM_ROWS].pressed) {
          int index = i*NUM_COLUMNS + j;
          if (!buttons[index].pressed) {
            if(!buttons[index].state) { 
              buttons[index].state = true;
              updateNeopixels();
#ifdef SERIAL9600 
              // add 1 to differentiate index from 0 bytes of serial data
              byte passVal = index+1;
              Serial.write(passVal);
#endif              
#ifdef DEBUG_MONOME
              Serial.print("button ");
              Serial.print(index);
              Serial.println(" ON");
#endif
            }
            else {
              buttons[index].state = false;
              // updateNeopixels();
#ifdef SERIAL9600  
              byte passVal = index+1+NUM_BUTTONS;
              Serial.write(passVal);
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
  for(int i=(rowNum*NUM_COLUMNS); i<(rowNum*NUM_COLUMNS+NUM_COLUMNS); i++) {
    buttons[i].pressed = false;
  }
}

void resetColumn(int column) {
  for(int i=column; i<NUM_COLUMNS; i++) {
    buttons[i*NUM_COLUMNS+column].pressed = false;
  }
}

void clearMonome() {
  clearNeopixels();
  for(int i=0; i<NUM_BUTTONS; i++) {
    buttons[i].state = false;
    buttons[i].highlight = false;
  }
}

void highlightColumn(int column) {
  for (int i=0; i<NUM_COLUMNS; i++) {
    // highlight the colum; buttons that are already on get a diff color
    buttons[column+i*NUM_COLUMNS].highlight = true;
    // turn off the column that was previously highlighted
    if (column == 0) {
       buttons[(NUM_COLUMNS-1)+i*NUM_COLUMNS].highlight = false;
    }
    else {
      buttons[column-1+i*NUM_COLUMNS].highlight = false;
    }
  }
  updateNeopixels();
}


///////////////////////////
// UPDATE NEOPIXELS
///////////////////////////
void updateNeopixels() {
  for (int i = 0; i < 64; i++) {
    int stripIndex = getStripIndex(i);
    if (buttons[i].state) {
      if (buttons[i].highlight) strip.setPixelColor(stripIndex, ledHighlightOnColor);
      else strip.setPixelColor(stripIndex, ledColor);
    }
    else {
      if(buttons[i].highlight) strip.setPixelColor(stripIndex, ledHighlightColor);
      else strip.setPixelColor(stripIndex, 0);
    }
  }
  strip.show();
}

// since we zig zag the Neopixel strip, test if this is an even or odd row
// and return the strip index that corresponds to the monome index
int getStripIndex(int i) {
  if((i/8)%2 == 0) return i;
  return (i/8)*8 + 7 - (i%8);
}

void clearNeopixels() {
  for(int i=0; i<NUM_BUTTONS; i++) {
    strip.setPixelColor(i, 0);
  }
  strip.show();
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


///////////////////////////
// NEOPIXEL COLORS
///////////////////////////
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

void setColors() {
  ledColor = strip.Color(10, 255, 79);
  ledHighlightColor = strip.Color(23, 114, 255);
  ledHighlightOnColor = strip.Color(10, 255, 79);
}


///////////////////////////
// CAPACITIVE SENSORS
///////////////////////////
uint8_t readCapacitivePin(int pinToMeasure) {
  // Variables used to translate from Arduino to AVR pin naming
  volatile uint8_t* port;
  volatile uint8_t* ddr;
  volatile uint8_t* pin;
  // Here we translate the input pin number from
  //  Arduino pin number to the AVR PORT, PIN, DDR,
  //  and which bit of those registers we care about.
  byte bitmask;
  port = portOutputRegister(digitalPinToPort(pinToMeasure));
  ddr = portModeRegister(digitalPinToPort(pinToMeasure));
  bitmask = digitalPinToBitMask(pinToMeasure);
  pin = portInputRegister(digitalPinToPort(pinToMeasure));
  // Discharge the pin first by setting it low and output
  *port &= ~(bitmask);
  *ddr  |= bitmask;
  delay(1);
  // Prevent the timer IRQ from disturbing our measurement
  noInterrupts();
  // Make the pin an input with the internal pull-up on
  *ddr &= ~(bitmask);
  *port |= bitmask;

  // Now see how long the pin to get pulled up. This manual unrolling of the loop
  // decreases the number of hardware cycles between each read of the pin,
  // thus increasing sensitivity.
  uint8_t cycles = 17;
       if (*pin & bitmask) { cycles =  0;}
  else if (*pin & bitmask) { cycles =  1;}
  else if (*pin & bitmask) { cycles =  2;}
  else if (*pin & bitmask) { cycles =  3;}
  else if (*pin & bitmask) { cycles =  4;}
  else if (*pin & bitmask) { cycles =  5;}
  else if (*pin & bitmask) { cycles =  6;}
  else if (*pin & bitmask) { cycles =  7;}
  else if (*pin & bitmask) { cycles =  8;}
  else if (*pin & bitmask) { cycles =  9;}
  else if (*pin & bitmask) { cycles = 10;}
  else if (*pin & bitmask) { cycles = 11;}
  else if (*pin & bitmask) { cycles = 12;}
  else if (*pin & bitmask) { cycles = 13;}
  else if (*pin & bitmask) { cycles = 14;}
  else if (*pin & bitmask) { cycles = 15;}
  else if (*pin & bitmask) { cycles = 16;}

  // End of timing-critical section
  interrupts();

  // Discharge the pin again by setting it low and output
  //  It's important to leave the pins low if you want to 
  //  be able to touch more than 1 sensor at a time - if
  //  the sensor is left pulled high, when you touch
  //  two sensors, your body will transfer the charge between
  //  sensors.
  *port &= ~(bitmask);
  *ddr  |= bitmask;

  return cycles;
}

void updateMovingAverage() {
  for(int i = 0; i < NUM_INPUTS; i++) {
    int cycles = readCapacitivePin(pinNumbers[i]);
    int mave = inputs[i].movingAverage;
    inputs[i].movingAverage = mave * (1.0 - movingAverageFactor) + cycles * movingAverageFactor;
  }
}

