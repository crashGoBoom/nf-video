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
  -crf  CRF Number for ffmpeg
  -h    Prints help information
  -i    Video to Process (Required.)
  -w    Adds a watermark (Defaults to upper left.)
  -x    X location for the watermark
  -y    Y location for the watermark
```

Currently only supports conversion to MP4.
Currently only runs locally.
More features to be added soon!

## This _will_ install nextflow!