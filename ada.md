# ada

i made a bad-but-kind-of-good function microcontroller generator out of a raspberry pi pico.

pico and its sdk are new to me, so i started with their happy path: pico c sdk. haven't tried micropython before, but it probably would have worked.

device features i need:

- dma + pio for full-bandwidth r2r bank writes from a buffer (ping-pong)
- spi for lcd and digipot
- interrupts for encoder and buttons
- adc for rotary switch reading (resistor stack)
- gpio for remaining buttons

and it basically works. yay. hacky glue code all the way.

i expected i'd want to write it in rust once all the pieces were together, and i still might, but i also recently learned that there's decent ada support for raspi pico! https://pico-doc.synack.me/

i've taken a few glances at some ada code, but never programmed in it before. skimming the code examples for pico seemed promising, and all the device features i need seem to be supported.

normally i'd jump in and get a blinky hello world, but the toolchain mentioned in the docs is for linux and i'm on an old mac laptop these days, so i figured i'd take a closer look at ada before worrying about that potential pain.

## adacore language intro

the _Ada on the Raspberry Pi Pico_ page links to [learn.adacore.com](https://learn.adacore.com/courses/intro-to-ada/index.html) for an intro to the language. it is just fantastic. the code examples are clear, and interactive! it's a great tour of language features.

the ada language was named after Ada Lovelace, the first programmer. she saw the potential in computing to even music and art, and described her aproach as "poetical science". the ada language was designed for the US department of defense.

from reading the docs, ada has the language features i want for a project like this:

- explicit and a stict and picky compiler :)
- strongly typed
    - really interesting features like integers defined as ranges and floats defined by desired precision (compiler picks the underlying type). mod numbers represent positive integers with wraparound overflow at arbitrary maximums.
- nice enums with a case/when constuct that has exhaustiveness checking
- variant records (sort of like rust enums) -- http://www.isa.uniovi.es/docencia/TiempoReal/Recursos/textbook/aps12-4.htm
    - edit later: they're in learn.adacore.com as well, i just missed it the first time: https://learn.adacore.com/courses/intro-to-ada/chapters/more_about_types.html#variant-records
- no multi-value/tuple returns, but explict in/out/inout function params
- it just generally seems really thoughtful

i'm anticipating that i'll miss some of the functional features i'm used to in other languages. my biggest question mark is how interrupt handling will work.

i'm hoping that it won't be too tedious and slow to experiment with due to explicitness and strictness. it doesn't seem like that will be too much of a problem from here.


## installing

weirdly burried: https://www.adacore.com/download/more

interesting: the free compiler is only supposed to be used for building software licensed GPLv3. fine with me.

alire is available as a binary download for mac: https://alire.ada.dev/docs/#installation

easy!?

side note: there's a sublime text package control package for ada, seems good.
- doesn't automatically recognized .gpr files as ada
- it uses 3 spaces by default? haha


## toolchain

followed the _Create a new project_ steps at https://pico-doc.synack.me/ and it... just worked. cool! also `alr` makes pretty colours and it's nice.

edited hello_pico.gpr as instructed

`alr build` failed :/ i think my mac is too old (10.12.)

```
dyld: Symbol not found: ___darwin_check_fd_set_overflow
  Referenced from: /Users/phil/.config/alire/cache/dependencies/gprbuild_22.0.1_b1220e2b/bin/gprconfig
  Expected in: /usr/lib/libSystem.B.dylib
```

side note: the alire package index is cute -- 221 crates that can be rendered on a single page https://alire.ada.dev/crates.html

ok, seems like this is an xcode thing that can't be fixed on my old OS. seems like my choices are either to build alire from source (might maybe possibly help?) or upgrade (aka switch back to linux).

### building alire from source :sob:

https://github.com/alire-project/alire#building-from-sources

clones fairly quickly, then

```bash
OS=macOS gprbuild -j0 -P alr_env
```

gets going but fails with 

```
[...]/alire/deps/gnatcoll-slim/src/terminals.c:23:10: fatal error: unistd.h: No such file or directory
 #include <unistd.h>
          ^~~~~~~~~~
compilation terminated.

   compilation of terminals.c failed

gprbuild: *** compilation phase failed
```

://////

i have xcode installed, so either somethings wrong in the build process finding the headers, or xcode needs an update and apple won't even consider anything but the latest (which of course absolutely does not run on my ancient macos).

double-checked my time machine and kicked out some excluded folders (eek) so now i'm waiting 23 more hours for 99GB to get backed up before i try to finally upgrade this os. that's toooooo long.


### starting over on linux

since my machine is busy backing itself up, i spun up a debian VM on LunaNode. it has 1GB of ram, let's see how it does.

`apt-get install gnat` just worked, i miss linux

alire's not in there, but that was expected. grabbed a link from https://github.com/alire-project/alire/releases and `curl -LO https://github.com/alire-project/alire/releases/download/v1.1.2/alr-1.1.2-bin-x86_64-linux.tar.gz`

```bash
sudo apt-get install unzip
unzip alr-1.1.2-bin-x86_64-linux.zip
# conveniently it dumps a `bin/` folder where we are, which is our home dir, and the .profile script will just pick it up next login. sweet!
```

ok following the _Create a new project_ directions again... it worked?

```
file bin/hello_pico
bin/hello_pico: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), statically linked, with debug_info, not stripped
```

it worked!?

made a little script since i'll be doing this a lot...
```bash
#!/bin/bash
set -eu
APP=hello_pico
ssh debian@[VM_IP] "cd $APP; ~/bin/alr build"
scp "debian@[VM_IP]:$APP/bin/$APP" "$APP.elf"  # there's probably a way to combine this with the ssh command?
openocd -f interface/picoprobe.cfg -f target/rp2040.cfg -c "program $APP.elf verify reset exit"
```

(openocd is from the pico fork, i set it up previously for the pico-sdk stuff)

it uploaded (and verified!), but there's no blinking. wait is this supposed to blink? (no, it's an empty project, nothing written yet!)

continuing the next step in _Create a new project_ to actually add some code...

HELL YEAH BLINKY BLINK

***

I'd rather keep the code on my local machine so the remote is stateless-ish, so i wrapped some stuff into a script -- see `fdsa.sh`.

```bash
./fdsa.sh hello_pico
```


## making stuff

I was not expecting a modern package management solution, but alire is really nice.

Title_Snake_Case feels so extreme.

Tried to add contracts, but nothign was enforced. Tried a few ways but wasn't sure how to enable runtime checks.

The DMA procedure for configuring the addresses auto-starts the DMA. It should be possible to include a flag preventing the DMA from starting yet.

Ada is case insensitive??????? error messages are sorta confusing here, wow.

Version of `pico_bsp` is a bit out of date (1.2.1 tagged, alire has 1.1.0), so i got a bit misled by reading the `.ads` files in there. Neet of figure out how to point the dep at a git address...

    - er no, i mixed up prp2040_hal and pico_bsp. rp2040 is 1.2.1.
    - nah but I *was* looking at undreleased code on the main branch. `RP.PIO.DMA_TX_Trigger` is unreleased :'(

wrote a bunch of code with DMA + PIO and.... didn't work, hard to debug. started over working backward from PIO instead of forward from DMA.

it's surprising to me that ada has exception-based error handling. seems like it can be non-obvious when a function like Get from https://learn.adacore.com/courses/intro-to-ada/chapters/generics.html#generic-packages can actually raise.

...but being able to add exception handling to any statements blook is pretty cool

unexpected: tasks as a language feature. seems... good?
not keen on: `with somepackge;` will cause that package's tasks to run automatically???
i do like the looks of rendez-vous style of task entries though

i'm a little surprised at how big the binary is already???352KB with it just doing some PIO stuff???but I have no idea if/how to turn on any optimizations in the compiler. Uploading is slower than it was with the C++ code, and takes longer than the round trip over the network to upload-compile-download from my linux vm.

A `Setup` procedure was added to `rp2040_hal` to configure addresses without auto-starting, which was the thing I was missing in trying to get chaining to work ????

