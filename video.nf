#!/usr/bin/env nextflow

/*
 * Copyright (c) 2019, Christopher Mundus (crashGoBoom)
 */


params.inputs = "$baseDir/video.mov"
params.filter = 'NO_FILE'

videofile_ch = file(params.inputs)
opt_file = file(params.filter)

 process foo {
  container 'jrottenberg/ffmpeg:4.0-ubuntu'
  input:
  file 'input.mov' from videofile_ch

  '''
  ffmpeg -i input.mov -vcodec copy -acodec copy new.mp4
  '''
}
