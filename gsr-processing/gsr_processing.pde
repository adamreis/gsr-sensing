// you can copy/paste this code into a new Processing sketch
// Visual source code from: http://www.generative-gestaltung.de/P_2_2_1_01
// GSR source code from: http://cwwang.com/2008/04/13/gsr-reader/

import processing.pdf.*;
import java.util.Calendar;

boolean recordPDF = false;

import processing.serial.*;
Serial myPort; 


int hPosition = 1;    
float currentReading;
float lastReading;
int count=0;
int zeroLinePos=0;

float gsrAverage,prevGsrAverage;
float baseLine=0;
long lastFlatLine=0;
int baselineTimer=10000;//10 sec
int gsrValue;
int gsrZeroCount=0;
float gsrRange=0;
int downhillCount=0;
int uphillCount=0;
boolean downhill;
boolean peaked=false;
float peak, valley;
int speed ;
int NORTH = 0;
int NORTHEAST = 1;
int EAST = 2;
int SOUTHEAST = 3;
int SOUTH = 4;
int SOUTHWEST = 5;
int WEST = 6;
int NORTHWEST= 7;

float stepSize = 1;
float diameter = 1;

int direction;
float posX, posY;
int minCurrentReading = 1000;
int maxCurrentReading = 0;

void setup() {
  size(800, 800);//size of window for image
  background(255);
  smooth();
  noStroke();
  posX = width/2;
  posY = height/2;
  println(Serial.list());
  currentReading=0;
  lastReading=0;
  gsrAverage=0;

//find the right serial port for your computer and enter in the number inside []
  myPort = new Serial(this, Serial.list()[11], 9600);
}

void serialEvent (Serial myPort) {
  int inByte=myPort.read();
  //0-255
  gsrValue=inByte;//taking value sent from Arduino
//  println("gsrValue = " + gsrValue);
}


void draw() {
 
  calculateGSR();
 
//  println("currentReading = " + currentReading);
 
  // map currentReading to speed
  if (currentReading <= 50)
  {
    currentReading = minCurrentReading; 
  } else  if (currentReading > 1000)
  {
    currentReading = maxCurrentReading; 
  }
  else // valid zone
  {
 
  if (currentReading< minCurrentReading)
  {
    minCurrentReading = int( currentReading);
  }
 
   if (currentReading> maxCurrentReading)
  {
    maxCurrentReading = int(currentReading);
  }}
 
//println("currentReading = " +  currentReading + " minCurrentReading = " + minCurrentReading + " maxCurrentReading = " + maxCurrentReading);
   currentReading = map (currentReading, minCurrentReading,maxCurrentReading,10,15000);
   speed = int (currentReading);
  
//  println("mapped value = "+  speed);
    delay(50);//delay for stability
   
//applying the GSR reading to drive the speed of that the organic drawing "grows"
  for (int i=0; i<=speed; i++) {
    direction = (int) random(0, 8);

    if (direction == NORTH) { 
      posY -= stepSize; 
    }
    else if (direction == NORTHEAST) {
      posX += stepSize;
      posY -= stepSize;
    }
    else if (direction == EAST) {
      posX += stepSize;
    }
    else if (direction == SOUTHEAST) {
      posX += stepSize;
      posY += stepSize;
    }
    else if (direction == SOUTH) {
      posY += stepSize;
    }
    else if (direction == SOUTHWEST) {
      posX -= stepSize;
      posY += stepSize;
    }
    else if (direction == WEST) {
      posX -= stepSize;
    }
    else if (direction == NORTHWEST) {
      posX -= stepSize;
      posY -= stepSize;
    }

    if (posX > width) posX = 0;
    if (posX < 0) posX = width;
    if (posY < 0) posY = height;
    if (posY > height) posY = 0;

    fill(0, 40);
    ellipse(posX+stepSize/2, posY+stepSize/2, diameter, diameter);
     //send 'a' for more bytes
  }
}


void calculateGSR () {
  //best delay setting for gsr readings
  //println(gsrValue);
  delay(50);
  //image(myMovie, 0, 0);

  if (gsrValue<15 &&gsrValue>-15){ // anything between -15 and +15 is considered zero
   //if someone lifts fingers off for 10 seconds resulting in 10 0s, just reset

    if( gsrZeroCount>10){
      currentReading=0;//flatline
      gsrAverage=0;
      baseLine=0;
      lastFlatLine=millis();
      gsrZeroCount=0;
      // println("reset");
    }
   
    gsrZeroCount++;
  } // end of test for close to zero
 
  else{ // ggood reading
    currentReading=gsrValue-baseLine;
    println("currentreading: " + currentReading);
    gsrZeroCount=0;
  }

  if(millis()-lastFlatLine>baselineTimer){
    baseLine=gsrAverage;//if we got at least 10 seconds of reading since the last flatline
  }


  gsrRange=peak-valley;



  gsrAverage=smooth(currentReading,.99,gsrAverage);

int thres=7;

  if (currentReading-thres>lastReading && peaked==true){
    downhill=false;
    //println(downhillCount);
    uphillCount++; 
    downhillCount=0;
    point(hPosition-1, height/2.0-lastReading);
    valley=lastReading;
    peaked=false;

  }
  if(currentReading+thres<lastReading && peaked==false){
    //println(uphillCount);
    downhill=true;
    uphillCount=0;
    downhillCount++;
    point(hPosition-1, height/2.0-lastReading);
    peak=lastReading;
    peaked=true;
  }

  prevGsrAverage=gsrAverage;
  lastReading=currentReading;
  //send 'a' for more bytes
  myPort.write('a');
 
}


int smooth(float data, float filterVal, float smoothedVal){
  if (filterVal > 1){      // check to make sure param's are within range
    filterVal = .99;
  }
  else if (filterVal <= 0){
    filterVal = 0;
  }
  smoothedVal = (data * (1 - filterVal)) + (smoothedVal  *  filterVal);
  return (int)smoothedVal;
}

