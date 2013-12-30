Converts all applicable video files in the current directory to
Quicktime

## Setup

You'll need ffmpeg installed, and then run:

```
bundle install
```

## Running

There is a locale issue with filemagic and you must first run:

```
export LC_CTYPE=C
export LANG=C
```

Then you can run the converter:

```
./qtconvert <path to dir>
```
