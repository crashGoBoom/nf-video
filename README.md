# nf-video

## What is it?

[Nextflow](https://www.nextflow.io) is an open source tool that "allows scalable and reproducible scientific workflows". It allows data scientists to process and work on large data sets without causing huge headaches.

It also simplifies much of the workflow for complex pipelines that need to process some data in parallel locally or in the cloud.

I thought this sounded very similar to a video processing pipeline! Especially when encoding large video files. So I've written `nf-video` as a Nextflow pipeline wrapper just for video processing that uses [ffmpeg](https://www.ffmpeg.org) behind the scenes. Now we can encode chucks in parallel without wiring up too much infrastructure or complex workflows.

## How to use it:

```
USAGE:
  ./nf-video.sh [FLAGS] [SUBCOMMAND]
FLAGS:
  --bgcolor Background Color of bumper video
  --bumperimage Image to use for the bumper video
  -c  CRF Number for ffmpeg
  -d  Set the duration of the bumper video
  -f  Font for bumper title
  --fontcolor Font Color of bumper video
  -h  Prints help information
  -i  Video to Process (Required.)
  -l  Language of the subtitle track in ISO 639. 3 letter language code. (eng, fra, etc..)
  -s  Adds a subtitle file.
  -t  Adds text to the bumper video.
  -w  Adds a watermark (Defaults to upper left.)
  -x  X location for the watermark
  -y  Y location for the watermark
```

## Examples:

To add a watermark to the lower right of a 720p video:
```
./nf-video.sh -i myvideo.mov -w someimage.png -x 1180 -y 650
```

To add subtitles to a video in english:
```
./nf-video.sh -i myvideo.mov -s example.srt -l eng
```

To create a simple 5 second bumper from your logo (must be png) and a title with Roboto font:
```
./nf-video.sh -i mylogo.png -f $YOUR_FONT_DIR/Roboto-Medium.ttf -t "This is my title" -d 5 --bgcolor WhiteSmoke --fontcolor DarkGray
```

Currently only supports conversion to MP4.
Currently only runs locally.

More features to be added soon!

## If nextflow is not installed you will be prompted.