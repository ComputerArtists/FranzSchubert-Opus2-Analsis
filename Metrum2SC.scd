~metrum = 80;

// Kompletter Code zum Starten
(
 // Setup für SC Client auf Auseisch Adresse
s = Server.local;
s.addr = NetAddr("127.0.0.1", 57121);
s.boot;

// Intialisierung von MIDI auf Kanahl 1
MIDIClient.init;
~midiOut = MIDIOut.new(1);

// Initialiserung des OSC Eingangs für die Steuer-Daten
~n = NetAddr.new("127.0.0.1", 1234);

// Erzeuge des Synthesiers mit Variabler Frequenz, Ton-Dauer ( in Sekunden ), Detune-Factor ( in Cent )
SynthDef("help-synth", { |freq=440, a=1, out=0, freqFact = 25|
	var sig, env, amp, int;
	// Generirung einer Pekusiven Envelope
	env = Env.perc(0.05, a, 1, -4);
	amp = EnvGen.kr(env);
	// Beechnung des Detune Factors in Fequenzy Factor
	int = 1.00057779 ** freqFact;
	// Erzeugung einer leichten Varianz in der Fequenz
	freq = LFNoise0.kr(4).range(freq*int, freq/int);
	// Tongenerator: Rechteck mit leichtem Reverb für mehr Räumlichkeit
	sig = FreeVerb.ar(Impulse.ar(freq, 0, amp), 0.9, 1);
	Out.ar(out, [sig, sig]);
}).add;


// Routine-Fabrik zur Steuerung des Synthesizers
~controlSynth = { |dur|
	Routine({
		var x; // Variable fü+r den Synthesizer
		// Starten des Synthesizers und MIDI Ausgabe des Ton-Beginns
		("Starte Synth für " ++ dur ++ " Sekunden").postln;
		x = Synth("help-synth", [freq: 440, a: dur]);
		~midiOut.noteOn(1, 60, 100);
		// Warten bis der Ton Gespielt sein sollte
		(dur*5).wait;
		// Soppen des Synthesizers damit Maschine nicht Überläuft und MIDI Ausgabe des Endes des Tons
		x.free;
		~midiOut.noteOff(1, 60, 100);
		("Synth freigegeben").postln;
	});
};

// OSC Empfangs Funktion
// OSC Callback
~o = OSCFunc({ |msg, time, addr, recvPort|
	var n; // Variable für die Gewählte Ton-Dauer
	// Prüfe ob Trigger gerufen wurde
	if (msg[1] != -1.0) {
		"Event wurde empfangen".postln;
		msg.postln; // Ausgabe der Message zur besseren Überwachung
		n = msg[2].asFloat; // Auslese der Ton-Dauer in üblicher Musikalischer Angabe
		n = ((1/2)**n)*(60/~metrum); // Umrechnung in Sekunden
		~r = ~controlSynth.(n); // Routine für Synthesizer Steuerung mit Zeit n erstellen
		~r.play; // Routine zum Steuern de Synthesizers starten
	};
}, "/trigger", ~n); // Empfang nur von OSC Messages für die Trigger
)