//this code is an essential part of the framulator
//and it does two things:
//it sequences Midi patterns determined by the user
//it granulates the audio track from the movie
//See helpfile to prepare movie in order to use this tool
//
//2020 ArtScience final semester project by Luca Tornato



s.boot

MIDIClient.init;      //starting midi

//loading audio sample
b = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "inputMono.wav");
//variable to store size of audio buffer
h = b.numFrames;

//synth to handle audio grains
( SynthDef(\granulator, {
	arg refreshRate, sweepCurve;
	var impulse, playhead, signal;

	//StartPos is triggered when a signal becomes positive
	impulse = Trig.kr(Impulse.kr(refreshRate));
	//playhead is a Linear curve sweeping through the buffer
	//Line has the startPos modulated by the input values, normalized
	//Amplitude is multiplied by the total number of frames in the buffer
	//So if sweepCurve is 0 the playhead is close to beggining of buffer
	playhead = Line.kr(sweepCurve/h, mul: h);

	//grain is multiplied by a short envelope
	signal = PlayBuf.ar(1, b, trigger: impulse, startPos: playhead, loop: 0)
	         *
	         EnvGen.kr(Env([0,1,1,0],[0.01,0.2,0.01]), doneAction:          Done.freeSelf);

	//panning
	Out.ar(0, Pan2.ar(signal, 0))}).add;
)


(
    // substitute your own Midi device here
    // TODO print devices
var    mOut = MIDIOut.newByName("loopMIDI Port", "loopMIDI Port").latency_(Server.default.latency);

var totalNumberOfVideoFrames = 480; //MUST be the same told by the processing sketch

var maxChan = 3; //also MUST be the same by the .pde sketch

var midiMax = 127; //always 127 values for pitch


//here is where the magic happens.
//note sequences Midi pithces from 0~127 within a video 'chunk'
//by sequencing the channel messages, other chunks of video can be manipulated
//just make sure note is not bigger than 127
//and chan not bigger than the 'rough number' estimated by the processing sketch

//------------------------------------------------------
//---------------- MIDI PATTERNS -----------------------
//------------------------------------------------------

var notes = Pn(Prand([
	Pseq(Array.series(exprand(1, midiMax), 0, 1), 1),
	Pseq(Array.series(exprand(1, midiMax), 0, 1), 1),
	Pseq(Array.series(exprand(1, midiMax), 0, 1), 1),
	Pseq(Array.series(exprand(1, midiMax), 0, 1), 1)], 1), inf);


var chan = Pseq([1, 1, 1, 2, 0, 1, 1], inf);

//------------------------------------------------------
//------------------------------------------------------

// this Pbind is used to send midi messages to the processing sketch
// and control the frame index
p = Pbind(
    \type, \midi,
	//\midinote, notes,   //pitches go here
	\midinote, notes,
    \midicmd, \noteOn,
    \midiout, mOut,
	\chan, chan,        //channels go here
	\dur, 0.03,         //just so the video gets fast enough, emulating motion
).play;

//this Pbind controls the audio grains
~seq = Pbind(\instrument, \granulator,
	\refreshRate, 25,
	//useful to iterate through the whole video and debug
	//\sweepCurve, Pseq(Array.series(480, 0, h/480), inf).trace,
	//converting the chan and note patterns into something that iterates through
	//the audio buffer
	\sweepCurve, h * ((chan*128 + notes) / totalNumberOfVideoFrames ),
	\dur, 0.03,   //MUST be the same value as the video Pbind to sync audio/video
).play;
)




/////////////////////////////////////////////
////////////// T R A S H ////////////////////
/////////////////////////////////////////////

c = Buffer.read(s, "sounds/a11wlk01.wav");  //test sample

g = c.numFrames;    //number of samples in test buffer

{ PlayBuf.ar(1, c, trigger: Impulse.ar(25), startPos: SinOsc.ar(50, Impulse.kr(1000))*g, loop: 1) }.play

{ BufRd.ar(2, b, phase: SinOsc.ar(1, 0.5).range(0.0, b.numFrames-1), loop: 1) }.play

{ BufRd.ar(2, b, phase: LFNoise1.ar(2).range(0.0,b.numFrames-1), loop: 1) }.play //pretty cool but not what I want