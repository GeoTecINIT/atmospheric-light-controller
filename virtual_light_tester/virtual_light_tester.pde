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

int BULB_NB = 40; 
Bulb[] myBulbs = new Bulb[BULB_NB];

void draw() {

          for (int i = 0; i < BULB_NB; i++)
    {
      int dc = int(map(rms.analyze(), 0, 0.5, 1, 255)); // Modifies the color with sound amplitude
      // drawing the bubls
      float tempYpos = i*20+20;
      float tempXpos = 80;
      if(i>19){ //change position values to draw two lines
        tempYpos = (i-20)*20+20;
        tempXpos = 120;
      }
      myBulbs[i] = new Bulb(i+1, dc,255-dc,255, upDownCounter(10, 5), tempXpos, tempYpos, 15);
      myBulbs[i].display();
    } 
}
// Bulbs: [int ID, int R, int G, int B, float A, float xpos, float ypos, float bsize]

// definir bulb
class Bulb{
  color c;
  float a;
  float xpos;
  float ypos;
  float bsize;
  int objID;
  
  // The Constructor is defined with arguments.
  Bulb(int objID, int tempR, int tempG, int tempB, float tempA, float tempXpos, float tempYpos, float tempBsize){
    c = color(tempR, tempG, tempB);
    a = tempA;
    xpos = tempXpos;
    ypos = tempYpos;
    bsize = tempBsize;
    objID = objID;
  }
  void display() {
    //adds glow effect [TEST - NOT WORKING PROPERLY]
    for (int i = 0; i < BULB_NB; i++) {
    fill(c, a);
    ellipse(xpos, ypos, bsize, bsize);
    }
  }
}

// for changing modes manually
void keyPressed() {
  if (key == '1') {
   print("1");
  } else if (key == '2') {
    print("2");
  } else if (key == '3') {
    print("3");
  }else if (key == '4') {
    print("4");
  }else if (key == '5') {
    print("5");
  }
}
// counts fordward and backwards (for the glow effect)
float upDownCounter(int maxValue, int factor) {
  float doubleMaxValue = 2*maxValue;
  float fcd = (frameCount/factor)%doubleMaxValue;
  return (fcd<maxValue)?fcd:doubleMaxValue-fcd; // this line is also important!
}