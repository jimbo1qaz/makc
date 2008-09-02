package {
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.Shape;
	import flash.events.TimerEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Timer;

	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.Mesh;
	import alternativa.types.Texture;

	import com.suite75.quake1.io.*;

	/**
	 * This class performs special effects on textures.
	 */
	public class QuakeTexture extends Texture {

		private var bmData:BitmapData;
		private var texture:BspTexture;
		private var face:BspFace;
		private var reader:BspReader;

		public function QuakeTexture (texture:BspTexture, face:BspFace, reader:BspReader) {
			// to work with new swc ver...
			this.bmData = texture.bitmap;

			this.texture = texture;
			this.face    = face;
			this.reader  = reader;

			if (texture.animated || face.lightmap_offset >= 0) {

				// make new bitmap in case our face is lit or animated
				bmData = new BitmapData (texture.bitmap.width, texture.bitmap.height);
				bmData.draw (texture.bitmap);

				// launch the timer
				var tt:Timer = new Timer (100); tt.addEventListener (TimerEvent.TIMER, onTimer); tt.start ();

				if (texture.name.charAt (0) == "*") {
					// this is lava
					lava = true;
					lavaMatrix = new Matrix;
				}

				else if (face.lightmap_offset >= 0) {
					// this face is lit
					light = true;
					lightMatrix = new Matrix; buildLightMaps ();
				}
			}

			super (bmData);
		}

		/**
		 * This builds light map.
		 * I pulled it here because BspReader does not seem to implement it correctly.
		 * 
		 * There are up to 4 lightmaps, the result is weighted sum; face.lightmap_styles
		 * defines each lightmap weight. Possible values include:
		 *   0 - static light
		 *   1 - fast pulsating light
		 *   2 - slow pulsating light
		 * 255 - map not used
		 */
		private function buildLightMaps ():void {
/* can't get this to work :( something about light maps is broken in parser.

			// lightmaps dimensions
			var se_s:int = (face.extents[0] >> 4) + 1;
			var se_t:int = (face.extents[1] >> 4) + 1, se_size:int = se_s * se_t;

			// texture tiling matrix
			lightMatrix.translate ( -face.min_s, -face.min_t);
			lightMatrix.scale (1 / (face.max_s - face.min_s), 1 / (face.max_t - face.min_t));

			// collect static lightmaps
			var bm:BitmapData = new BitmapData (16 * se_s, 16 * se_t, false, 0); bm.lock ();
			var lightdata:ByteArray = reader.data,
				lightlump:BspLump = reader.header.lumps[BspLump.LUMP_LIGHTING],
				r:Rectangle = new Rectangle (0, 0, 16, 16);
			lightdata.position = lightlump.offset + face.lightmap_offset;
			for (var ds:int = 0; ds < se_s; ds++)
			for (var dt:int = 0; dt < se_t; dt++) {
				var c:int = 128; // ambient;
				for (var maps:int = 0; maps < 4; maps++)
				if (face.lightmap_styles [maps] == 0) {
					c += lightdata [maps * se_size + dt * se_s + ds];
				}
				if (c > 255) c = 255;
				r.x = 16 * ds; r.y = 16 * dt; bm.fillRect (r, (c << 16) | (c << 8) | c);
			}
			bm.unlock ();

			// hack to get texture back into game
			var s:Shape = new Shape;
			s.graphics.beginBitmapFill (texture.bitmap, lightMatrix);
			s.graphics.drawRect (0, 0, bm.width, bm.height);
			s.graphics.endFill ();
			bm.draw (s, null, null, BlendMode.MULTIPLY);
			// apply map
			bmData = bm;
*/
		}

		// TODO change this to handle dynamic maps
		private function applyLightMap (dest:BitmapData, map:BitmapData):void {
			dest.draw (map, lightMatrix, null, BlendMode.ADD, map.rect, true);
		}

		private var t:Number = 0;

		private var lava:Boolean = false;
		private var lavaMatrix:Matrix;

		private var light:Boolean = false;
		private var lightMatrix:Matrix;

		/**
		 * Correct UVs for light-mapped textures
		 */
		public function correctUVsInMesh (mesh:Mesh):void {
			// FIXME needless, since buildLightMaps doesnt work
			if (light && false) {
				var faceArray:Array = mesh.faces.toArray (true);
				for (var i:int = 0; i < faceArray.length; i++) {   
					var face:Face = faceArray [i];   
					face.aUV = lightMatrix.transformPoint (face.aUV);
					face.bUV = lightMatrix.transformPoint (face.bUV);
					face.cUV = lightMatrix.transformPoint (face.cUV);
				}   
			}
		}

		private function onTimer (e:TimerEvent):void {
			// count the time
			t += 0.1; if (t > 6.2831853) t -= 6.2831853;

			if (lava) {
				// scroll the lava
				var w:Number = bmData.width;
				lavaMatrix.tx ++; if (lavaMatrix.tx > w) lavaMatrix.tx -= w;
				bmData.draw (texture.bitmap, lavaMatrix); lavaMatrix.tx -= w;
				bmData.draw (texture.bitmap, lavaMatrix); lavaMatrix.tx += w;
			}
		}
	}
}