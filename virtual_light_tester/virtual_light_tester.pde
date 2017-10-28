// this sketch draws the bulb and change color when sound amplitud changes
// Requires sound library

import processing.sound.*;
AudioIn in;
Amplitude rms;

void setup() {
  size(200, 420); 
  background(0);
  noStroke();
  //frameRate(2);
  // Create the Input stream
  in = new AudioIn(this, 0);
  in.start();
 // in.play();
  // create a new Amplitude analyzer
    rms = new Amplitude(this);
    // Patch the input to an volume analyzer
    rms.input(in);
    
}

int BULB_NB = 20; 
Bulb[] myBulbs = new Bulb[BULB_NB];

void draw() {
  // draw bulbs
   // draw first balls
          for (int i = 0; i < BULB_NB; i++)
    {
      int dc = int(map(rms.analyze(), 0, 0.5, 1, 255));
      myBulbs[i] = new Bulb(color(dc,255-dc,255), 80, i*20+20, 15);
      myBulbs[i].display();
    } 
   //  print(int(map(rms.analyze(), 0, 0.5, 1, 255)), "\n");
}
// Bulbs: [int ID, int R, int G, int B, float A, float xpos, float ypos, float bsize]

// definir bulb
class Bulb{
  color c;
  float xpos;
  float ypos;
  float bsize;
  
  // The Constructor is defined with arguments.
  Bulb(color tempC, float tempXpos, float tempYpos, float tempBsize){
    c = tempC;
    xpos = tempXpos;
    ypos = tempYpos;
    bsize = tempBsize;
  }
  void display() {
    for (int i = 0; i < BULB_NB; i++) {
    fill(c, upDownCounter(10, 5));
    ellipse(xpos, ypos, bsize, bsize);
    }
  }
}

void keyPressed() {
  if (key == '1') {
   print("1");
  } else if (key == '2') {
    print("2");
  }
}

float upDownCounter(int maxValue, int factor) {
  float doubleMaxValue = 2*maxValue;
  float fcd = (frameCount/factor)%doubleMaxValue;
  return (fcd<maxValue)?fcd:doubleMaxValue-fcd; // this line is also important!
}