# nf-video

## What is it?

[Nextflow](https://www.nextflow.io) is an open source tool that "allows scalable and reproducible scientific workflows". It allows data scientists to process and work on large data sets without causing huge headaches.

It also simplifies much of the workflow for complex pipelines that need to process some data in parallel locally or in the cloud.

I thought this sounded very similar to a video processing pipeline! Especially when encoding large video files. So I've written `nf-video` as a Nextflow pipeline wrapper just for video processing that uses [ffmpeg](https://www.ffmpeg.org) behind the scenes. Now we can encode chucks in parallel without wiring up too much infrastructure or complex workflows.

## How to use it:

`./nf-video.sh -i $SOME_VIDEO`

Currently only supports MOV to MP4 conversion.
Currently only encodes at crf 23.
Currently only runs locally.

Next up. AWS BATCH.

More features to be added.
