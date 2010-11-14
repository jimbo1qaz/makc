package {
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.media.Camera;
	import flash.media.Video;
	import org.libspark.flartoolkit.core.FLARCode;
	import org.libspark.flartoolkit.core.FLARMat;
	import org.libspark.flartoolkit.core.param.FLARParam;
	import org.libspark.flartoolkit.core.raster.rgb.FLARRgbRaster_BitmapData;
	import org.libspark.flartoolkit.core.transmat.FLARTransMatResult;
	import org.libspark.flartoolkit.core.types.FLARIntSize;
	import org.libspark.flartoolkit.detector.FLARSingleMarkerDetector;
	import net.hires.debug.Stats;
	/**
	 * Testing FLARToolKit v1.
	 * @see http://www.libspark.org/svn/as3/FLARToolKit/branches/ver1_x_x/src/org/libspark/flartoolkit/ r4416
	 * @author makc
	 */
	[SWF(width=320,height=240,frameRate=30)]
	public class FLARTest extends Sprite {
		public var camera:Camera
		public var video:Video;
		public var overlay:Sprite;
		public var buffer:BitmapData;
		public var bufferMatrix:Matrix;
		public var param:FLARParam;
		public var focalLength:Number;
		public var code:FLARCode;
		public var raster:FLARRgbRaster_BitmapData;
		public var result:FLARTransMatResult;
		public var detect:FLARSingleMarkerDetector;
		public function FLARTest () {
			addChild (video = new Video);
			addChild (new Stats);
			addChild (overlay = new Sprite);
			// small buffer to get better performance
			buffer = new BitmapData (160, 120, false, 0);
			bufferMatrix = new Matrix (0.5, 0, 0, 0.5);
			raster = new FLARRgbRaster_BitmapData (buffer);
			// get webcam
			camera = Camera.getCamera ();
			camera.setMode (320, 240, stage.frameRate);
			video.attachCamera (camera);
			// almost FLARToolKit standard param, but slightly better
			param = new FLARParam;
			param.getDistortionFactor ().setValue ([320, 240, 26.2, 1]);
			param.getPerspectiveProjectionMatrix ().setValue (
				[713,   0, 320, 0,
				   0, 713, 240, 0,
				   0,   0,   1, 0]);
			param.changeScreenSize (160, 120); calculateFocalLength ();
			// 50% 16x16 hiro pattern
			[Embed(source='hiro.pat',mimeType='application/octet-stream')] var Hiro:Class;
			code = new FLARCode (16, 16);
			code.loadARPatt (new Hiro);
			// result
			result = new FLARTransMatResult;
			// single marker detector
			detect = new FLARSingleMarkerDetector (param, code, 2);
			// process whole rect every frame (not smart :)
			addEventListener (Event.ENTER_FRAME, loop);
		}
		public var threshold:int = 128;
		public function loop (e:Event):void {
			overlay.graphics.clear ();
			// draw frame into buffer
			buffer.draw (video, bufferMatrix, null, null, null, true);
			// try to detect something
			if (detect.detectMarkerLite (raster, threshold)) {
				var confidence:Number = detect.getConfidence ();
				if (confidence > 0.3) {
					// detected, draw
					detect.getTransformMatrix (result);
					renderOverlay ();
				} else {
					threshold = 1 + Math.round (253 * Math.random ());
				}
			} else {
				threshold = 1 + Math.round (253 * Math.random ());
			}
		}
		public function renderOverlay ():void {
			// origin
			project (result.m03, result.m13, result.m23, pt1);
			// x
			project (result.m03 + result.m00, result.m13 + result.m10, result.m23 + result.m20, pt2);
			// y
			project (result.m03 + result.m01, result.m13 + result.m11, result.m23 + result.m21, pt3);
			// z
			project (result.m03 + result.m02, result.m13 + result.m12, result.m23 + result.m22, pt4);

			overlay.graphics.lineStyle (1, 0xFF0000);
			overlay.graphics.moveTo (pt1.x, pt1.y); overlay.graphics.lineTo (pt2.x, pt2.y);
			overlay.graphics.lineStyle (1, 0x0000FF);
			overlay.graphics.moveTo (pt1.x, pt1.y); overlay.graphics.lineTo (pt3.x, pt3.y);
			overlay.graphics.lineStyle (1, 0x00FF00);
			overlay.graphics.moveTo (pt1.x, pt1.y); overlay.graphics.lineTo (pt4.x, pt4.y);
		}
		public var pt1:Point = new Point;
		public var pt2:Point = new Point;
		public var pt3:Point = new Point;
		public var pt4:Point = new Point;
		public function project (x:Number, y:Number, z:Number, out:Point):void {
			out.x = 160 + 2 * x * focalLength / z;
			out.y = 120 + 2 * y * focalLength / z;
		}
		public function calculateFocalLength ():void {
			// this is hairy way of doing it, should be simpler...
			const size:FLARIntSize = param.getScreenSize ();
			const tMat:FLARMat = new FLARMat (3, 4);
			const iMat:FLARMat = new FLARMat (3, 4);
			param.getPerspectiveProjectionMatrix ().decompMat (iMat, tMat);
			const i:Array = iMat.getArray ();
			const t:Array = tMat.getArray ();
			const h1:Number = size.h - 1;
			const p11:Number = (h1 * i[2][1] - i[1][1]) / i[2][2];
			const p12:Number = (h1 * i[2][2] - i[1][2]) / i[2][2];
			const q11:Number = -(2 * p11 / h1);
			const q12:Number = -(2 * p12 / h1) + 1.0;
			const mp5:Number = q11 * t[1][1] + q12 * t[2][1];
			focalLength = 0.5 * mp5 * size.h;
		}
	}
}