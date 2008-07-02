package {
	import flash.display.BitmapData;
	import flash.events.TimerEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.utils.Timer;
	import alternativa.types.Texture;

	import com.suite75.quake1.io.*;


	/**
	 * This class performs special effects on textures.
	 */
	public class QuakeTexture extends Texture {

		private var texture:BspTexture;
		private var face:BspFace;

		public function QuakeTexture (texture:BspTexture, face:BspFace) {
			super (texture.bitmap);
			this.texture = texture;
			this.face    = face;

			if (texture.animated || face.lightmap_offset >= 0) {

				// make new bitmap in case our face is lit or animated
				bitmapData = new BitmapData (texture.bitmap.width, texture.bitmap.height);
				bitmapData.draw (texture.bitmap);

				// launch the timer
				var tt:Timer = new Timer (100); tt.addEventListener (TimerEvent.TIMER, onTimer); tt.start ();

				if (texture.name.charAt (0) == "*") {
					// this is lava
					lava = true; lavaMatrix = new Matrix;
				}
/*
 * from r_light.c

static int
calc_lighting_1 (msurface_t  *surf, int ds, int dt)
{
	int         se_s = ((surf->extents[0] >> 4) + 1);
	int         se_t = ((surf->extents[0] >> 4) + 1);
	int         se_size = se_s * se_t;
	int         r = 0, maps;
	byte       *lightmap;
	unsigned int scale;

	ds >>= 4;
	dt >>= 4;

	lightmap = surf->samples;
	if (lightmap) {
		lightmap += dt * se_s + ds;

		for (maps = 0; maps < MAXLIGHTMAPS && surf->styles[maps] != 255;
			 maps++) {
			scale = d_lightstylevalue[surf->styles[maps]];
			r += *lightmap * scale;
			lightmap += se_size;
		}

		r >>= 8; // d_lightstylevalue[*] defaults to 256, hence >>= 8
	}

	ambientcolor[2] = ambientcolor[1] = ambientcolor[0] = r;

	return r;
}

called as:
		tex = surf->texinfo;

		s = DotProduct (mid, tex->vecs[0]) + tex->vecs[0][3];
		t = DotProduct (mid, tex->vecs[1]) + tex->vecs[1][3];

		if (s < surf->texturemins[0] || t < surf->texturemins[1])
			continue;

		ds = s - surf->texturemins[0];
		dt = t - surf->texturemins[1];

		if (ds > surf->extents[0] || dt > surf->extents[1])
			continue;

		if (!surf->samples)
			return 0;

		if (mod_lightmap_bytes == 1)
			return calc_lighting_1 (surf, ds, dt);

texturemins and extents:
 (dot (vertex, tex axis) + tex offset) rounded to 16
UVs:
 (above expression) / texture dimension, w or h
			
*/
			}
		}

		private var t:Number = 0;

		private var lava:Boolean = false;
		private var lavaMatrix:Matrix;

		private function onTimer (e:TimerEvent):void {
			// count the time
			t += 0.1; if (t > 6.2831853) t -= 6.2831853;

			if (lava) {
				// scroll the lava
				var w:Number = bitmapData.width;
				lavaMatrix.tx ++; if (lavaMatrix.tx > w) lavaMatrix.tx -= w;
				bitmapData.draw (texture.bitmap, lavaMatrix); lavaMatrix.tx -= w;
				bitmapData.draw (texture.bitmap, lavaMatrix); lavaMatrix.tx += w;
			}
		}
	}
}