#!/usr/bin/env nextflow

/*
 * Copyright (c) 2019, Christopher Mundus (crashGoBoom)
 */


params.inputs = "$baseDir/video.mov"
params.filter = 'NO_FILE'

videofile_ch = file(params.inputs)
opt_file = file(params.filter)

process convert {
  container 'jrottenberg/ffmpeg:4.0-ubuntu'
  input:
  file 'input.mov' from videofile_ch
  output:
  file 'input.mp4' into input_video
  '''
  ffmpeg -i input.mov -vcodec copy -acodec copy input.mp4
  '''
}

process segment {
  container 'jrottenberg/ffmpeg:4.0-ubuntu'
  input:
  file 'input.mp4' from input_video
  output:
  file 'output_*' into segments mode flatten
  '''
  ffmpeg -i input.mp4 -map 0 -c copy -f segment -segment_time 10 output_%03d.mp4
  '''
}

process encode {
  container 'jrottenberg/ffmpeg:4.0-ubuntu'
  input:
  file segment_file from segments
  output:
  file 'encoded_*.mp4' into segments_encoded
  """
  ffmpeg -i ${segment_file} -crf 23 -vcodec libx264 -acodec aac encoded_${segment_file}
  """
}


process concat {
  container 'jrottenberg/ffmpeg:4.0-ubuntu'
  input:
  file segment_files from segments_encoded.toList()
  output:
  file 'completed.mp4'
  shell:
  '''
  files=(!{segment_files})
  IFS=$"\n"
  sorted=($(sort <<<"${files[*]}"))
  for i in ${sorted[@]}; do
    echo "file $i" >> concatlist.txt
  done
  ffmpeg -f concat -i concatlist.txt -c copy completed.mp4
  '''
}

workflow.onComplete {
  println "Your Video is Ready!"
}