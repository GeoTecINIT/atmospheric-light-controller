// this sketch draws the bulb and change color when sound amplitud changes
// Requires sound library

import processing.sound.*;
import oscP5.*;
import netP5.*;

AudioIn in;
Amplitude rms;

OscP5 oscP5;
NetAddress nodejsServer;
String receivedString="";

void setup(){
  size(200, 420); 
  background(0);
  noStroke();
  /* start oscP5, listening for incoming messages at port 12000 */
  oscP5 = new OscP5(this,3333);
  
  /* myRemoteLocation is a NetAddress. a NetAddress takes 2 parameters,
   * an ip address and a port number. myRemoteLocation is used as parameter in
   * oscP5.send() when sending osc packets to another computer, device, 
   * application. usage see below. for testing purposes the listening port
   * and the port of the remote location address are the same, hence you will
   * send messages back to this sketch.
   */
   nodejsServer = new NetAddress("127.0.0.1",3334);
   
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

int BULB_NB = 40; // Quantity of bulbs
ArrayList<Bulb> bulbs = new ArrayList<Bulb>(); 

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
      // upDownCounter(10, 5) color changer for alpha (making the system slow)
      bulbs.add(new Bulb(i+1, dc,255-dc,255, 1, tempXpos, tempYpos, 15));
    } 
  for (int i = 0; i < bulbs.size(); i++) {
  Bulb part = bulbs.get(i);
  part.display();
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
    fill(c);
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
 void receive(String s){
   receivedString=s;
 }
/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  if(theOscMessage.checkAddrPattern("/clientMsg")==true) {
    /* check if the typetag is the right one. */
    if(theOscMessage.checkTypetag("s")) {
      /* parse theOscMessage and extract the values from the osc message arguments. */
      receivedString=theOscMessage.get(0).stringValue();
      print(receivedString);
    }  
  }
}