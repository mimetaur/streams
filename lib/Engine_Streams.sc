// Engine_Streams
// clouds of sine grains
// duration in seconds, freq in hz
// by @mimetaur

Engine_Streams : CroneEngine {
	var synthGroup;

	var freq = 440;
	var freq_range = 0;
	var density = 100;
	var amp = 1.0;
	var dur = 1.0;
	var grain_dur = 0.01;
	var width = 1.0;

	var max_modulators = 4;
	var modulators;
	var modulator_outs;
	var modulator_types = #[\BrownianModulator, \NoiseModulator, \SineModulator];



	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
		// Output groups

		synthGroup = ParGroup.tail(context.xg);

		// SynthDefs

		SynthDef(\SineGrainCloud, {
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

		SynthDef(\BrownianModulator, {
			arg out, freq = 10, lag = 0.1, aux = 1.0;
			var mod, to_out;

			mod = LFBrownNoise1.kr(freq: freq, dev: aux).range(-1, 1);
			to_out = Lag.kr(mod, lag);
			Out.kr(out, to_out);
		}).add;

		SynthDef(\NoiseModulator, {
			arg out, freq = 10, lag = 0.1, aux = 0;
			var mod, to_out;

			mod = LFNoise0.kr(freq).range(-1, 1);
			to_out = Lag.kr(mod, lag);
			Out.kr(out, to_out);
		}).add;

		SynthDef(\SineModulator, {
			arg out, freq = 10, lag = 0.1, aux = 0;
			var mod, to_out;

			mod = SinOsc.kr(freq).range(-1, 1);
			to_out = Lag.kr(mod, lag);
			Out.kr(out, to_out);
		}).add;


		context.server.sync;

		modulator_outs = Array.fill(max_modulators, { arg i; Bus.control(context.server) });
		modulators = Array.fill(max_modulators, { arg i; Synth.new(modulator_types.choose, [\out, modulator_outs.at(i)], target:synthGroup); });

		context.server.sync;

		// Synth Engine Commands

		this.addCommand("hz", "f", { arg msg;
			var val = msg[1];
			Synth(\SineGrainCloud, [\out, context.out_b, \freq, val, \amp, amp, \dur, dur, \freq_range, freq_range, \density, density, \grain_dur, grain_dur, \width, width], target:synthGroup);
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

		// Modulator Commands

		this.addCommand("add_mod", "ii", { arg msg;
/*			var type = msg[1] - 1;
			var slot_num = msg[2] - 1;
			var mod_name = modulator_types.at(type);
			var mod = Synth.new(\SineModulator, [\out, modulator_outs.at(slot_num)], target:synthGroup);
			modulators.put(slot_num, mod);*/
		});

		this.addCommand("remove_mod", "i", { arg msg;
/*			var slot_num = msg[2] - 1;
			var mod = modulators.removeAt(slot_num);
			mod.free;*/
		});


		this.addCommand("mod_hz", "if", { arg msg;
			var i = msg[1] - 1;
			var val = msg[2];
			modulators.at(i).set(\freq, val);
		});

		this.addCommand("mod_lag", "if", { arg msg;
			var i = msg[1] - 1;
			var val = msg[2];
			modulators.at(i).set(\lag, val);
		});

		this.addCommand("mod_aux", "if", { arg msg;
			var i = msg[1] - 1;
			var val = msg[2];
			modulators.at(i).set(\aux, val);
		});

		// Polls

		modulator_outs.do({ arg a_modulator, i;
			var num = i + 1;
			this.addPoll(("mod_" ++ num ++ "_out").asSymbol, {
				var val = a_modulator.getSynchronous;
				val
			});
		});
	}
}