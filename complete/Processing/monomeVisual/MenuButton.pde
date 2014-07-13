
class MenuButton {
  int n, x, y, w, h;
  PImage onImage, offImage;
  boolean state = false;
  int imageDim = 40;
  String label;
  
  MenuButton(int num, int xpos, int ypos, int wd, int ht, String lab,
    String offString, String onString) {
    n = num;
    x = xpos;
    y = ypos;
    w = wd;
    h = ht;
    state = false;
    onImage = loadImage(onString);
    offImage = loadImage(offString);
    label = lab;
  }
  
  void drawButton() {
    if (contains()) {
      fill(245);
      noStroke();
      int buttonPadding = 10;
      // backlight when hovering over button
      //rect(x-(buttonPadding/2), y-(buttonPadding/2), imageDim+buttonPadding, imageDim+buttonPadding*2);
      fill(0);
      stroke(0);
      // center button label
      float xLab = ((imageDim+buttonPadding-textWidth(label))/2);
      text(label, x-(buttonPadding/2)+xLab, y+imageDim+buttonPadding+3);
    }
    if(state) {
      image(onImage, x, y, imageDim, imageDim);
    }
    else image(offImage, x, y, imageDim, imageDim);
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
  
}
    
