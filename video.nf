#!/usr/bin/env nextflow

/*
 * Copyright (c) 2019, Christopher Mundus (crashGoBoom)
 */

/*
 * Params for passing in options.
 */
params.inputs = "$baseDir/video.mov"
params.crf = 23
params.duration = 5
params.framerate = 30
params.watermark = ''
params.x=10
params.y=10
params.font = 'NO_FILE'
params.srt = ''
params.language = 'eng'
params.text = ''
params.background_color = 'WhiteSmoke'
params.font_color = 'DarkGray'

/*
 * Channels for file inputs.
 */
srt_file = Channel.empty()
watermark_file = Channel.empty()
fontfile_ch = Channel.empty()
videofile_ch = Channel.empty()
imagefile_ch = Channel.empty()

user_input = file(params.inputs)
input_path = user_input.getParent()
input_extension = user_input.getExtension()

/*
 * If we are using a png file as the input hook up that channel and
 * leave the video file channel blank so segmenting is not attempted.
 */
if ( input_extension == 'png' ) {
  imagefile_ch = file(params.inputs)
} else {
  videofile_ch = file(params.inputs)
}

/*
 * Fade in and fade out calculations.
 */
fade_in = params.framerate * params.duration - params.framerate
fade_out_start = params.framerate * params.duration - params.framerate
fade_out_end = params.framerate

/*
 * Title text for bumper videos.
 */
title_text = Channel.from(params.text)

/*
 * Create empty strings for the watermark and subtitles
 * options as default.
 */
watermark = ''
subtitles = ''

if (params.watermark) {
  watermark_file = file(params.watermark)
  watermark = "-i $watermark_file -filter_complex 'overlay=$params.x:$params.y'"
}

if (params.srt) {
  srt_file = file(params.srt)
  subtitles = "-i $params.srt -c:v copy -c:a copy -c:s mov_text -metadata:s:s:0 language=$params.language"
}

if (params.font) {
  fontfile_ch = file(params.font)
}

/*
 * In the create_bumper process we create a bumper video.
 */
process create_bumper {
  publishDir "$workflow.projectDir", mode: 'move'
  input:
  file input_file from imagefile_ch
  file input_font from fontfile_ch
  val x from title_text
  output:
  file 'completed_bumper.mp4' into file_bumper_output

  shell:
  '''
  ffmpeg -f lavfi -i color=c=!{params.background_color}:s=1280x720:d=!{params.duration}:r=30 \
  -i !{input_file} \
  -filter_complex \
  "[0] drawtext=fontfile=!{input_font}:fontsize=60:fontcolor=!{params.font_color}:x=(w-text_w)/2:y=(h-text_h)/1.1:text='!{x}', fade=in:0:!{params.framerate},fade=out:!{fade_out_start}:!{fade_out_end} [b]; [b] overlay=(W-w)/2:(H-h)/2, fade=in:0:!{params.framerate},fade=out:!{fade_out_start}:!{fade_out_end}" \
  completed_bumper.mp4
  '''
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
  ffmpeg -i ${input_file} -an -map 0 -c copy -f segment -segment_time 10 output_%03d.${input_extension}
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
  if (!params.srt) {
    publishDir "$workflow.projectDir", mode: 'move'
  }
  input:
  file segment_files from segments_encoded.toList()
  file 'input.aac' from input_audio
  output:
  file 'completed.mp4' optional true into file_output
  file 'pre_completed.mp4' optional true into file_optional_output
  shell:
  '''
  files=(!{segment_files})
  output_filename='completed.mp4'
  srt="!{subtitles}"
  IFS=$"\n"
  sorted=($(sort <<<"${files[*]}"))
  for i in ${sorted[@]}; do
    echo "file $i" >> concatlist.txt
  done
  if [[ ! -z "${srt}" ]]; then
    output_filename='pre_completed.mp4'
  fi
  ffmpeg -f concat -i concatlist.txt -i input.aac -c copy "${output_filename}"
  '''
}

/*
 * In the subtitles process we add subtitles if needed.
 */
process subtitles {
  publishDir "$workflow.projectDir", mode: 'move'
  input:
  file 'pre_completed.mp4' from file_optional_output
  file srt_file from srt_file
  output:
  file 'completed.mp4' into file_srt_output

  shell:
  '''
  ffmpeg -i pre_completed.mp4 !{subtitles} completed.mp4
  '''
}

workflow.onComplete {
  println "Your Video is Ready!"
}