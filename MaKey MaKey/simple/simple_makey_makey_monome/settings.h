#include "Arduino.h"

/*
/////////////////////////////////////////////////////////////////////////
// KEY MAPPINGS: WHICH KEY MAPS TO WHICH PIN ON THE MAKEY MAKEY BOARD? //
/////////////////////////////////////////////////////////////////////////
  
  - edit the keyCodes array below to change the keys sent by the MaKey MaKey for each input
  - the comments tell you which input sends that key (for example, by default 'w' is sent by pin D5)
  - change the keys by replacing them. for example, you can replace 'w' with any other individual letter,
    number, or symbol on your keyboard
  - you can also use codes for other keys such as modifier and function keys (see the
    the list of additional key codes at the bottom of this file)

*/

int keyCodes[NUM_INPUTS] = {
  // top side of the makey makey board
  'h',    // up arrow pad
  '3',    // down arrow pad
  '4',    // left arrow pad
  'g',    // right arrow pad
  'f',    // space button pad
  'e',    // click button pad
  
  // female header on the back left side
  
  'a',    // pin D5
  'b',    // pin D4
  'c',    // pin D3
  'd',    // pin D2
  '1',    // pin D1
  '2',    // pin D0
  
  // female header on the back right side
  
  '5',    // pin A5
  '6',    // pin A4
  '7',    // pin A3
  '8',    // pin A2
  MOUSE_LEFT,         // pin A1
  MOUSE_RIGHT         // pin A0
};

///////////////////////////
// NOISE CANCELLATION /////
///////////////////////////
#define SWITCH_THRESHOLD_OFFSET_PERC  5    // number between 1 and 49
                                           // larger value protects better against noise oscillations, but makes it harder to press and release
                                           // recommended values are between 2 and 20
                                           // default value is 5

#define SWITCH_THRESHOLD_CENTER_BIAS 55   // number between 1 and 99
                                          // larger value makes it easier to "release" keys, but harder to "press"
                                          // smaller value makes it easier to "press" keys, but harder to "release"
                                          // recommended values are between 30 and 70
                                          // 50 is "middle" 2.5 volt center
                                          // default value is 55
                                          // 100 = 5V (never use this high)
                                          // 0 = 0 V (never use this low
                                          

/////////////////////////
// MOUSE MOTION /////////
/////////////////////////
#define MOUSE_MOTION_UPDATE_INTERVAL  35   // how many loops to wait between 
                                           // sending mouse motion updates
                                           
#define PIXELS_PER_MOUSE_STEP         4     // a larger number will make the mouse
                                           // move faster

#define MOUSE_RAMP_SCALE              150  // Scaling factor for mouse movement ramping
                                           // Lower = more sensitive mouse movement
                                           // Higher = slower ramping of speed
                                           // 0 = Ramping off
                                            
#define MOUSE_MAX_PIXELS              10   // Max pixels per step for mouse movement

/*

///////////////////////////
// ADDITIONAL KEY CODES ///
///////////////////////////

- you can use these codes in the keyCodes array above
- to get modifier keys, function keys, etc 

KEY_LEFT_CTRL
KEY_LEFT_SHIFT		
KEY_LEFT_ALT		
KEY_LEFT_GUI		
KEY_RIGHT_CTRL		
KEY_RIGHT_SHIFT		
KEY_RIGHT_ALT	
KEY_RIGHT_GUI		

KEY_BACKSPACE		
KEY_TAB				
KEY_RETURN			
KEY_ESC				
KEY_INSERT			
KEY_DELETE			
KEY_PAGE_UP			
KEY_PAGE_DOWN		
KEY_HOME
KEY_END				
KEY_CAPS_LOCK	
	
KEY_F1				
KEY_F2				
KEY_F3				
KEY_F4				
KEY_F5				
KEY_F6				
KEY_F7				
KEY_F8				
KEY_F9				
KEY_F10
KEY_F11				
KEY_F12			

*/
