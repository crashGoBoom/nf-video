# nf-video
What does nf-video do you ask? Well let me tell ya!

Nextflow is an open source tool that "allows scalable and reproducible scientific workflows". It allows data scientists to process and work on large data sets without causing huge headaches.

It also simplifies much of the workflow for complex pipelines that need to process some data in parallel locally or in the cloud.

I thought this sounded very similar to a video processing pipeline! Especially when dealing with encoding large files. Now we can encode chucks in parallel without wiring up too much infrastructure or complex workflows.

## How to use it:

`./nf-video.sh -i $SOME_VIDEO`

Currently only supports MOV to MP4 conversion.
Currently only encodes at crf 23.
Currently only runs locally.

Next up. AWS BATCH.

More features to be added.