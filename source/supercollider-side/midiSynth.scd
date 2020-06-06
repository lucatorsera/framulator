//this code is an essential part of the framulator
//and it does two things:
//it sequences Midi patterns determined by the user
//it granulates the audio track from the movie
//See helpfile to prepare movie in order to use this tool
//
//2020 ArtScience final semester project by Luca Tornato



s.boot

MIDIClient.init;      //starting midi

//loading audio sample -- inputMono for bird
b = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+"audio"+/+ "input.wav");

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

var totalNumberOfVideoFrames = 870; //MUST be the same told by the processing sketch

var maxChan = 6; //also MUST be the same by the .pde sketch

var midiMax = 127; //always 127 values for pitch


//here is where the magic happens.
//note sequences Midi pithces from 0~127 within a video 'chunk'
//by sequencing the channel messages, other chunks of video can be manipulated
//just make sure note is not bigger than 127
//and chan not bigger than the 'rough number' estimated by the processing sketch

//------------------------------------------------------
//---------------- MIDI PATTERNS -----------------------
//------------------------------------------------------



/*
var notes = Pn( Plazy {
	Pseq(Array.series(rrand(2, 40), 50, 1), 1)
});

var chan = Pseq([1, 3, 5], inf);
*/
/*
var notes = Pwalk(
    Array.series(127, 0, 1),
        // steps up to 2 in either direction, weighted toward positive
    Pwrand([-2, -1, 0, 1, 2], [0.05, 0.1, 0.15, 1, 0.1].normalizeSum, inf),
        // reverse direction at boundaries
    Pseq([1, -1], inf),
    10);

var chan = Pwalk([0, 1, 2, 3, 4, 5],
	Pwrand([0, 1, 2], [10, 1, 2].normalizeSum, inf));
*/

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
