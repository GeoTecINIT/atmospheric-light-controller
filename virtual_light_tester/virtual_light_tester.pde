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

String chosenOption=""; 

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
    int cm = millis() % 255;
    int cmd = (millis() + 2500) % 255;
      //iterate through the bulbs
     for (int i = 0; i < BULB_NB; i++){
       
       //defining the position of bulbs in graph
        float tempYpos = i*20+20;
        float tempXpos = 80;
        if(i>19){ //change position values to draw two lines
          tempYpos = (i-20)*20+20;
          tempXpos = 120;
        }
        //changing the program by pressing keys or web interface
         if(chosenOption=="option1"){
           if(i% 2 == 0){ bulbs.add(new Bulb(cmd,cmd,cmd, 1, tempXpos, tempYpos, 15)); }
           else{ bulbs.add(new Bulb(cm,cm,cm, 1, tempXpos, tempYpos, 15)); }
         }else{ // default programming if there is not chosen option
            int dc = int(map(rms.analyze(), 0, 0.5, 1, 255)); // Modifies the color with sound amplitude
            // upDownCounter(10, 5) color changer for alpha (making the system slow)
            bulbs.add(new Bulb(dc,255-dc,255, 1, tempXpos, tempYpos, 15));
      } 
    }
  //draw the bulbs
  for (int i = 0; i < bulbs.size(); i++) {
    Bulb part = bulbs.get(i);
    part.display();
 }
}
// Bulbs: [int R, int G, int B, float A, float xpos, float ypos, float bsize]

// definir bulb
class Bulb{
  color c;
  float a;
  float xpos;
  float ypos;
  float bsize;  
  // The Constructor is defined with arguments.
  Bulb(int tempR, int tempG, int tempB, float tempA, float tempXpos, float tempYpos, float tempBsize){
    c = color(tempR, tempG, tempB);
    a = tempA;
    xpos = tempXpos;
    ypos = tempYpos;
    bsize = tempBsize;
  }
  void display() {
    //adds glow effect [TEST - NOT WORKING PROPERLY]
   // for (int i = 0; i < BULB_NB; i++) {
    fill(c);
    ellipse(xpos, ypos, bsize, bsize);
   // }
  }
}

// for changing modes manually
void keyPressed() {
  if (key == '1') {
   print("Key pressed: option1\n");
   chosenOption = "option1";
  } else if (key == '2') {
    print("Key pressed: option2\n");
    chosenOption = "option2";
  } else if (key == '3') {
    print("Key pressed: option3\n");
    chosenOption = "option3";
  }else if (key == '4') {
    print("Key pressed: option4\n");
    chosenOption = "option4";
  }else if (key == '5') {
    print("Key pressed: option5\n");
    chosenOption = "option5";
  }else if (key == '0') {
    print("option set to empty\n");
    chosenOption = "";
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
      print("Key received by webserver",receivedString);
      chosenOption = receivedString;
    }  
  }
}