#ifndef FFMPEG_H_
#define FFMPEG_H_

extern "C" { // ffmpeg
#include <avformat.h>
#include <swscale.h>
}

#ifndef INT64_C // ffmpeg hates msvc
#define INT64_C(val) val##i64
#endif

#define STREAM_FRAME_RATE 25
#define STREAM_PIX_FMT PIX_FMT_YUV420P

#define STREAM_BIT_RATE 90000000
#define STREAM_BUFFER_SIZE 90000000

AVStream *add_video_stream(AVFormatContext *oc, CodecID codec_id, int width, int height);
void open_video(AVFormatContext *oc, AVStream *st);
void close_video(AVFormatContext *oc, AVStream *st);

#endif