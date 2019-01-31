#!/usr/bin/env nextflow

/*
 * Copyright (c) 2019, Christopher Mundus (crashGoBoom)
 */

/*
 * Params for passing in options.
 */
params.video_input = "$baseDir/video.mov"
params.bumper_image = ''
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
srt_file = ''
watermark_file = ''
fontfile_ch = ''
videofile_ch = Channel.empty()
imagefile_ch = Channel.empty()

/*
 * If we are using a png file as the input hook up that channel and
 * leave the video file channel blank so segmenting is not attempted.
 */
if ( params.bumper_image ) {
  needs_bumper = true
  imagefile_ch = file(params.bumper_image)
} else {
  needs_bumper = ''
}


input_extension = ''
user_input = ''
if ( params.video_input ) {
  videofile_ch = file(params.video_input)
  user_input = file(params.video_input)
  input_path = user_input.getParent()
  input_extension = user_input.getExtension()
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
} else {
  srt_file = 'FALSE'
}

if (params.font) {
  fontfile_ch = file(params.font)
}

/*
 * In the create_bumper process we create a bumper video.
 */
process create_bumper {
  if (!params.video_input) {
    publishDir "$workflow.projectDir", mode: 'move'
  }
  input:
  file input_file from imagefile_ch
  file input_font from fontfile_ch
  val x from title_text
  output:
  file 'completed_bumper.mp4' optional true into bumper_file
  shell:
  '''
  ffmpeg -f lavfi -i color=c=!{params.background_color}:s=1280x720:d=!{params.duration}:r=25 \
  -i !{input_file} \
  -filter_complex \
  "[0] drawtext=fontfile=!{input_font}:fontsize=60:fontcolor=!{params.font_color}:x=(w-text_w)/2:y=(h-text_h)/1.1:text='!{x}', fade=in:0:!{params.framerate},fade=out:!{fade_out_start}:!{fade_out_end} [b]; [b] overlay=(W-w)/2:(H-h)/2, fade=in:0:!{params.framerate},fade=out:!{fade_out_start}:!{fade_out_end}" \
  needs_audio_stream.mp4
  echo "1
00:00:1,330 --> 00:00:3,528
This is a test subtitle file" >fakesubs.txt
  ffmpeg -i needs_audio_stream.mp4 -f lavfi -i anullsrc=r=48000:cl=stereo -c:a aac \
  -i fakesubs.txt -c:v copy -c:s mov_text -metadata:s:s:0 language=!{params.language} -shortest completed_bumper.mp4
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
  shell:
  '''
  seg=$(echo "!{segment_file}" | cut -f 1 -d '.')
  ffmpeg -i !{segment_file} !{watermark} -crf !{params.crf} -vcodec libx264 encoded_"${seg}".mp4
  '''
}

process finalize {
  publishDir "$workflow.projectDir", mode: 'move'
  input:
  file segment_files from segments_encoded.toList()
  file 'input.aac' from input_audio
  file srt_file from srt_file
  file bumper_file from bumper_file.ifEmpty { 'EMPTY' }
  output:
  file 'completed*.mp4' into file_output

  shell:
  '''
  function add_bumper() {
    local -r _input_file="${1}"
    local -r _output_file="${2}"
    echo "file !{bumper_file}" >concatlist.txt
    echo "file ${_input_file}" >>concatlist.txt
    ffmpeg -f concat -i concatlist.txt -scodec copy -c copy "${_output_file}"
  }

  function add_subtitles() {
    local -r _input_file="${1}"
    local -r _output_file="${2}"
    echo "Adding !{srt_file}"
    ffmpeg -i "${_input_file}" !{subtitles} "${_output_file}"
  }

  files=(!{segment_files})
  output_filename='completed.mp4'
  srt="!{subtitles}"
  bumper="!{needs_bumper}"
  IFS=$"\n"
  sorted=($(sort <<<"${files[*]}"))
  for i in ${sorted[@]}; do
    echo "file $i" >> concatlist.txt
  done
  needs=''
  if [[ -n "${srt}" ]]; then
    needs="_subs"
  fi
  if [[ -n "${bumper}" ]]; then
    needs="${needs}_bumper"
  fi
  if [[ -n "${needs}" ]]; then
    output_filename="needs${needs}.mp4"
  fi

  ffmpeg -f concat -i concatlist.txt -i input.aac -c copy "${output_filename}"

  case $output_filename in
    'needs_bumper.mp4')
      add_bumper "${output_filename}" "completed_w_bumper.mp4"
      ;;
    'needs_subs.mp4')
      add_subtitles "${output_filename}" "completed_w_subs.mp4"
      ;;
    'needs_subs_bumper.mp4')
      add_subtitles "${output_filename}" "needs_bumper.mp4"
      add_bumper "needs_bumper.mp4" "completed_w_subs_bumper.mp4"
      ;;
  esac
  '''
}

workflow.onComplete {
  println "Your Video is Ready!"
}