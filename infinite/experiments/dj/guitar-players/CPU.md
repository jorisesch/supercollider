# Guitar CPU measurements

Measured on 2026-11-02 using an Apple M4 Mac with 10 CPU cores and 16 GiB memory, SuperCollider 3.13, 48 kHz audio and a 64-sample control block. These are the audio server's average/peak **signal-processing percentages**, as defined by the [SuperCollider status command](https://doc.sccode.org/Reference/Server-Command-Reference.html#%2Fstatus). They are not whole-machine CPU percentages.

## Preliminary results

| Scenario | Typical reported DSP load | Highest observed reported peak |
| --- | --- | --- |
| Full Rock band, across Rook/June/Flint | 33–34% | 53–54% |
| Two-track handover | 33% | 58% |
| Six live guitar notes through one shared rig | 26% | 39% |
| Twelve live notes through one shared rig | 36% | 48% |
| Six experimental contact strings through one rig | 29% | 44% |
| Twelve experimental strings through one rig | 38% | 52% |
| Twenty-four experimental strings through two rigs | 41% | 65% |

“Typical” is the median of sampled `avgCPU` readings. Static chord figures combine two short trials. Twelve string voices represent a doubled six-string chord; twenty-four model overlapping doubled chords across two rigs. The first pass measured two idle deck strips plus the master at about 23%; the partial repeat measured about 16%, illustrating run-to-run variation in timing on this machine.

The first pass completed all measurement cases but reported eight errors during musical-case cleanup: queued end-of-bar automation reached deck nodes after the benchmark had freed them. These occurred after the song measurement windows. The retained harness waits for queued automation before freeing the nodes. A confirmation run repeated the idle and Rook cases, then its dedicated server stopped answering during June and exited at the timeout. These results therefore remain **preliminary**, and do not establish long-run stability or a maximum safe polyphony. No production sound code was changed to investigate them.

See [raw timing samples](cpu-samples.tsv) and [results, source hashes and limitations](cpu-results.json).

## What costs CPU

The current live Rock guitar computes 28 string modes per sounding note. The experimental contact guitar computes 40 primary modes plus 12 modes for the other string polarization. A seventh, added ninth or inversion does not add a special processing stage: the important quantities are the number of sounding notes, the instrument used and overlapping releases.

Guitar effects are shared per deck, so adding a chord note adds a string voice rather than a new pedalboard. However, the current pedal graph computes all its circuit branches before selecting/blending their outputs. Both deck strips also keep running when one deck is unused. Those are significant fixed costs and plausible optimization targets. This benchmark changes no instruments, effects, player rules or scheduling in the DJ.

## Method

[cpu-benchmark.scd](cpu-benchmark.scd) boots its own server with hardware output muted. It loads the existing guitar definitions, polls `/status` and writes `rock-cpu-samples.tsv` to SuperCollider's temporary folder. It does not use or stop another running session. Run from the repository folder:

```sh
sclang -D infinite/experiments/dj/guitar-players/cpu-benchmark.scd
```

The benchmark measures an idle server, idle deck/master strips, each player with bass/drums and a requested solo, an eight-bar two-deck handover, and simultaneous held chords with 6, 12 or 24 guitar voices. The static test holds notes for four seconds, discards the attack/warm-up interval and samples before they release. The dry comparison retains the master but omits the guitar deck. Real song tests use the same event and automation adapters as live playback, without the GUI/spectrum.

Statistics describe these short tests with other applications open; they are not a maximum-polyphony limit or a guarantee on another machine. Reported peak CPU is the server's recent-peak statistic, sampled periodically, rather than an exhaustive callback trace. Static-chord attack/allocation spikes are not exhaustively measured. No listening or dropout assessment is inferred from muted output or from the absence of late OSC messages.

The companion website plays rendered M4A files using ordinary HTML audio. It does not run this guitar synthesis in the browser.
