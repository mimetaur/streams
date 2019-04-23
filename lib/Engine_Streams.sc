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
	var modulator_types = #[\ConstantMod, \SineMod, \NoiseMod, \BrownianMod, \LorenzMod];
	var modulator_freqs;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
		// Output groups

		synthGroup = ParGroup.tail(context.xg);

		// SynthDefs

		// Audio
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



		// Modulators

		SynthDef(\ConstantMod, {
			arg out, hz = 0, lag = 0, aux = 0;
			var mod = DC.kr(aux).range(-1, 1);
			Out.kr(out, mod);
		}).add;

		SynthDef(\SineMod, {
			arg out, hz = 1, lag = 0.1, aux = 0;
			var mod, to_out;

			mod = SinOsc.kr(hz).range(-1, 1);
			to_out = Lag.kr(mod, lag);
			Out.kr(out, to_out);
		}).add;


		SynthDef(\NoiseMod, {
			arg out, hz = 1, lag = 0.1, aux = 0;
			var mod, to_out;

			mod = LFNoise0.kr(hz).range(-1, 1);
			to_out = Lag.kr(mod, lag);
			Out.kr(out, to_out);
		}).add;

		SynthDef(\BrownianMod, {
			arg out, hz = 1, lag = 0.1, aux = 1.0;
			var mod, to_out;

			mod = LFBrownNoise1.kr(freq: hz, dev: aux).range(-1, 1);
			to_out = Lag.kr(mod, lag);
			Out.kr(out, to_out);
		}).add;

		SynthDef(\LorenzMod, {
			arg out, hz = 1, lag = 0.1, aux = 0.02;
			var mod, to_out;

			mod = Lorenz2DC.kr(minfreq: hz, maxfreq: hz, h: aux).range(-1, 1);
			to_out = Lag.kr(mod, lag);
			Out.kr(out, to_out);
		}).add;

		context.server.sync;

		modulator_outs = Array.fill(max_modulators, { arg i; Bus.control(context.server) });
		modulators = Array.fill(max_modulators, { arg i; Synth.new(modulator_types.at(0), [\out, modulator_outs.at(i)], target:synthGroup); });
		modulator_freqs = Array.fill(max_modulators, { arg i; 1 });

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

		this.addCommand("mod_type", "ii", { arg msg;
			var slot_num = msg[1] - 1;
			var type = msg[2] - 1;
			var mod, mod_name, old_mod;

			if ( (type > -1) && (slot_num > -1) && (type < modulator_types.size) && (slot_num < modulators.size), {
				mod_name = modulator_types.at(type);
				old_mod = modulators.at(slot_num);
				old_mod.free;

				mod = Synth.new(mod_name, [\out, modulator_outs.at(slot_num), \hz, modulator_freqs.at(slot_num)], target:synthGroup);
				modulators.put(slot_num, mod);
			});
		});

		this.addCommand("mod_speed", "if", { arg msg;
			var i = msg[1] - 1;
			var val = msg[2];
			var hz;

			if ( (i > -1) && (i < modulators.size), {
				val.clip(1, 100);
				hz = val.linexp(1, 100, 0.001, 30);
				modulator_freqs.put(i, hz);

				modulators.at(i).set(\hz, hz);
			});
		});

		#[\lag, \aux].do({ arg cmd, i;
			this.addCommand("mod_" ++ cmd, "if", { arg msg;
				var i = msg[1] - 1;
				var val = msg[2];

				if ( (i > -1) && (i < modulators.size), {
					modulators.at(i).set(cmd, val);
				});
			});
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