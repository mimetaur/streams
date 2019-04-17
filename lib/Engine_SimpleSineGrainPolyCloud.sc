// Engine_SimpleSineGrainPolyCloud
// works at cloud level rather than individual grain
// wrapped in a gate-able ASR envelope
// by @mimetaur

Engine_SimpleSineGrainPolyCloud : CroneEngine {
	var freq = 440;
	var freq_range = 0;
	var density = 100;
	var amp = 1.0;
	var dur = 1.0;
	var grain_dur = 0.01;
	var width = 1.0;
	var atk_time = 1.0;
	var rel_time = 1.0;

	var num_voices = 4;
	var voiceList;
	var synthGroup;


	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
		voiceList = List.new(num_voices);
		synthGroup = ParGroup.tail(context.xg);
		SynthDef(\SimpleSineGrainPolyCloud, {
			arg out, gate = 0, density = density, freq = freq, freq_range = freq_range, amp = amp, atk_time = atk_time, rel_time = rel_time, grain_dur = grain_dur, width = width;

			var gd_ = grain_dur.clip(0.001, 0.25);
			var amp_ = amp.linlin(0, 1, 0, 0.4);
			var dens_ = density.clip(1, 1000);
			var fill_factor = grain_dur * dens_;
			var dens_amp = amp_ * fill_factor.linexp(0.001, 25, 1.0, 0.1);
			var chan_dens = dens_ * 0.5;
			var freq_range_ = freq_range.clip(0, freq);

			var snd = SinGrain.ar([Dust.ar(chan_dens), Dust.ar(chan_dens)], grain_dur, [BrownNoise.ar.range(freq - freq_range_, freq + freq_range_), BrownNoise.ar.range(freq - freq_range_, freq + freq_range_)]);
			var env = Env.asr(attackTime: atk_time, level: dens_amp, releaseTime: rel_time).kr(0, gate);
			var sig = snd * env;
			Out.ar(0, Splay.ar(sig, width));
		}).add;

		this.addCommand("note_on", "i", { arg msg;
			var i = msg[1] - 1;
			var newVoice;

			if(i < num_voices && i >= 0, {
				newVoice = Synth(\SimpleSineGrainPolyCloud, [\out, context.out_b, \gate, 1, \freq, freq, \amp, amp, \freq_range, freq_range, \density, density, \grain_dur, grain_dur, \atk_time, atk_time, \rel_time, rel_time, \width, width], target:synthGroup);
				voiceList.insert(i, newVoice);
			});
		});

		this.addCommand("note_off", "i", { arg msg;
			var i = msg[1] - 1;
			var oldVoice;

			if(i < num_voices && i >= 0, {
				oldVoice = voiceList.at(i);
				oldVoice.set(\gate, 0);
			});
		});

		this.addCommand("hz", "f", { arg msg;
			freq = msg[1];
		});

		this.addCommand("hz_range", "f", { arg msg;
			freq_range = msg[1];
		});

		this.addCommand("atk_time", "f", { arg msg;
			atk_time = msg[1];
		});

		this.addCommand("rel_time", "f", { arg msg;
			rel_time = msg[1];
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
	}
}