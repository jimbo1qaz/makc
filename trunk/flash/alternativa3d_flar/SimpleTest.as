package {

	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.media.Camera;
	import flash.media.Video;

	import org.libspark.flartoolkit.core.FLARCode;
	import org.libspark.flartoolkit.core.FLARMat;
	import org.libspark.flartoolkit.core.param.FLARParam;
	import org.libspark.flartoolkit.core.raster.rgb.FLARRgbRaster_BitmapData;
	import org.libspark.flartoolkit.core.transmat.FLARTransMatResult;
	import org.libspark.flartoolkit.core.types.FLARIntSize;
	import org.libspark.flartoolkit.detector.FLARSingleMarkerDetector;

	import alternativa.engine3d.core.*
	import alternativa.engine3d.display.*
	import alternativa.engine3d.materials.*
	import alternativa.engine3d.primitives.*
	import alternativa.types.*

	/**
	* Simple FLARToolKit + Alternativa3D test.
	* @author makc
	*/

	public class SimpleTest extends Sprite {

		protected var video:Video;
		protected var videoSnapshot:BitmapData;
		protected var webcam:Camera;

		[Embed(source='../data/camera_para.dat', mimeType='application/octet-stream')]
		protected var CameraData:Class;
		[Embed(source='../data/test.pat', mimeType='application/octet-stream')]
		protected var MarkerData:Class;

		protected const MarkerSize:Number = 100;

		protected var param:FLARParam;
		protected var code:FLARCode;
		protected var raster:FLARRgbRaster_BitmapData;
		protected var detector:FLARSingleMarkerDetector;
		protected var result:FLARTransMatResult;

		protected var base:Object3D;
		protected var box:Box;
		protected var m:Matrix3D = new Matrix3D;
		protected var scene:Scene3D;
		protected var view:View;

		[SWF(width=640,height=480)]
		public function SimpleTest () {
			scaleX = scaleY = 2;

			webcam = Camera.getCamera ();
			if (!webcam) throw new Error ('No webcam :(');

			webcam.setMode(320, 240, stage.frameRate);
			video = new Video (320, 240); video.attachCamera (webcam); addChild (video);
			videoSnapshot = new BitmapData (320, 240, false, 0);

			param = new FLARParam ();
			param.loadARParam (new CameraData);
			param.changeScreenSize (320, 240);

			code = new FLARCode (16, 16);
			code.loadARPatt (new MarkerData);

			raster = new FLARRgbRaster_BitmapData (videoSnapshot);
			detector = new FLARSingleMarkerDetector (param, code, MarkerSize);
			result = new FLARTransMatResult ();

			scene = new Scene3D; scene.root = new Object3D;
			view = new View; view.camera = new Camera3D;

			// set up view based on param
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
			const tan:Number = 1 / mp5 * Math.sqrt (size.w * size.w + size.h * size.h) / size.h;

			view.width = size.w; view.height = size.h;
			view.camera.fov = 2 * Math.atan (tan);
			scene.root.addChild (view.camera);
			addChild (view);

			base = new Object3D;
			scene.root.addChild(base);

			box = new Box (MarkerSize, MarkerSize, MarkerSize);
			box.cloneMaterialToAllSurfaces (new FillMaterial (0x7FFF00, 1, "normal", 2, 0x7F));

			box.z = MarkerSize / 2; base.addChild(box);

			addEventListener (Event.ENTER_FRAME, onEnterFrame);
		}


		protected function onEnterFrame (e:Event):void {
			videoSnapshot.draw (video);

			var a:Number = 0;
			if (detector.detectMarkerLite (raster, 128)) {
				a = detector.getConfidence ();

				detector.getTransformMatrix (result);

				m.a = result.m00; m.b = result.m01; m.c = result.m02; m.d = result.m03;
				m.e = result.m10; m.f = result.m11; m.g = result.m12; m.h = result.m13;
				m.i = result.m20; m.j = result.m21; m.k = result.m22; m.l = result.m23;

				//var obj:Object3D = base;
				var obj:Object3D = view.camera; m.invert ();

				// m is not scaled, but we shall calculate scales any way, just to be NaN-safe
				var sx:Number = Math.sqrt (m.a * m.a + m.e * m.e + m.i * m.i);
				var sy:Number = Math.sqrt (m.b * m.b + m.f * m.f + m.j * m.j);
				var sz:Number = Math.sqrt (m.c * m.c + m.g * m.g + m.k * m.k);

				var sinY:Number = m.i / sx;
				if (-1 < sinY && sinY < 1) {
					obj.rotationY = -Math.asin (sinY);
					obj.rotationX = Math.atan2 (m.j * sz, m.k * sy);
					obj.rotationZ = Math.atan2 (m.e, m.a);
				} else {
					obj.rotationY = (sinY > 0) ? -Math.PI / 2 : Math.PI / 2;
					obj.rotationX = 0;
					obj.rotationZ = Math.atan2 (-m.b, m.f);
				}

				obj.x = m.d;
				obj.y = m.h;
				obj.z = m.l;

			}

			for each (var s:Surface in box.surfaces) s.material.alpha = a;
			scene.calculate ();
		}
	}

}