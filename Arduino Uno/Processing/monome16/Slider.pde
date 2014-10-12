
class Slider {
  int n, x, y, w, h, sliderPos, sliderY, sliderVal, minVal, maxVal; 
  int sliderH = 20;
  int sliderW = 10;
  boolean draggable;
  
  Slider(int xpos, int ypos, int wd, int ht, int min, int max, int init) {
    x = xpos;
    y = ypos;
    w = wd;
    h = ht;
    minVal = min;
    maxVal = max;
    sliderVal = init;
    sliderY = y -((sliderH-h)/2);
    updateSliderPos(); 
  }
  
  void drawSlider() {
    fill(200);
    noStroke();
    rect(x, y, w, h);
    fill(150);
    rect(sliderPos, sliderY, sliderW, sliderH); 
  }
  
  boolean contains() {
    if (mouseX > sliderPos && mouseX < sliderPos+sliderW && mouseY > sliderY && mouseY < sliderY+sliderH) return true;
    return false;
  }
  
  void updateSliderPosMouse() {
    if (mouseX > x+w) sliderPos = x+w;
    else if (mouseX < x) sliderPos = x;
    else sliderPos = mouseX;
  }
  
  int getSliderVal() {
    sliderVal = int(map(sliderPos - x,0,w, minVal, maxVal));
    return sliderVal;
  }
  
  void setSliderVal(int value) {
    sliderVal = value;
    updateSliderPos();
  }
  
  void updateSliderPos() {
    sliderPos = int(map(sliderVal, minVal, maxVal, 0.0, 1.0)*w+x);
  }
}
    
