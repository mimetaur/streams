// Engine_SimpleSineGrainCloud
// works at cloud level rather than individual grain
// duration in ms, freq in hz
// by @mimetaur

Engine_SimpleSineGrainCloud : CroneEngine {
	var synthGroup;
	var freq = 440;
	var freq_range = 0;
	var density = 100;
	var amp = 1.0;
	var dur = 1.0;
	var grain_dur = 0.01;
	var width = 1.0;
	var lfo;
	var lfo_out;


	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
		// Output groups

		synthGroup = ParGroup.tail(context.xg);
		lfo_out = Bus.control(context.server);

		// SynthDefs

		SynthDef(\SimpleSineGrainCloud, {
			arg out, density = density, freq = freq, freq_range = freq_range, amp = amp, dur = dur, grain_dur = grain_dur, width = width;

			var gd_ = grain_dur.clip(0.001, 0.25);
			var amp_ = amp.linlin(0, 1, 0, 0.4);
			var dens_ = density.clip(1, 1000);
			var fill_factor = grain_dur * dens_;
			var dens_amp = amp_ * fill_factor.linexp(0.001, 25, 1.0, 0.1);
			var chan_dens = dens_ * 0.5;
			var freq_range_ = freq_range.clip(0, freq);

			var snd = SinGrain.ar([Dust.ar(chan_dens), Dust.ar(chan_dens)], grain_dur, [BrownNoise.ar.range(freq - freq_range_, freq + freq_range_), BrownNoise.ar.range(freq - freq_range_, freq + freq_range_)]);
			var env = Env.sine(dur: dur, level: dens_amp).kr(2);
			var sig = snd * env;
			Out.ar(out, Splay.ar(sig, width));
		}).add;

		SynthDef(\LfoController, {
			arg out, freq = 10, amp = 1.0;
			var sin = SinOsc.kr(freq: freq);
			var lfo = sin * amp;
			Out.kr(out, lfo);
		}).add;

		context.server.sync;

		lfo = Synth.new(\LfoController, [\out, lfo_out], target:synthGroup);

		context.server.sync;

		// Commands

		this.addCommand("lfo_hz", "f", { arg msg;
			var val = msg[1];
			lfo.set(\freq, val);
		});

		this.addCommand("lfo_amount", "f", { arg msg;
			var val = msg[1];
			lfo.set(\amp, val);
		});

		this.addCommand("hz", "f", { arg msg;
			var val = msg[1];
			Synth(\SimpleSineGrainCloud, [\out, context.out_b, \freq, val, \amp, amp, \dur, dur, \freq_range, freq_range, \density, density, \grain_dur, grain_dur, \width, width], target:synthGroup);
		});

		this.addCommand("hz_range", "f", { arg msg;
			freq_range = msg[1];
		});

		this.addCommand("dur", "f", { arg msg;
			dur = msg[1];
		});

		this.addCommand("amp", "f", { arg msg;
			amp = msg[1];
		});

		this.addCommand("density", "f", { arg msg;
			density = msg[1];
		});

		this.addCommand("grain_dur", "f", { arg msg;
			grain_dur = msg[1];
		});

		this.addCommand("width", "f", { arg msg;
			grain_dur = msg[1];
		});

		// Polls

		this.addPoll(("lfo_out").asSymbol, {
			var val = lfo_out.getSynchronous;
			val
		});

	}
}