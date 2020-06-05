//this is the framulator. It loads a video into an arrayList of frames.
//after loading, every frame is acessible by Midi messages (127 per channel)
//by a supercollider code, which is used to sequence the frames in any
//desired way, roughly emulating a granular synthesis.
//See helpfile to prepare movie in order for this tool to work
//
//2020 ArtScience semester project, by Luca Tornato


import processing.video.*;
import themidibus.*; 

MidiBus myBus; // The MidiBus

ArrayList<PImage> frames;        //all the frames will be stored here
Movie input;                     //input file
boolean isLoaded;                //flag to start the framulator routine
boolean record;                  //if you want to output
int index;                       //receives Midi messages, iterates frames

void setup(){
  size(720, 576, P2D);           //size must equal movie aspect ratio


  isLoaded = false;
  record = false;

  input = new Movie(this, "beach.mp4"){
  	//custom End of Stream method
  	@Override public void eosEvent(){
  		super.eosEvent();
  		//calling custom method
  		myEoS();          
  	}
  };

  frames = new ArrayList<PImage>();

  //the sketch has to go through the whole movie in order to store
  //frames into the arrayList. Volume is muted
  input.play();                        
  input.volume(0);
  println("LOADING FRAMES");

  index = 0;
  //Method is (this, input devide, output device)
  //print midibus TODO
  myBus = new MidiBus(this, 0, 3); // Create a new MidiBus using the device index to select the Midi input and output devices respectively.
}

void draw(){
  //nothing is visible during loading state
  //when movie finishes, isLoaded becomes true and frameScramble routine starts
  if(isLoaded){
  	//shows the current frame chosen by midi messages
  	index = constrain(index, 0, frames.size() - 1);
    image(frames.get(index), 0, 0, width, height); 
    if(record){
    	saveFrames();
    } 
  }
}

//not used
void delay(int time) {
  int current = millis();
  while (millis () < current+time) Thread.yield();
}

void noteOn(int channel, int pitch, int velocity) {
  //this method is called when a noteOn message is received
  println();
  println("Note On:");
  println("--------");
  println("Pitch:"+pitch);

  //since Midi pitch is 0~127, it has to be mapped into other channels
  //Therefore, video is split into chunks of 128 frames.
  index = channel * 128 + pitch;
  if(index > frames.size() - 1){
  	//checking for errors
  	index = frames.size() - 1;
  	println("ERROR - Message exceeds frameCount!");
  }
}

void myEoS(){
	//custom End of Stream method. Starts scrambling routine
	//print some useful info used in supercollider
	isLoaded = true;
	println("LOADED");
	println("Number of frames: " + (frames.size() - 1));
	println("Rough number of channels: " + (frames.size() - 1) / 128);
}

void movieEvent(final Movie m){
	//method called when a new frame is available, during the loading routine
	//also stores the current frame into the arrayList
	m.read();
	frames.add(m.get());
}

void keyPressed(){
	//turns on recording
	if(key == 'r'){
		record = !record;
	}
}

void saveFrames(){
	//formating file name for easy render
	String dateString = String.format("%d-%02d-%02d %02d.%02d.%02d",
    year(), month(), day(), hour(), minute(), second());
    save(dateString + ".png");
}