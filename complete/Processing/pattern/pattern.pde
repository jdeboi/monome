import org.philhosoft.p8g.svg.P8gGraphicsSVG;

P8gGraphicsSVG svg;

int squareLen = 400;
int windowSize = 500;
int startX = 50;
int startY = 50;
int x = startX;
int y = startY;

int spacing = 15;
int turns = 16;

void setup() {
  // Renders only on the SVG surface, no display
  size(windowSize, windowSize);
  smooth();
  background(#88AAFF);
  
  svg = (P8gGraphicsSVG) createGraphics(width, height, P8gGraphicsSVG.SVG, "maze.svg");
  beginRecord(svg);
}

void draw() {
  svg.beginDraw();
  stroke(0);
  strokeWeight(3);
  
  for (int i = 0; i < 3; i++) { 
    int l = squareLen; 
    
    // draw the first turn of all 3 lines
    l = squareLen - spacing*i;
    x = startX;
    y = startY + spacing*i;
    line(x, y, x+=l, y);
    
    // draw the remaining turns of all 3 lines
    for (int turn = 1; turn < turns; turn++) {
      int t = (turn-1)/2;  
      if (i == 0) l = squareLen - spacing*t*3;
      else if (i == 1) l = squareLen - spacing*(2+(t*3));
      else if (i == 2) l = squareLen - spacing*(4+(t*3));
 
      if (turn % 4 == 1) line(x, y, x, y+=l);
      else if (turn % 4 == 2) line(x, y, x-=l, y);
      else if (turn % 4 == 3) line(x, y, x, y-=l);
      else if (turn % 4 == 0) line(x, y, x+=l, y);
    }
  }  
  
  svg.endRecord();  
  println("Done");
  // Mandatory, so that proper cleanup is called, saving the file
  exit(); 
}
