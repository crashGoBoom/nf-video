#!/usr/bin/env nextflow

/*
 * Copyright (c) 2019, Christopher Mundus (crashGoBoom)
 */

params.inputs = "$baseDir/video.mov"
params.filter = 'NO_FILE'
params.crf = 23
params.watermark = ''

videofile_ch = file(params.inputs)
opt_file = file(params.filter)
watermark_file = file(params.watermark)
crf = params.crf

file_ext_matcher = params.inputs =~ /\.[a-zA-Z0-9]+$/

/*
 * x and y are for watermark location
 */
x=10
y=10
watermark = ''
if (params.x) {
  x = params.x
}
if (params.y) {
  y = params.y
}
if (params.watermark) {
  watermark = "-i $params.watermark -filter_complex 'overlay=$x:$y'"
}

/*
 * In the segment process we must remove the audio to be encoded later
 * since we are segmenting the file for parallel encoding. Otherwise you will
 * hear popping noises at each segment.
 * TODO: Add audio encoding options and process.
 */
process segment {
  input:
  file input_file from videofile_ch
  output:
  file 'output_*' into segments mode flatten
  file 'input.aac' into input_audio
  """
  ffmpeg -i ${input_file} -an -map 0 -c copy -f segment -segment_time 10 output_%03d${file_ext_matcher[0]}
  ffmpeg -i ${input_file} -vn -acodec aac input.aac
  """
}
/*
 * In the encode_video process we encode the video and also add the
 * watermark file as an input if passed as an option.
 */
process encode_video {
  input:
  file segment_file from segments
  file watermark_input from watermark_file
  output:
  file 'encoded_*.mp4' into segments_encoded
  """
  ffmpeg -i ${segment_file} ${watermark} -crf ${params.crf} -vcodec libx264 encoded_${segment_file}.mp4
  """
}
/*
 * In the concat process we recombine the segments along
 * with the audio and output a new mp4 file.
 */
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