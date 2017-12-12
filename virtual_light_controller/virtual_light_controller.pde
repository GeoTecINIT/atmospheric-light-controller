// this sketch draws the bulb and change color when sound amplitud changes

import oscP5.*;
import netP5.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
Minim minim;
AudioInput in;
FFT fft1, fft2;
AudioPlayer song;
boolean soundIn = true;
/** SOUND VARIABLES **/

float[] peaks1, peaks2;  //acumulates the peak of each band
int peak_hold_time = 10;  // how long before peak decays
int[] peak_age1, peak_age2;  // tracks how long peak has been stable, before decaying

// how wide each 'peak' band is, in fft bins
int binsperband = 10;
int peaksize1, peaksize2; // how many individual peak buffer_size we have (dep. binsperband)
float gain = 40; // in dB
float dB_scale = 2.0;  // pixels per dB

int buffer_size = 1024;  // also sets FFT size (frequency resolution)
float sample_rate = 44100;

int spectrum_height = 200; // determines range of dB shown
int legend_height = 0;
int spectrum_width = 480; // determines how much of spectrum we see
int legend_width = 0;

int engineCalc = 0; // calculates the noise of a motor engine
boolean engineNoise = false; //active if it there is an engine noise
boolean windNoise = false; //active if it there is a wind noise
int avgAmplitude1, avgAmplitude2; // stores average amplitude for each mic

/** Lights and server variables **/
OscP5 oscP5;
NetAddress nodejsServer;
char receivedString; // string received by osc/node server
char chosenOption;  // the mode chosen by user
char chosenSpeed; // the speed choiced (only in background, changes timeframe, not the delay on animation
int a = 0; // used to increase color to 255 (not in use)
int cm; // ColorMode used to send independent color to lights
int i; //for iteration
float tempYpos; // position to draw lights
float tempXpos; // position to draw lights

// DMX Libraries and variables
import dmxP512.*;
import processing.serial.*;
DmxP512 dmxOutput;
int universeSize=120; // universe (lights per RGB chanels)
boolean DMXPRO=true;
String DMXPRO_PORT=Serial.list()[1];//case matters ! on windows port must be upper cased.
int DMXPRO_BAUDRATE=115000;

/* GENERAL VARIABLES */
int ia = 0; //used for modify lights sequence varies by mode
int spd = 1; // used for speed by adding delay on sending signal to DMX
Animation gif; // animated GIF class
int countFrames = 0; //animated GIF current frame
int imageFrames = 41; //animated GIF amount of frames (rest 1 to calculous)

int numFrames = 255;  // The number of frames in the animation
int currentFrame = 0; // to store framerate (related to chosenSpeed
int BULB_NB = 40; // Quantity of bulbs
Bulb bulb;  //bulb class
int[] list = new int[BULB_NB]; //creates a list of bulbs to access
int[] rlist = new int[BULB_NB]; //creates an inversed list of bulbs

void setup(){
  size(200, 480, P3D);
  background(0);
  noStroke();
  frameRate(30);
  
  /* Start DMX */
  if(DMXPRO){dmxOutput=new DmxP512(this,universeSize,true);
  dmxOutput.setupDmxPro(DMXPRO_PORT);}
  
  /* start oscP5, listening for incoming messages at port 3333 */
  oscP5 = new OscP5(this,3333);
  
  /* myRemoteLocation is a NetAddress. a NetAddress takes 2 parameters,
   * an ip address and a port number. myRemoteLocation is used as parameter in
   * oscP5.send() when sending osc packets to another computer, device, 
   * application. usage see below. for testing purposes the listening port
   * and the port of the remote location address are the same, hence you will
   * send messages back to this sketch.
   */
   nodejsServer = new NetAddress("127.0.0.1",3334);
  
   /* Start Minim SOUND ANAL */

     // Create the Input stream
  minim = new Minim(this);
  
  // this loads mysong.wav from the data folder
  if(soundIn){
    in = minim.getLineIn(Minim.STEREO, buffer_size, 44000);
  in.enableMonitoring();
  fft1 = new FFT(in.bufferSize(), in.sampleRate());
  fft2 = new FFT(in.bufferSize(), in.sampleRate());
  }else{
  song = minim.loadFile("../sound-analysis/data/dic17_bus.aiff");
  song.loop();
  fft1 = new FFT(song.bufferSize(), song.sampleRate());
  fft2 = new FFT(song.bufferSize(), song.sampleRate());
  }
   
  //fft1.logAverages(10, buffer_size);
  //fft2.logAverages(10, buffer_size);
  
  fft1.window(FFT.HAMMING);
  fft2.window(FFT.HAMMING);
  // initialize peak-hold structures
  peaksize1 = 1+Math.round(fft1.specSize()/binsperband);
  peaks1 = new float[peaksize1];
  peak_age1 = new int[peaksize1];
  
  peaksize2 = 1+Math.round(fft2.specSize()/binsperband);
  peaks2 = new float[peaksize2];
  peak_age2 = new int[peaksize2];
  
  /* GIF Processing */
  gif = new Animation("frames/", imageFrames); //recovers the animated GIF

  
  // push bulbs to list
  for (i = 0; i < BULB_NB; i++){
    list[i] = i;
  }
  rlist =reverse(list); //reverses the list
  
}

void draw() { 
    background(0,0,0);
    // ****
    // AUDIO ANALYSIS
    // ****
    
    if(soundIn){ fft1.forward(in.left); fft2.forward(in.right);}
    else{ fft1.forward(song.left); fft2.forward(song.right);}
    engineCalc = int((peaks1[2]+peaks1[3]+peaks1[4])/3);
    
    if( engineCalc > 45) { engineNoise = true; text("engine db: "+ engineCalc, 20, 465);}else{ engineNoise = false;}
    if((peaks1[40]+peaks1[50]+peaks1[peaksize1-1])/3 > 5) { windNoise = true; text("windy", 20, 465);}else{ windNoise = false;} 
    avgAmplitude1 = calcAmplitude(peaks1);
    avgAmplitude2 = calcAmplitude(peaks2);
    drawSpecto(peaks1, peaksize1, peak_age1, fft1);
    drawSpecto(peaks2, peaksize2, peak_age2, fft2); 
    
    
     // ****
    // LIGHT BEHAVIOUR
    // ****
    text("av1: "+avgAmplitude1, 20, 400); text("av2: "+avgAmplitude2, 80, 400);  // prints each amplitude
    //a++; if(a>255){a=0;} // A is going trough color spectrum
    currentFrame = (currentFrame+1) % numFrames;  // Use % to cycle through frames
         switch(chosenOption){
            // *** CASE A  ***  maps light to amplitude each line 
        case 'A': 
                color from = color(0, 0, 255);
                color to = color(255, 0, 0);
                color theCol = color(0,0,0);
                int am = int(map(avgAmplitude1, 35, 60, 0, BULB_NB/2-1));
                
                for (i = 0; i < BULB_NB/2; i++){
                  theCol = color(0,0,0);
                    if(i < am){ //col = 255;
                     float tocol = map(i, 0 , BULB_NB/2, 0.0 , 1.0); //determines the color for the lerp
                      theCol = lerpColor(from, to, tocol);
                     }
                   setDMX(i,int(red(theCol)),int(green(theCol)),int(blue(theCol)));
                   int gifi = i;
                   if(i > BULB_NB/2-2){gifi = rlist[i];} //inverse the position of pixel
                        tempYpos = gifi*20+20;
                        tempXpos = 80;
                        if(i>19){ //change position values to draw two lines
                          tempXpos = 120;
                        }
                   bulb = new Bulb(int(red(theCol)),int(green(theCol)),int(blue(theCol)), 1, tempXpos, tempYpos, 15);
                   bulb.display();
                }
                int am2 = int(map(avgAmplitude2, 35, 70, BULB_NB-1, BULB_NB/2-1)); // La segunda linea va invertida (para atras)
                for (i = BULB_NB-1; i > BULB_NB/2-1; i--){
                 from = color(0, 255, 0);
                 theCol = color(0,0,0);
                    if(i > am2){ //col = 255;
                     float tocol = map(i, BULB_NB, BULB_NB/2, 0.0 , 1.0); //determines the color for the lerp
                      theCol = lerpColor(from, to, tocol);
                     }
                   setDMX(i,int(red(theCol)),int(green(theCol)),int(blue(theCol)));
                   tempYpos = (i-BULB_NB/2)*20+20;
                   tempXpos = 120;
                   bulb = new Bulb(int(red(theCol)),int(green(theCol)),int(blue(theCol)), 1, tempXpos, tempYpos, 15);
                   bulb.display();
                }
          break;
           // *** CASE B  //  heart-beat ***
         case 'B':
             /* colors from blue to red */
              if(ia > 4)ia = 0;
             spd=300; 
             //spd = (int(map(avgAmplitude2, 0, 50, 400, 100)) + int(map(avgAmplitude1, 30, 80, 40, 300)))/2; //modifies speed regarding amplitude
             spd = int(map(engineCalc, 10, 50, 300, 50));
             if(spd < 50){ spd=50; }else if(spd>300){spd=300;}
             float iatoa = map(ia,0,4,0.2,1.0);
             for (i = 0; i < BULB_NB; i++){
               int gifi = i;
               if(i > BULB_NB/2-2){gifi = rlist[i];} //inverse the position of pixel
                    tempYpos = gifi*20+20;
                    tempXpos = 80;
                    if(i>19){ //change position values to draw two lines
                      tempXpos = 120;
                    }
               int dm = int(map(engineCalc, 10, 60, 1, 255)); 
               dm = int(dm*iatoa);
               if(dm>255){dm=255;}else if(dm<1){dm=1;}
               int dm2 = int(map(engineCalc, 20, 60, 255, 1)); 
               dm2 = int(dm2*iatoa);
               if(dm2>255){dm2=255;}else if(dm2<1){dm2=1;}
               setDMX(i,dm,0,dm2);
               //println(dm,dm2,spd);
                bulb = new Bulb(dm,0,dm2, 1, tempXpos, tempYpos, 15);
                bulb.display();
             }
             delay(spd); //modifies the speed
             ia++;

          break;
          // *** CASE C : animated GIF ***
          case 'C':
              
              spd = 1; spd = int(map((avgAmplitude1+avgAmplitude2)/2, 20, 55, 1, 15)); //modifies speed regarding amplitude
             if(spd < 1){ spd=1; }
             if(spd>15){spd=15;}
            for (int i = 0; i < BULB_NB; i++){
                int gifi = i; 
                delay(spd); 
                if(i > BULB_NB/2-2){gifi = rlist[i];} //inverse the position of pixel
                int gifpc = gif.getImagePixelsxF(countFrames)[gifi]; //gets the pixel of the image
                   tempYpos = gifi*20+20;
                    tempXpos = 80;
                    if(i>19){ //change position values to draw two lines
                      tempXpos = 120;
                    }
                setDMX(i,int(red(gifpc)),int(green(gifpc)),int(blue(gifpc)));
                bulb = new Bulb(int(red(gifpc)),int(green(gifpc)),int(blue(gifpc)), 1, tempXpos, tempYpos, 15);
                bulb.display(); 
              }
              fill(255,255,255);
              text("speed: "+spd, 130.0, 400.0);
              countFrames++; if(countFrames > imageFrames-1){countFrames = 0;}
          break;
          // *** CASE D : snake mode  ***
          case 'D':
              // Circular light
             if(ia == BULB_NB){ia = 0;}
             spd = 1; spd = int(map((avgAmplitude1+avgAmplitude2)/2, 30, 60, 300, 1)); //modifies speed regarding amplitude
             if(spd < 1){ spd=1; }
             if(spd>300){spd=300;}
             float tocol= map((avgAmplitude1+avgAmplitude2)/2, 25, 60, 0.0, 1.0);
             int spdcol = lerpColor(color(0, 128, 105), color(255,10,5), tocol);
             int spdcol1 = lerpColor(color(0, 98, 75), color(155,5,0), tocol);
             int spdcol2 = lerpColor(color(0, 68, 45), color(55,0,0), tocol);
             for (i = 0; i < BULB_NB; i++){
              tempYpos = i*20+20;
                    tempXpos = 80;
                    if(i>19){ //change position values to draw two lines
                      tempYpos = (i-20)*20+20;
                      tempXpos = 120;
                    }
               if(i == ia){
                 bulb = new Bulb(int(red(spdcol)),int(green(spdcol)),int(blue(spdcol)), 1, tempXpos, tempYpos, 15);
                 setDMX(i,int(red(spdcol)),int(green(spdcol)),int(blue(spdcol)));
               }else if(i == ia-1){
                 bulb = new Bulb(int(red(spdcol1)),int(green(spdcol1)),int(blue(spdcol1)), 1, tempXpos, tempYpos, 15);
                 setDMX(i,int(red(spdcol1)),int(green(spdcol1)),int(blue(spdcol1)));
               }else if(i == ia-2){
                 bulb = new Bulb(int(red(spdcol2)),int(green(spdcol2)),int(blue(spdcol2)), 1, tempXpos, tempYpos, 15);
                 setDMX(i,int(red(spdcol2)),int(green(spdcol2)),int(blue(spdcol2)));
               }
               else{
                 bulb = new Bulb(0,0,0, 1, tempXpos, tempYpos, 15);
                 setDMX(i,0,0,0);
               }
               bulb.display();
             }
             //println(spd, a, avgAmplitude1+avgAmplitude2, spdcol, spdcol1, spdcol2);
             delay(spd); //modifies the speed
             ia++; 
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
              bulb.display();
              setDMX(i,0,0,0);
            }
          break;
          // *** CASE Z: LIGHTS WHITE ***
          case 'Z':
            for (i = 0; i < BULB_NB; i++){ //iterate through the bulbs
                        //defining the position of bulbs in graph
                    tempYpos = i*20+20;
                    tempXpos = 80;
                    if(i>19){ //change position values to draw two lines
                      tempYpos = (i-20)*20+20;
                      tempXpos = 120;
                    }
              bulb = new Bulb(255,255,255, 0, tempXpos, tempYpos, 15); 
              bulb.display();
              setDMX(i,255,255,255);
            }
            
            
          break;
          // *** CASE DEFAULT: Sound Amplitude response ***
         default:
          for (i = 0; i < BULB_NB; i++){ //iterate through the bulbs
                    
                        //defining the position of bulbs in graph
                    tempYpos = i*20+20;
                    tempXpos = 80;
                    if(i>19){ //change position values to draw two lines
                      tempYpos = (i-20)*20+20;
                      tempXpos = 120;
                    }
           int dc = int(map((avgAmplitude1+avgAmplitude2)/2, 20, 70, 0, 255)); // Modifies the color with sound amplitude
           bulb = new Bulb(dc,dc,dc, 1, tempXpos, tempYpos, 15);
           bulb.display();
           if(dc > 255){dc = 255;}
           if(dc < 3){dc = 3;}
           setDMX(i,dc,dc,dc);
           dmxOutput.set(i,dc); //for some reason this should be here (DMX doesnt work otherwise)
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
void resetLights(){
  for (i = 0; i < BULB_NB; i++){ setDMX(i,255,255,255);  setDMX(i,0,0,0); }
  delay(50);
}
// for changing modes manually
void keyPressed() {
  if (key == 'a' || key == 'A') {
   println("Key pressed: option A\n");
   resetLights();
   chosenOption = 'A';
  } else if (key == 'b' || key == 'B') {
    println("Key pressed: option B\n");
    resetLights();
    chosenOption = 'B';
  } else if (key == 'c' || key == 'C') {
    println("Key pressed: option C\n");
    resetLights();
    chosenOption = 'C';
  }else if (key == 'd' || key == 'D') {
    println("Key pressed: option D\n");
    resetLights();
    chosenOption = 'D';
  }else if (key == 'e' || key == 'E') {
    println("Key pressed: option E\n");
    resetLights();
    chosenOption = 'E';
  }else if (key == 'x' || key == 'X') {
    println("Key pressed: option X\n");
    chosenOption = 'X';
  }else if (key == 'z' || key == 'Z') {
    println("Key pressed: option Z\n");
    chosenOption = 'Z';
  }else if (key == 'n' || key == 'N') {
    println("option set to empty\n");
    resetLights();
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
  }else if (key == '8') {
    print("Key pressed: Speed 8\n");
    chosenSpeed = '8';
    frameRate(150);
  }else if (key == '9') {
    print("Key pressed: Speed 9\n");
    chosenSpeed = '9';
    frameRate(230);
  }else if (key == '0') {
    print("option set to stop\n");
    chosenSpeed = '0';
  }
}

int[] mapDMX(int bulb){  
 if(bulb==0){ int[] r = {1,2,3}; return r; }
 else if(bulb==1){ int[] r = {4,5,6}; return r; }
 else if(bulb==2){ int[] r = {7,8,9}; return r; }  
 else if(bulb==3){ int[] r = {10,11,12}; return r; }  
 else if(bulb==4){ int[] r = {13,14,15}; return r; }  
 else if(bulb==5){ int[] r = {16,17,18}; return r; } 
 else if(bulb==6){ int[] r = {19,20,21}; return r; }
 else if(bulb==7){ int[] r = {22,23,24}; return r; }  
 else if(bulb==8){ int[] r = {25,26,27}; return r; }  
 else if(bulb==9){ int[] r = {28,29,30}; return r; }  
 else if(bulb==10){ int[] r = {31,32,33}; return r; } 
 else if(bulb==11){ int[] r = {34,35,36}; return r; }
 else if(bulb==12){ int[] r = {37,38,39}; return r; }  
 else if(bulb==13){ int[] r = {40,41,42}; return r; }  
 else if(bulb==14){ int[] r = {43,44,45}; return r; }  
 else if(bulb==15){ int[] r = {46,47,48}; return r; } 
 else if(bulb==16){ int[] r = {49,50,51}; return r; }
 else if(bulb==17){ int[] r = {52,53,54}; return r; }  
 else if(bulb==18){ int[] r = {55,56,57}; return r; }  
 else if(bulb==19){ int[] r = {58,59,60}; return r; }  
 else if(bulb==20){ int[] r = {61,62,63}; return r; }
 else if(bulb==21){ int[] r = {64,65,66}; return r; }
 else if(bulb==22){ int[] r = {67,68,69}; return r; }  
 else if(bulb==23){ int[] r = {70,71,72}; return r; }  
 else if(bulb==24){ int[] r = {73,74,75}; return r; }  
 else if(bulb==25){ int[] r = {76,77,78}; return r; } 
 else if(bulb==26){ int[] r = {79,80,81}; return r; }
 else if(bulb==27){ int[] r = {82,83,84}; return r; }  
 else if(bulb==28){ int[] r = {85,86,87}; return r; }  
 else if(bulb==29){ int[] r = {88,89,90}; return r; }  
 else if(bulb==30){ int[] r = {91,92,93}; return r; } 
 else if(bulb==31){ int[] r = {94,95,96}; return r; }
 else if(bulb==32){ int[] r = {97,98,99}; return r; }  
 else if(bulb==33){ int[] r = {100,101,102}; return r; }  
 else if(bulb==34){ int[] r = {103,104,105}; return r; }  
 else if(bulb==35){ int[] r = {106,107,108}; return r; } 
 else if(bulb==36){ int[] r = {109,110,111}; return r; }
 else if(bulb==37){ int[] r = {112,113,114}; return r; }  
 else if(bulb==38){ int[] r = {115,116,117}; return r; }  
 else if(bulb==39){ int[] r = {118,119,120}; return r; }  
 else {int[] r = {0,0,0}; return r;}
}
void setDMX(int bulb, int val1, int val2, int val3){
     if(DMXPRO){
       dmxOutput.set(mapDMX(bulb)[0],val1); 
       dmxOutput.set(mapDMX(bulb)[1],val2); 
       dmxOutput.set(mapDMX(bulb)[2],val3);
     }
}
int calcAmplitude(float[] peaks){
  int tempAmplitude = 0;int avgSize = 0;
    for(int i = 0; i < 20; ++i){
      tempAmplitude += peaks[i];
      avgSize+=1;
    }
    float amplitude = tempAmplitude/avgSize;
    return int(amplitude);
}
void drawSpecto(float[] peaks, int peaksize, int[] peak_age, FFT fft){
  noStroke();
    fill(0, 128, 144); // dim cyan
    
    for(int i = 0; i < peaksize; ++i) { 
    int thisy = spectrum_height - Math.round(peaks[i]);
    if(peaks[i]> 0.0){ 
      objectIdentif(i, peaks);
//      spectColors(peaks[i], i);
    }
//      rect(legend_width+binsperband*i, thisy, binsperband, spectrum_height-thisy);
      // update decays
     if (peak_age[i] < peak_hold_time) {
        ++peak_age[i];
      } else {
        peaks[i] -= 1.0;
        if (peaks[i] < 0) { peaks[i] = 0; }
      }
    }
    stroke(64,192,255);
    noFill();
    for(int i = 0; i < spectrum_width; i++)  {
      // draw the line for frequency band i using dB scale
      float val = dB_scale*(20*((float)Math.log10(fft.getBand(i))) + gain);
      if (fft.getBand(i) == 0) {   val = -200;   }  // avoid log(0)
//      int y = spectrum_height - Math.round(val);
//      if (y > spectrum_height) { y = spectrum_height; }
//      line(legend_width+i, spectrum_height, legend_width+i, y);
      // update the peak record
      // which peak bin are we in?
      int peaksi = i/binsperband;
      if (val > peaks[peaksi]) {
        peaks[peaksi] = val;
        // reset peak age counter
        peak_age[peaksi] = 0;
      }
    }
}
void objectIdentif(int i, float peaks[]){ // detects objects in sounds
  // Identifiying objects
    if(i > 10 && i < 15){ // PEOPLE TALKING (sometimes can't sepate other noise)
      if(engineNoise == false && windNoise == false  && peaks[i] > 10 && peaks[i] < 35) {text("people talking", 20, 450);}
      if(windNoise == true && peaks[i] > 15 && peaks[i] < 35) {text("people talking", 20, 450);}
      if(engineNoise == true && peaks[i] > 35) {text("people talking", 20, 450);}
    }
    if(i > 1 && i < 5){ // BUS ENGINE
      if(peaks[i] > 40 && peaks[i] < 55) {text("bus engine", 20, 450);}
      else if(peaks[i] > 55 && peaks[i] < 65) {text("bus engine", 20, 450);}
      else if (peaks[i] > 65){text("TOO loud bus engine", 20, 450); } 
    }
    if(i > 8 && i < 10){ // TRAM BIP
     if(peaks[i] > 40 && peaks[i] < 40) text("TRAM BIP", 20, 450);//println(i, sum[i]*height*scale);
    }
    if(i > 9 && i < 13){ // BUs STOPping
      if(peaks[i] > 50) text("STOPPING"+ i + peaks[i], 20, 450); 
      //println(i, sum*height*scale);
    }
}
void spectColors(float fft, int i){ // separate bands in buffer and draw in colors
   // Defining colors of spectrum bars
    if(i < 1){ fill(255,255,255);}
    else if(i > 1 && i < 5){ // split each of the buffer_size
    fill(250,250,250);
      if(fft > 40){ fill(250,250,0); }
    }else if(i > 5 && i < 10){
      fill(200,200,200);
      if(fft > 25){ fill(200,200,0); }
    }
    else if(i > 10 && i < 20){
      fill(150,150,150);
     // println(nf(fft.spectrum[i], 1, 3));
      if(fft > 15){ fill(150,150,0); }
    }else if(i > 20 && i < 30){
      fill(100,100,100);
      if(fft > 15){ fill(100,100,0); }
    }
    else if(i > 30 && i < 50){
      fill(50,50,50);
      if(fft > 15){ fill(50,50,0); }
    }
    else if(i > 50){
      fill(10,10,10);
      if(fft > 15){ fill(10,10,0); }
    }
    if(fft > 65){ // if buffer_size surpasses a threshold
      fill(255,0,0);
    }
}
class Animation {
  PImage[] images;
  int imageCount;
  int frame;
  
  Animation(String imagePrefix, int count) {
    imageCount = count;
    images = new PImage[imageCount];

    for (int i = 0; i < imageCount; i++) {
      // Use nf() to number format 'i' into four digits
      String filename = imagePrefix + nf(i, 2) + ".gif";
      images[i] = loadImage(filename);
    }
  }

  void getImage(float xpos, float ypos) {
    frame = (frame+1) % imageCount;
    image(images[frame], xpos, ypos);
  }
   int[] getImagePixels() {
    frame = (frame+1) % imageCount;
    images[frame].resize(2,20);
    return images[frame].pixels;
  }
  int[] getImagePixelsxF(int frame) {
    image(images[frame], 10.0,10.0);
    images[frame].resize(2,20);
    return images[frame].pixels;
  }
  int getWidth() {
    return images[0].width;
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
void stop()
{
  // always close Minim audio classes when you finish with them
  in.close();
  minim.stop();
  super.stop();
  dmxOutput.reset();
}