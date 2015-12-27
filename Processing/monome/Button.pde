
class Button {
  int n, x, y, w, h;
  boolean pressed;
  boolean state;
  boolean highlight;
  color onColor = #ff00bf;
  color offColor = #808080;
  color highlightColor = #0000ff;
  color highlightOnColor = #00FFD5;
  
  Button(int num, int xpos, int ypos, int wd, int ht) {
    n = num;
    x = xpos;
    y = ypos;
    w = wd;
    h = ht;
    pressed = false;
    state = false;
    highlight = false;
  }
  
  void drawButton() {
    stroke(55);
    if (highlight) {
      if (state) fill(highlightOnColor);
      else fill(highlightColor);
    }
    else {
      if (state)fill(onColor);
      else fill(offColor);
    }
    rect(x, y, w, h);
  }
  
  boolean contains() {
    if (mouseX > x && mouseX < x+w && mouseY > y && mouseY < y+h) return true;
    return false;
  }
  
  void switchState() {
    state =! state;
  }
  
  void switchOn() {
    state = true;
  }
  
  void switchOff() {
    state = false;
  }
  
  void unHighlight() {
    highlight = false;
  }
  
  void highlight() {
    highlight = true;
    playSound();
  }
  
  void playSound() {
    if(state) sounds[n/numCols].trigger();
  }
}

    