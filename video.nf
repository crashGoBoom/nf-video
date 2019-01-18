#!/usr/bin/env nextflow

/*
 * Copyright (c) 2019, Christopher Mundus (crashGoBoom)
 */

params.inputs = "$baseDir/video.mov"
params.filter = 'NO_FILE'

videofile_ch = file(params.inputs)
opt_file = file(params.filter)

process segment {
  input:
  file input_file from videofile_ch
  output:
  file 'output_*' into segments mode flatten
  file 'input.aac' into input_audio
  """
  ffmpeg -i ${input_file} -map 0 -c copy -f segment -segment_time 10 output_%03d.mov
  ffmpeg -i ${input_file} -vn -acodec aac input.aac
  """
}

process encode_video {
  input:
  file segment_file from segments
  output:
  file 'encoded_*.mp4' into segments_encoded
  """
  ffmpeg -i ${segment_file} -crf 23 -vcodec libx264 encoded_${segment_file}.mp4
  """
}

process concat {
  publishDir "$workflow.projectDir", mode: 'move'
  input:
  file segment_files from segments_encoded.toList()
  file 'input.aac' from input_audio

  output:
  file 'completed.mp4' into file_output
  shell:
  '''
  files=(!{segment_files})
  IFS=$"\n"
  sorted=($(sort <<<"${files[*]}"))
  for i in ${sorted[@]}; do
    echo "file $i" >> concatlist.txt
  done
  ffmpeg -f concat -i concatlist.txt -i input.aac -c copy completed.mp4
  '''
}

workflow.onComplete {
  println "Your Video is Ready!"
}