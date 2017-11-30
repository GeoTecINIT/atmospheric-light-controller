// this sketch draws the bulb and change color when sound amplitud changes

//import processing.sound.*;
import oscP5.*;
import netP5.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
Minim minim;
AudioInput in;
FFT fft1, fft2;

// Audio imports and Variables
// Define how many FFT bands we want
int bands = 128;

/*AudioDevice device;
AudioIn in1, in2;
HighPass highPass;
Amplitude rms1, rms2;
*/
// Declare a scaling factor
int scale=10;

// declare a drawing variable for calculating rect width
float r_width;
// Create a smoothing vector
float[] sum1 = new float[bands];
float[] sum2 = new float[bands];
// Create a smoothing factor
float smooth_factor = 0.2;

// Lights and server variables
OscP5 oscP5;
NetAddress nodejsServer;
char receivedString;
char chosenOption; 
char chosenSpeed; 
int a = 0;
int cm;
int i;
float tempYpos;
float tempXpos;

// DMX Libraries 
import dmxP512.*;
import processing.serial.*;
DmxP512 dmxOutput;
int universeSize=120;
boolean DMXPRO=true;
String DMXPRO_PORT=Serial.list()[1];//case matters ! on windows port must be upper cased.
int DMXPRO_BAUDRATE=115000;

void setup(){
  size(200, 420, P3D);
  background(0);
  noStroke();
  frameRate(30);
  
  /* Start DMX */
  if(DMXPRO){dmxOutput=new DmxP512(this,universeSize,false);
  dmxOutput.setupDmxPro(DMXPRO_PORT,DMXPRO_BAUDRATE);}
  
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
   
  // Create the Input stream
  //device = new AudioDevice(this, 44000, bands);
  minim = new Minim(this);
  in = minim.getLineIn(Minim.STEREO, bands, 44000);
  in.enableMonitoring();
  fft1 = new FFT(in.bufferSize(), in.sampleRate());
  fft2 = new FFT(in.bufferSize(), in.sampleRate());
  
  fft1.logAverages(10, bands);
  fft2.logAverages(10, bands);
 
  // Calculate the width of the rects depending on how many bands we have
  r_width = width*2/float(bands);
/*   
  //Load and play a soundfile and loop it. This has to be called 
  // before the FFT is created.
  // ** WITH AUDIO INPUTS **
  in1 = new AudioIn(this, 1);
  in1.start();
  in2 = new AudioIn(this, 1);
  in2.start();
  
    // FILTERS **
  highPass = new HighPass(this);
  highPass.process(in1, 100);
  
    // Create and patch the FFT analyzer
  fft1 = new FFT(this, bands);
  fft1.input(highPass); // <--- Change for sample or in (or filtered band)
  //fft2 = new FFT(this, bands);
  //fft2.input(in2);

  
  // create a new Amplitude analyzer
    rms1 = new Amplitude(this);
    // Patch the input to an volume analyzer
    rms1.input(in1);
    // create a new Amplitude analyzer
    rms2 = new Amplitude(this);
    // Patch the input to an volume analyzer
    rms2.input(in2);
    */
}

int numFrames = 255;  // The number of frames in the animation
int currentFrame = 0;
int BULB_NB = 40; // Quantity of bulbs
Bulb bulb; 
void draw() { 
    background(125,255,125);
    // ****
    // AUDIO ANALYSIS
    // ****
    
    fft1.forward(in.left);
    fft2.forward(in.right);

    for(int i = 0; i < fft1.specSize(); i++) { 
      sum1[i] += (dB(fft1.getBand(i)) - sum1[i]) * smooth_factor;  // smooth the FFT data by smoothing factor
     // println(dB(fft1.getBand(i)), fft1.getBand(i));
       //objectIdentif(i, sum1[i]);
      rect( i*r_width, height-height/2, r_width, -sum1[i]*scale/2-height/2 ); //Draw the bands
    }
    for(int i = 0; i < fft2.specSize(); i++) {
      sum2[i] += (dB(fft2.getBand(i)) - sum2[i]) * smooth_factor;  // smooth the FFT data by smoothing factor
      //objectIdentif(i, sum2[i]);
      rect( i*r_width, height, r_width, -sum2[i]*scale ); //Draw the bands
    }
   
    
     // ****
    // LIGHT BEHAVIOUR
    // ****
    
    a++; if(a>255){a=0;} // A is going trough color spectrum
    currentFrame = (currentFrame+1) % numFrames;  // Use % to cycle through frames
    int offset = 0;
         switch(chosenOption){
            // *** CASE A : Alternate strobo between lights  ***
        case 'A': 
          for (i = 0; i < BULB_NB; i++){ //iterate through the bulbs
            
                //defining the position of bulbs in graph
            tempYpos = i*20+20;
            tempXpos = 80;
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
             for (i = 0; i < BULB_NB; i++){ //iterate through the bulbs
                
                    //defining the position of bulbs in graph
                tempYpos = i*20+20;
                tempXpos = 80;
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
            /*  OLD STUFFF
                  for (int i = 0; i < BULB_NB; i++){ //iterate through the bulbs
                  
                      //defining the position of bulbs in graph
                  float tempYpos = i*20+20;
                  float tempXpos = 80;
                  if(i>19){ //change position values to draw two lines
                    tempYpos = (i-20)*20+20;
                    tempXpos = 120;
                  }
                 cm = (a*i)%255;
                 println(a,i,cm, frameRate);
                 bulb = new Bulb(cm,cm,cm, 1, tempXpos, tempYpos, 15);
                 bulb.display();
              } */
              
                   i++; if(i>39){i=0;} 
                      //defining the position of bulbs in graph
                  tempYpos = i*20+20;
                  tempXpos = 80;
                  if(i>19){ //change position values to draw two lines
                    tempYpos = (i-20)*20+20;
                    tempXpos = 120;
                  }
                 //cm = (currentFrame+offset) % numFrames; offset+=2;
                  cm = int(map(a, 0, 40, 0, 255));
                  i = i+1; //velocidad
                  //cm = int(map(i, 0, 40, 0, 255));
                 //cm = (a*40)%255;
                 println(a,i,cm, frameRate);
                 bulb = new Bulb(cm,cm,cm, 1, tempXpos, tempYpos, 15);
                 bulb.display();
              
          break;
          // *** CASE D : Parallel chain progression  ***
          case 'D':
              for (i = 0; i < BULB_NB; i++){ //iterate through the bulbs
                      //defining the position of bulbs in graph
                 tempYpos = i*20+20;
                 tempXpos = 80;
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
            for (i = 0; i < BULB_NB; i++){ //iterate through the bulbs
                        //defining the position of bulbs in graph
                    tempYpos = i*20+20;
                    tempXpos = 80;
                    if(i>19){ //change position values to draw two lines
                      tempYpos = (i-20)*20+20;
                      tempXpos = 120;
                    }
              bulb = new Bulb(0,0,0, 0, tempXpos, tempYpos, 15); 
            }
          break;
          // *** CASE DEFAULT: Sound Amplitude response ***
         default:
          for (i = 0; i < BULB_NB*3; i++){ //iterate through the bulbs
                    
                        //defining the position of bulbs in graph
                    tempYpos = i*20+20;
                    tempXpos = 80;
                    if(i>19){ //change position values to draw two lines
                      tempYpos = (i-20)*20+20;
                      tempXpos = 120;
                    }
           
           int dc = int(map(int(dB(fft1.getFreq(i))), 0, 15, 0, 255)); // Modifies the color with sound amplitude
           bulb = new Bulb(dc,dc,dc, 1, tempXpos, tempYpos, 15);
           bulb.display();
           //println(dB(fft1.getFreq(i)), " - ", dB(fft2.getFreq(i)));
           //dmxOutput.set(i,dc);
           println(dc, dB(fft1.getFreq(i)));
          // println("rms1: ",int(map(in.left.get(i), 0, 0.5, 0, 255))," - rms2: ",int(map(in.right.get(i), 0, 0.5, 0, 255)));
           
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
float dB(float x) {
  if (x == 0) {
    return 0;
  }
  else if (x < 0) {
    return 0;
  }
  else {
    return 10 * (float)Math.log10(x);
  }
}
void objectIdentif(int i, float sum){
  // Identifiying objects
    if(i > 10 && i < 15){ // PEOPLE TALKING (sometimes can't sepate other noise)
      if(sum*height*scale > 3 && sum*height*scale < 10) println("people talking");//println(i, sum[i]*height*scale);
    }
    if(i > 0 && i < 5){ // BUS ENGINE
      if(sum*height*scale > 25 && sum*height*scale < 30) {println("bus engine");}
      else if(sum*height*scale > 30 && sum*height*scale < 40) {println("bus engine");}
      else if (sum*height*scale > 40){println("TOO loud bus engine"); }
    }
    if(i > 30 && i < 35){ // TRAM BIP
      if(sum*height*scale > 3 && sum*height*scale < 10) println("TRAM BIP");//println(i, sum[i]*height*scale);
    }
    if(i > 145 && i < 155){ // BUs STOPping
      if(sum*height*scale > 10 && sum*height*scale < 15) println("STOPPING"); 
      //println(i, sum*height*scale);
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