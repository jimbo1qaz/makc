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
					lava = true;
					lavaColorTransform = new ColorTransform;
					lavaMatrix = new Matrix;
				}
			}
		}

		private var t:Number = 0;

		private var lava:Boolean = false;
		private var lavaColorTransform:ColorTransform, lavaMatrix:Matrix;

		private function onTimer (e:TimerEvent):void {
			// count the time
			t += 0.1; if (t > 6.2831853) t -= 6.2831853;

			if (lava) {
				// scroll the bloody lava
				lavaColorTransform.redOffset = 50 + 77 * (1 + Math.sin (t));
				lavaColorTransform.greenMultiplier = lavaColorTransform.blueMultiplier = 0.5 + 0.5 * (1 + Math.cos (t));
				var w:Number = bitmapData.width;
				lavaMatrix.tx ++; if (lavaMatrix.tx > bitmapData.width) lavaMatrix.tx -= bitmapData.width;
				bitmapData.draw (texture.bitmap, lavaMatrix, lavaColorTransform);
				lavaMatrix.tx -= bitmapData.width;
				bitmapData.draw (texture.bitmap, lavaMatrix, lavaColorTransform);
				lavaMatrix.tx += bitmapData.width;
			}
		}
	}
}