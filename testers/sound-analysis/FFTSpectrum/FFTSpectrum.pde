// This sketch shows how to use the FFT class to analyze a stream  
// of sound. Change the variable bands to get more or less 
// spectral bands to work with. Smooth_factor determines how
// much the signal will be smoothed on a scale form 0-1.

import processing.sound.*;

// Declare the processing sound variables 
SoundFile sample;
FFT fft1, fft2;
AudioDevice device;
AudioIn in1, in2;
HighPass highPass;
BandPass bandPass;

// Declare a scaling factor
int scale=5;

// Define how many FFT bands we want
int bands = 256;

// declare a drawing variable for calculating rect width
float r_width;

// Create a smoothing vector
float[] sum1 = new float[bands];
float[] sum2 = new float[bands];

// Create a smoothing factor
float smooth_factor = 0.2;

public void setup() {
  size(640, 360);
  background(255);
  
  // If the Buffersize is larger than the FFT Size, the FFT will fail
  // so we set Buffersize equal to bands
  device = new AudioDevice(this, 44000, bands);
  
  // Calculate the width of the rects depending on how many bands we have
  r_width = width/float(bands);
  
  //Load and play a soundfile and loop it. This has to be called 
  // before the FFT is created.
  // ** WITH AUDIO INPUTS **
  in1 = new AudioIn(this, 0);
  in1.start();
  // ** WITH SAMPLES **
  sample = new SoundFile(this, "bus2.aiff");
  sample.loop();

  // FILTERS **
  highPass = new HighPass(this);
  highPass.process(in1, 100);
  
  /*  bandPass = new BandPass(this);
  bandPass.process(sample, 0, 30); */
  
  // Create and patch the FFT analyzer
  fft1 = new FFT(this, bands);
  fft1.input(highPass); // <--- Change for sample or in (or filtered band)
  fft2 = new FFT(this, bands);
  fft2.input(sample);

}      

public void draw() {
  // Set background color, noStroke and fill color
  background(125,255,125);
  fill(255,0,150);
  noStroke();
  
  fft1.analyze();

  for (int i = 0; i < bands; i++) {
    // smooth the FFT data by smoothing factor
    sum1[i] += (fft1.spectrum[i] - sum1[i]) * smooth_factor;
    sum2[i] += (fft2.spectrum[i] - sum2[i]) * smooth_factor;
    
    // Identifiying objects
    if(i > 10 && i < 15){ // PEOPLE TALKING (sometimes can't sepate other noise)
      if(sum1[i]*height*scale > 3 && sum1[i]*height*scale < 10) println("people talking");//println(i, sum[i]*height*scale);
    }
    if(i > 0 && i < 5){ // BUS ENGINE
      if(sum1[i]*height*scale > 25 && sum1[i]*height*scale < 30) {println("bus engine");}
      else if(sum1[i]*height*scale > 30 && sum1[i]*height*scale < 40) {println("bus engine");}
      else if (sum1[i]*height*scale > 40){println("TOO loud bus engine"); }
    }
    if(i > 30 && i < 35){ // TRAM BIP
      if(sum1[i]*height*scale > 3 && sum1[i]*height*scale < 10) println("TRAM BIP");//println(i, sum[i]*height*scale);
    }
    if(i > 145 && i < 155){ // BUs STOPping
      if(sum1[i]*height*scale > 10 && sum1[i]*height*scale < 15) println("STOPPING"); 
      //println(i, sum[i]*height*scale);
    }
    
    
    // Defining colors of spectrum
    if(i < 30){ // split each of the bands
      if(fft1.spectrum[i] > 0.3){ fill(0,0,0); }
    }if(i > 30 && i < 80){
      fill(150,255,255);
      //println(nf(fft.spectrum[i], 1, 3));
      if(fft1.spectrum[i] > 0.02){ fill(0,0,0); }
    }
    else if(i < 150 && i > 79){
      fill(255,255,150);
     // println(nf(fft.spectrum[i], 1, 3));
      if(fft1.spectrum[i] > 0.02){ fill(0,0,0); }
    }else if(i > 149){
      fill(255,255,255);
      if(fft1.spectrum[i] > 0.02){ fill(0,0,0); }
    }
    if(-sum1[i]*height*scale < -280){ // if bands surpasses a threshold
      fill(255,255,0);
    }
    // draw the rects with a scale factor
    rect( i*r_width, height, r_width, -sum1[i]*height*scale );
    rect( i*r_width, height, r_width, -sum2[i]*height*scale );
  }
}