#include <atlbase.h> // CComBSTR (also helps gdiplus.h to compile :)
//#include <gdiplus.h> // (add gdiplus.lib)

#include <stdio.h>
#define snprintf _snprintf

#include "ffmpeg.h"

#include "ConvexPolRas.h"

#define STRIDE_3ALIGN4(W) (((3*((W)+1))>>2)*4)

void saveBitmap(unsigned char *pBuffer, char *pFileName) {
	PBITMAPINFOHEADER pbih = (PBITMAPINFOHEADER) pBuffer;
	DWORD dwTmp;

	HANDLE hf = CreateFile(pFileName, 
               GENERIC_READ | GENERIC_WRITE, 
               (DWORD) 0, 
               NULL, 
               CREATE_ALWAYS, 
               FILE_ATTRIBUTE_NORMAL, 
               (HANDLE) NULL); 
	if (hf == INVALID_HANDLE_VALUE)
		return/*throw 0*/;

	BITMAPFILEHEADER hdr;
	hdr.bfType = 0x4d42; // 0x42 = "B" 0x4d = "M"
	hdr.bfSize = (DWORD) (sizeof(BITMAPFILEHEADER) + 
             pbih->biSize + pbih->biClrUsed 
             * sizeof(RGBQUAD) + pbih->biSizeImage);
	hdr.bfReserved1 = hdr.bfReserved2 = 0;
	hdr.bfOffBits = (DWORD) sizeof(BITMAPFILEHEADER) + 
             pbih->biSize + pbih->biClrUsed 
             * sizeof (RGBQUAD);
	if (!WriteFile(hf, (LPVOID) &hdr, sizeof(BITMAPFILEHEADER), (LPDWORD) &dwTmp,  NULL))
		return/*throw 0*/;
	if (!WriteFile(hf, (LPVOID) pbih, sizeof(BITMAPINFOHEADER) + pbih->biClrUsed * sizeof (RGBQUAD), (LPDWORD) &dwTmp, NULL))
		return/*throw 0*/;

	LPBYTE lpBits = ((LPBYTE)pbih + (WORD)(pbih->biSize));
	if (!WriteFile(hf, (LPSTR) lpBits, (int) pbih->biSizeImage, (LPDWORD) &dwTmp, NULL))
		return/*throw 0*/;

	if (FAILED(CloseHandle(hf)))
		return/*throw 0*/;
};

unsigned char *pBuffer, *pBits; int iWidth, iHeight, iWidth2, iHeight2, iColor, iStride;

#define CH_BLU 0
#define CH_GRE 1
#define CH_RED 2

void drawPoint1 (int x, int y) {
	y = iHeight - y;
	x += iWidth2; y -= iHeight2;
	// left view: offset x-s by -0.05*w, set red pixels only
	x -= int (0.05 * iWidth);
	if ((x > -1) && (y > -1) && (x < iWidth) && (y < iHeight)) {
		unsigned char *pPixel = &(pBits [y * iStride + x * 3]);
		pPixel [CH_RED] = (iColor & 0xFF0000) >> 16;
	}
}

void drawPoint2 (int x, int y) {
	y = iHeight - y;
	x += iWidth2; y -= iHeight2;
	// right view: set 0.9 of green and blue
	if ((x > -1) && (y > -1) && (x < iWidth) && (y < iHeight)) {
		unsigned char *pPixel = &(pBits [y * iStride + x * 3]);
		pPixel [CH_GRE] = (9 * ((iColor & 0xFF00) >> 8)) / 10;
		pPixel [CH_BLU] = iColor & 0xFF;
	}
}

AVFrame *picture, *tmp_picture;
uint8_t *video_outbuf;
int video_outbuf_size;

void write_video_frame(AVFormatContext *oc, AVStream *st) {
	AVCodecContext *c = st->codec;
	static struct SwsContext *img_convert_ctx;
	if (img_convert_ctx == NULL) {
        img_convert_ctx = sws_getContext(
			c->width, c->height,
			PIX_FMT_BGR24,
			c->width, c->height,
			c->pix_fmt,
			SWS_BICUBIC, NULL, NULL, NULL
		);
        if (img_convert_ctx == NULL) {
            fprintf(stderr, "Cannot initialize the conversion context\n");
            exit(1);
        }
    }

	// fill_yuv_image call in ffmpeg's output_example.c - we copy pBits to picture->data [0]
	for (int y = 0; y < iHeight; y++)
		memcpy (tmp_picture->data[0] + (iHeight - y - 1) * iStride,
			pBits + y * iStride, iStride);

	sws_scale(img_convert_ctx, tmp_picture->data, tmp_picture->linesize,
        0, c->height, picture->data, picture->linesize);

	/* encode the image */
	int out_size = avcodec_encode_video(c, video_outbuf, video_outbuf_size, picture);
    /* if zero size, it means the image was buffered */
    if (out_size > 0) {
        AVPacket pkt;
        av_init_packet(&pkt);

        if (c->coded_frame->pts != AV_NOPTS_VALUE)
            pkt.pts= av_rescale_q(c->coded_frame->pts, c->time_base, st->time_base);
        if(c->coded_frame->key_frame)
            pkt.flags |= PKT_FLAG_KEY;
        pkt.stream_index= st->index;
        pkt.data= video_outbuf;
        pkt.size= out_size;

        /* write the compressed frame in the media file */
		if (av_write_frame(oc, &pkt) != 0) {
			fprintf(stderr, "Error while writing video frame\n");
			exit(1);
		}
    }
}





int main(int argc, char* argv[])
{
	// 1st, create 1280x960 24bpp bitmap
	iWidth  = 2 * 640; iWidth2 = iWidth / 2;
	iHeight = 2 * 480; iHeight2 = iHeight / 2;
	iStride = STRIDE_3ALIGN4 (iWidth);
	int iBufferLength = sizeof (BITMAPINFOHEADER) + iStride * iHeight;
	pBuffer = new unsigned char [iBufferLength]; ZeroMemory (pBuffer, iBufferLength);

	PBITMAPINFOHEADER pbih = (PBITMAPINFOHEADER) pBuffer; ZeroMemory (pbih, sizeof (BITMAPINFOHEADER));
	pbih->biBitCount = 24; pbih->biCompression = BI_RGB; pbih->biHeight = iHeight; pbih->biWidth = iWidth;
	pbih->biPlanes = 1; pbih->biSize = sizeof (BITMAPINFOHEADER); pbih->biSizeImage = iStride * pbih->biHeight;
	pbih->biXPelsPerMeter = pbih->biYPelsPerMeter = 0;

	pBits = (pBuffer + (WORD)(((PBITMAPINFOHEADER)pBuffer)->biSize));

	// 2nd, prepare video stuff
	av_register_all();

	char *filename = "pt3d.mp4"; AVOutputFormat *fmt = NULL;
	if (argc == 2) filename = argv [1];
	fmt = guess_format(NULL, argv [1], NULL);
	if (!fmt) fmt = guess_format("mp4", NULL, NULL);
	fmt->audio_codec = CODEC_ID_NONE;

	AVFormatContext *oc = av_alloc_format_context();
	oc->oformat = fmt; snprintf(oc->filename, sizeof(oc->filename), "%s", filename);

	AVStream *video_st = add_video_stream(oc, fmt->video_codec, iWidth, iHeight);

	av_set_parameters(oc, NULL); dump_format(oc, 0, filename, 1);
	open_video(oc, video_st); url_fopen(&oc->pb, filename, URL_WRONLY);
	av_write_header(oc);


	// 3rd, read flash log file
	FILE *pFile; char line [100];
	bool view1 = true; int x [100], y [100], n = 0, f = 0, np = 0;
	if (( pFile = fopen ("flashlog.txt" , "r")) != NULL) {
		while (fgets (line , 100 , pFile) != NULL) {
			if ((n > 0)
				&& ((line [0] == 'v') || (line [0] == 'c'))) {
				// render polygon
				mpConvexPolRas (x, y, n, view1 ? drawPoint1 : drawPoint2);

				n = 0; np++;
			}

			if (line [0] == 'v') {
				if (!view1 && (line [1] == '1')) {
					// save frame
					write_video_frame(oc, video_st);

					// show stats
					printf ("\r%d bytes, frame %d: %d polys            ",
						ftell (pFile), f, np);
					if (f % 20 == 0) {
						char frameFilename [16];
						sprintf (frameFilename, "frame%03d.bmp", f / 20);
						saveBitmap (pBuffer, frameFilename);
					}
					np = 0; f++;

					ZeroMemory (pBits, ((PBITMAPINFOHEADER)pBuffer)->biSizeImage);
					//if (f > 123) break;
				}

				view1 = (line [1] == '1');
			}
			else if (line [0] == 'c') {
				line [8] = 0;
				line [7] = line [6];
				line [6] = line [5];
				line [5] = line [4];
				line [4] = line [3];
				line [3] = line [2];
				line [2] = line [1];
				line [1] = 'x';
				line [0] = '0';
				sscanf (line, "%i", &iColor);
			}
			else if (n + 1 < 100) {
				sscanf (line, "%d %d", &(x [n]), &(y [n])); n++;
			}
		}
		fclose (pFile);
	}

	// release stuff
	delete pBuffer;
	close_video(oc, video_st); av_write_trailer(oc);
	for(unsigned int i = 0; i < oc->nb_streams; i++) {
        av_freep(&oc->streams[i]->codec);
        av_freep(&oc->streams[i]);
    }
	url_fclose(oc->pb);
	av_free(oc);

	puts ("");
	puts ("Done. Enjoy.");

	return 0;
}

