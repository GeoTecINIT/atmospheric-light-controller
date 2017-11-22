// this sketch draws the bulb and change color when sound amplitud changes
// Requires sound library

import processing.sound.*;
import oscP5.*;
import netP5.*;

AudioIn in;
Amplitude rms;

OscP5 oscP5;
NetAddress nodejsServer;
char receivedString;
char chosenOption; 
char chosenSpeed; 
int a = 0;
int cm;
void setup(){
  size(200, 420); 
  background(0);
  noStroke();
   frameRate(30);
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
Bulb bulb; 
void draw() { 
    a++; if(a>255){a=0;}
    
     
         switch(chosenOption){
            // *** CASE A : Alternate strobo between lights  ***
        case 'A': 
          for (int i = 0; i < BULB_NB; i++){ //iterate through the bulbs
            
                //defining the position of bulbs in graph
            float tempYpos = i*20+20;
            float tempXpos = 80;
            if(i>19){ //change position values to draw two lines
              tempYpos = (i-20)*20+20;
              tempXpos = 120;
            }
            
            if(i% 2 == 0){
              cm = (millis() + 2500) % 255; 
              bulb = new Bulb(cm,cm,cm, 1, tempXpos, tempYpos, 15); }
             else{
             cm = millis() % 255;
             bulb = new Bulb(cm,cm,cm, 1, tempXpos, tempYpos, 15); }
             bulb.display();
          }
          break;
           // *** CASE B  //  slow progression ***
         case 'B':
             for (int i = 0; i < BULB_NB; i++){ //iterate through the bulbs
                
                    //defining the position of bulbs in graph
                float tempYpos = i*20+20;
                float tempXpos = 80;
                if(i>19){ //change position values to draw two lines
                  tempYpos = (i-20)*20+20;
                  tempXpos = 120;
                }
               cm = (a+i*39)%255;
               bulb = new Bulb(cm,cm,cm, 1, tempXpos, tempYpos, 15);
               bulb.display();
             }
          break;
          // *** CASE C : Testing entire chain progression ***
          case 'C':
              for (int i = 0; i < BULB_NB; i++){ //iterate through the bulbs
                  
                      //defining the position of bulbs in graph
                  float tempYpos = i*20+20;
                  float tempXpos = 80;
                  if(i>19){ //change position values to draw two lines
                    tempYpos = (i-20)*20+20;
                    tempXpos = 120;
                  }
                  cm = int(map(i, 0, 40, 0, 255))%255;
                 //cm = (a*i)%255;
                 println(a,i,cm, frameRate);
                 bulb = new Bulb(cm,cm,cm, 1, tempXpos, tempYpos, 15);
                 bulb.display();
              }
          break;
          // *** CASE D : Parallel chain progression  ***
          case 'D':
              for (int i = 0; i < BULB_NB; i++){ //iterate through the bulbs
                      //defining the position of bulbs in graph
                  float tempYpos = i*20+20;
                  float tempXpos = 80;
                  if(i>19){ //change position values to draw two lines
                    tempYpos = (i-20)*20+20;
                    tempXpos = 120;
                  }
                println(frameRate);
                if(i >= BULB_NB/2){
                  cm = (a*(i-BULB_NB/2))%255; 
                  bulb = new Bulb(cm,cm,cm, 1, tempXpos, tempYpos, 15); }
                 else{ 
                  cm = (a*i)%255;
                bulb = new Bulb(cm,cm,cm, 1, tempXpos, tempYpos, 15); }
                bulb.display();
              }
          break;
          // *** CASE X: LIGHTS TURNED OFF ***
          case 'X':
            for (int i = 0; i < BULB_NB; i++){ //iterate through the bulbs
                    
                        //defining the position of bulbs in graph
                    float tempYpos = i*20+20;
                    float tempXpos = 80;
                    if(i>19){ //change position values to draw two lines
                      tempYpos = (i-20)*20+20;
                      tempXpos = 120;
                    }
              bulb = new Bulb(0,0,0, 0, tempXpos, tempYpos, 15); 
            }
          break;
          // *** CASE DEFAULT: Sound Amplitude response ***
         default:
          for (int i = 0; i < BULB_NB; i++){ //iterate through the bulbs
                    
                        //defining the position of bulbs in graph
                    float tempYpos = i*20+20;
                    float tempXpos = 80;
                    if(i>19){ //change position values to draw two lines
                      tempYpos = (i-20)*20+20;
                      tempXpos = 120;
                    }
           int dc = int(map(rms.analyze(), 0, 0.5, 1, 255)); // Modifies the color with sound amplitude
           bulb = new Bulb(dc,255-dc,255, 1, tempXpos, tempYpos, 15);
           bulb.display();
           println(dc);
          }
          break;
       }
       
    }

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
    fill(c);
    ellipse(xpos, ypos, bsize, bsize);
  }
}

// for changing modes manually
void keyPressed() {
  if (key == 'a' || key == 'A') {
   print("Key pressed: option A\n");
   chosenOption = 'A';
  } else if (key == 'b' || key == 'B') {
    print("Key pressed: option B\n");
    chosenOption = 'B';
  } else if (key == 'c' || key == 'C') {
    print("Key pressed: option C\n");
    chosenOption = 'C';
  }else if (key == 'd' || key == 'D') {
    print("Key pressed: option D\n");
    chosenOption = 'D';
  }else if (key == 'e' || key == 'E') {
    print("Key pressed: option E\n");
    chosenOption = 'E';
  }else if (key == 'x' || key == 'X') {
    print("Key pressed: option X\n");
    chosenOption = 'X';
  }else if (key == 'n' || key == 'N') {
    print("option set to empty\n");
    chosenOption = '\n';
  }
  if (key == '1') {
   print("Key pressed: Speed 1\n");
   chosenSpeed = '1';
   frameRate(5);
  } else if (key == '2') {
    print("Key pressed: Speed 2\n");
    chosenSpeed = '2';
    frameRate(20);
  } else if (key == '3') {
    print("Key pressed: Speed 3\n");
    chosenSpeed = '3';
    frameRate(30);
  }else if (key == '4') {
    print("Key pressed: Speed 4\n");
    chosenSpeed = '4';
    frameRate(50);
  }else if (key == '5') {
    print("Key pressed: Speed 5\n");
    chosenSpeed = '5';
    frameRate(80);
  }else if (key == '0') {
    print("option set to stop\n");
    chosenSpeed = '0';
  }
}

 void receive(char s){
   receivedString=s;
 }
/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  if(theOscMessage.checkAddrPattern("/clientMsg")==true) {
    /* check if the typetag is the right one. */
    if(theOscMessage.checkTypetag("s")) {
      /* parse theOscMessage and extract the values from the osc message arguments. */
      receivedString=theOscMessage.get(0).stringValue().charAt(0);
      print("Key received by webserver",receivedString);
      chosenOption = receivedString;
    }  
  }
}