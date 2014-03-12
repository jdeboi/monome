/**
 * Makey Makey Monome
 *
 * Jenna deBoisblanc
 * jdeboi.com
 * January 2014
 *
 */
 
import ddf.minim.*;
Minim minim;
AudioSample[] sounds;

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
  rowTime = new int[8];
  columnTime = new int[8];
  buttons = new Button[64];
  
  
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
  drawMonome();
  sequence();
}

void updateMonome() {
  for(int i=0; i<8; i++) {
    if(millis() - rowTime[i] < triggerThresh){
      for(int j=0; j<8; j++) {
        if(millis() - columnTime[j] < triggerThresh) {
          checkButton(i*8 + j);
        }
        else {
          buttons[i*8+j].pressed = false;
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


void checkButton(int button) {
  if (!buttons[button].pressed) {
    buttons[button].switchState();
    buttons[button].pressed = true;
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
  for(int i=0; i<64; i++) {
    if(buttons[i].contains()) buttons[i].switchState();
  }
  updateMonome();
}

void loadSounds() {
   // see minim Processing example files for explanations
  minim = new Minim(this);
  // load sounds - filename, buffer size
  sounds = new AudioSample[8];
  sounds[0] = minim.loadSample("audio/clap.wav", 512);
  sounds[1] = minim.loadSample("audio/hihatcl.wav", 512);
  sounds[2] = minim.loadSample("audio/hihatopen.wav", 512);
  sounds[3] = minim.loadSample("audio/kick.wav", 512);
  sounds[4] = minim.loadSample("audio/snare.wav", 512);
  sounds[5] = minim.loadSample("audio/starkick.wav", 512);
  sounds[6] = minim.loadSample("audio/tomhi.wav", 512);
  sounds[7] = minim.loadSample("audio/tomlow.wav", 512);
}
    
  


