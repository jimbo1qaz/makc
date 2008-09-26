package {
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.Shape;
	import flash.events.TimerEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
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

			if (!texture.special) {
				// make new bitmap with light-mapped texture
				// parser assumes all shimmering lights are at their peak value
				bmData = reader.buildLightMap(face, bmData);

				light = true;
				lightMatrix = new Matrix;

				// light-mapped textures span across all the face
				lightMatrix.translate ( -face.min_s, -face.min_t);
				lightMatrix.scale (1/(face.max_s -face.min_s), 1/(face.max_t -face.min_t));
			} else

			if (texture.animated) {

				// make new bitmap in case our face is special and animated
				// TODO think about animated features under light maps...
				bmData = new BitmapData (texture.bitmap.width, texture.bitmap.height);
				bmData.draw (texture.bitmap);

				// launch the timer
				var tt:Timer = new Timer (100); tt.addEventListener (TimerEvent.TIMER, onTimer); tt.start ();

				///if (texture.name.charAt (0) == "*") {
					// this is always lava (special and animated)
					lava = true;
					lavaMatrix = new Matrix;
				///}
			}

			super (bmData);
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
			if (light) {
				var faceArray:Array = mesh.faces.toArray (true);
				for each (var face:Face in faceArray) {
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
				bmData.lock ();
				bmData.draw (texture.bitmap, lavaMatrix); lavaMatrix.tx -= w;
				bmData.draw (texture.bitmap, lavaMatrix); lavaMatrix.tx += w;
				bmData.unlock ();
			}
		}
	}
}