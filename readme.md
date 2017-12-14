# Atmospheric Light Controller (ALC)

For now is just an Beta version on first Processing programming. 

## Contents
- Light Controller and sound analysis (processing) at /virtual_light_controller
- Web interface (nodejs) at /webserver
- The folder "tester" contains different parts of the software used to test connections or analysis


## Usage
### Dependencies
* NodeJS
	* express
	* crypto
	* socket.io
	* node-schedule
	* body-parser
	* node-osc
	* client-sessions
* MongoDB
* Processing 3
	* oscP5
	* netP5
	* minim
	* dmxP512
 

### Installation

1. Install nodejs server
`cd /webserver`  
`npm install` 

2. Create MongoDB collections
 - Database: atmospheric-light-controller
 - Collection: logs, vals, energysaver

### Launching

3. Connect to mongo (in new Terminal)
`sudo mongod`

4. Launch node server
`cd /webserver
sudo node server.js`

5. Launch Processing sketch
`/virtual_light_controller/virtual_light_controller.pde`

## Programming Light Modes

Inside the sketch (around line 160) you will find the Light Behaviour part. Each of the Cases are activated through the web platform. 
For designing lightbulb interactions, you can change one of each modes. 

These software was made for control two strings of 20 lights that are connected by DMX in a linear setup. 
The class Bulb is to draw bulbs in the app
The function setDMX is for sending signals to each bulb. 
The Class Animation is made to map animated GIFs to each bulb. (those would be for 2x20px images that can be stored in the "frames" folder).

### Sound Analysis
Using Minim, we create an average amplitude analysis for two inputs (could be stereo mics or two separate inputs). The avgAmplitude1 and avgAmplitude2 will return a balanced stream of each inputs. 

---
This work was made by [Manuel Portela](http://manuchis.net/). Thanks to the collaboration of Carlos Granell-Canut and Cristian Reynaga. 

This research is held in the frame of the GEO-C (http://geo-c.eu) project regarding the ESR15: Situational Awareness-as-a-service and the GeoTec (http://geotec.uji.es) research department at UJI.
GEO-C is funded by the European Commission within the Marie Skłodowska-Curie Actions, International Training Networks (ITN), European Joint Doctorates (EJD). The funding period is January 1, 2015 - December 31, 2018, Grant Agreement number 642332 — GEO-C — H2020-MSCA-ITN-2014.

[![DOI](https://zenodo.org/badge/108422101.svg)](https://zenodo.org/badge/latestdoi/108422101)