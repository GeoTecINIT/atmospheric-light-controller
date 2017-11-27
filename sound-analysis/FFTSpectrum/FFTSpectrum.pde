// This sketch shows how to use the FFT class to analyze a stream  
// of sound. Change the variable bands to get more or less 
// spectral bands to work with. Smooth_factor determines how
// much the signal will be smoothed on a scale form 0-1.

import processing.sound.*;

// Declare the processing sound variables 
SoundFile sample;
FFT fft;
AudioDevice device;
AudioIn in;

// Declare a scaling factor
int scale=5;

// Define how many FFT bands we want
int bands = 256;

// declare a drawing variable for calculating rect width
float r_width;

// Create a smoothing vector
float[] sum = new float[bands];

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
  in = new AudioIn(this, 0);
  in.start();
  //sample = new SoundFile(this, "beat.aiff");
  //sample.loop();

  // Create and patch the FFT analyzer
  fft = new FFT(this, bands);
  fft.input(in);
}      

public void draw() {
  // Set background color, noStroke and fill color
  background(125,255,125);
  fill(255,0,150);
  noStroke();

  fft.analyze();

  for (int i = 0; i < bands; i++) {
    // smooth the FFT data by smoothing factor
    sum[i] += (fft.spectrum[i] - sum[i]) * smooth_factor;
    
    if(i < 30){ // split each of the bands
      if(fft.spectrum[i] > 0.3){ fill(0,0,0); }
    }if(i > 30 && i < 80){
      fill(150,255,255);
      //println(nf(fft.spectrum[i], 1, 3));
      if(fft.spectrum[i] > 0.02){ fill(0,0,0); }
    }
    else if(i < 150 && i > 79){
      fill(255,255,150);
     // println(nf(fft.spectrum[i], 1, 3));
      if(fft.spectrum[i] > 0.02){ fill(0,0,0); }
    }else if(i > 149){
      fill(255,255,255);
      if(fft.spectrum[i] > 0.02){ fill(0,0,0); }
    }
    if(-sum[i]*height*scale < -280){ // if bands surpasses a threshold
      fill(255,255,0);
    }
    // draw the rects with a scale factor
    rect( i*r_width, height, r_width, -sum[i]*height*scale );
  }
}