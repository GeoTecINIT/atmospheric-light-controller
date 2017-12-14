
import ddf.minim.*;
import ddf.minim.analysis.*;
Minim minim;
AudioInput in;
FFT fft1, fft2;
AudioPlayer song;

/*
// Audio imports and Variables
// Define how many FFT buffer_size we want
int buffer_size = 1024;

/*AudioDevice device;
AudioIn in1, in2;
HighPass highPass;
Amplitude rms1, rms2;

// Declare a scaling factor
int scale=10;

// declare a drawing variable for calculating rect width
float r_width;
// Create a smoothing vector
float[] sum1 = new float[buffer_size];
float[] sum2 = new float[buffer_size];
// Create a smoothing factor
float smooth_factor = 0.2;

*/


/** SOUND VARIABLES **/

float[] peaks;
int peak_hold_time = 10;  // how long before peak decays
int[] peak_age;  // tracks how long peak has been stable, before decaying

// how wide each 'peak' band is, in fft bins
int binsperband = 10;
int peaksize; // how many individual peak buffer_size we have (dep. binsperband)
float gain = 40; // in dB
float dB_scale = 2.0;  // pixels per dB

int buffer_size = 1024;  // also sets FFT size (frequency resolution)
float sample_rate = 44100;

int spectrum_height = 200; // determines range of dB shown
int legend_height = 20;
int spectrum_width = 512; // determines how much of spectrum we see
int legend_width = 40;

boolean engineNoise = false;
boolean windNoise = false;
/** **/
void setup(){
  size(552, 220, P3D);
  textFont(createFont("SanSerif", 12));
  background(0);
  noStroke();
  frameRate(30);
 
   
  // Create the Input stream
  minim = new Minim(this);
  
  // this loads mysong.wav from the data folder
  song = minim.loadFile("../data/dic17_motor2.aiff");
  song.loop();
  /*
  in = minim.getLineIn(Minim.STEREO, buffer_size, 44000);
  in.enableMonitoring();
   */   
  
  fft1 = new FFT(song.bufferSize(), song.sampleRate());
  fft2 = new FFT(song.bufferSize(), song.sampleRate());
  
  //fft1.logAverages(10, buffer_size);
  //fft2.logAverages(10, buffer_size);
  
  fft1.window(FFT.HAMMING);
  fft2.window(FFT.HAMMING);
  // initialize peak-hold structures
  peaksize = 1+Math.round(fft1.specSize()/binsperband);
  peaks = new float[peaksize];
  peak_age = new int[peaksize];
}

void draw() { 
    background(0);
    // ****
    // AUDIO ANALYSIS
    // ****
    
    fft1.forward(song.left);
    fft2.forward(song.right);
     
    noStroke();
    fill(0, 128, 144); // dim cyan
    int calc = int((peaks[2]+peaks[3]+peaks[4])/3);
    if( calc > 45) { engineNoise = true; println("engine db: ", calc);}else{ engineNoise = false;}
    if((peaks[40]+peaks[50]+peaks[peaksize-1])/3 > 5) { windNoise = true; println("windy");}else{ windNoise = false;}
    for(int i = 0; i < peaksize; ++i) { 
    int thisy = spectrum_height - Math.round(peaks[i]);
    if(peaks[i]> 0.0){ 
     // println(i, peaks[i]);
      objectIdentif(i, peaks);
      spectColors(peaks[i], i);
    }
    rect(legend_width+binsperband*i, thisy, binsperband, spectrum_height-thisy);
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
    float val = dB_scale*(20*((float)Math.log10(fft1.getBand(i))) + gain);
    if (fft1.getBand(i) == 0) {   val = -200;   }  // avoid log(0)
    int y = spectrum_height - Math.round(val);
    if (y > spectrum_height) { y = spectrum_height; }
    line(legend_width+i, spectrum_height, legend_width+i, y);
    // update the peak record
    // which peak bin are we in?
    int peaksi = i/binsperband;
    if (val > peaks[peaksi]) {
      peaks[peaksi] = val;
      // reset peak age counter
      peak_age[peaksi] = 0;
    }
  }
  
  // add legend
  // frequency axis
  fill(255);
  stroke(255);
  int y = spectrum_height;
  line(legend_width,y,legend_width+spectrum_width,y); // horizontal line
  // x,y address of text is immediately to the left of the middle of the letters 
  textAlign(CENTER,TOP);
  for (float freq = 0.0; freq < song.sampleRate()/2; freq += 2000.0) {
    int x = legend_width+fft1.freqToIndex(freq); // which bin holds this frequency
    line(x,y,x,y+4); // tick mark
    text(Math.round(freq/1000) +"kHz", x, y+5); // add text label
  }
  
  // level axis
  int x = legend_width;
  line(x,0,x,spectrum_height); // vertictal line
  textAlign(RIGHT,CENTER);
  for (float level = -100.0; level < 100.0; level += 20.0) {
    y = spectrum_height - (int)(dB_scale * (level+gain));
    line(x,y,x-3,y);
    text((int)level+" dB",x-5,y);
  }
 
}

void objectIdentif(int i, float peaks[]){
  // Identifiying objects
    if(i > 10 && i < 15){ // PEOPLE TALKING (sometimes can't sepate other noise)
      if(engineNoise == false && windNoise == false  && peaks[i] > 10 && peaks[i] < 35) {println("people talking", i, peaks[i]);}
      if(windNoise == true && peaks[i] > 15 && peaks[i] < 35) {println("people talking", i, peaks[i]);}
      if(engineNoise == true && peaks[i] > 35) {println("people talking", i, peaks[i]);}
    }
    if(i > 1 && i < 5){ // BUS ENGINE
     /* if(peaks[i] > 40 && peaks[i] < 55) {println("bus engine", i, peaks[i]);}
      else if(peaks[i] > 55 && peaks[i] < 65) {println("bus engine", i, peaks[i]);}
      else if (peaks[i] > 65){println("TOO loud bus engine", i, peaks[i]); } */
    }
    if(i > 8 && i < 10){ // TRAM BIP
     if(peaks[i] > 40 && peaks[i] < 40) println("TRAM BIP");//println(i, sum[i]*height*scale);
    }
    if(i > 9 && i < 13){ // BUs STOPping
      if(peaks[i] > 50) println("STOPPING", i, peaks[i]); 
      //println(i, sum*height*scale);
    }
}
void spectColors(float fft, int i){
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
void stop()
{
  // always close Minim audio classes when you finish with them
  in.close();
  minim.stop();
  super.stop();
}