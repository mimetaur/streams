## Streams

*Streams* is a Norns script which generates granular synthesis based on rectangular "clouds" moving across the screen.

There are two varieties of *Streams*:

1. `streams_audio` reads from a file-based audio buffer. You can select files from the params menu.
2. `streams_sines` uses clouds of pure sine waves. There are no additional param options.

## Notes
* *Streams* is most rewarding when you assign Arc or Midi controllers to the `wind`, `gravity` and `diffusion` parameters.
* In some cases, modulators may be more appropriate than manually changing parameters. *Streams* comes with *sine*, *noise*, *brownian* and *lorenz* modulators. There are three modulation slots, which can be assigned any of the above types and assigned to either `wind`, `gravity`, or `diffusion`.

