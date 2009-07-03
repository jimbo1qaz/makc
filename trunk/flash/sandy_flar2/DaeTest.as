package  
{
	import flash.display.*;
	import flash.events.*;
	import flash.media.*
	import org.libspark.flartoolkit.core.FLARCode;
	import org.libspark.flartoolkit.core.FLARMat;
	import org.libspark.flartoolkit.core.param.FLARParam;
	import org.libspark.flartoolkit.core.raster.rgb.FLARRgbRaster_BitmapData;
	import org.libspark.flartoolkit.core.transmat.FLARTransMatResult;
	import org.libspark.flartoolkit.core.types.FLARIntSize;
	import org.libspark.flartoolkit.detector.FLARSingleMarkerDetector;
	import sandy.core.Scene3D;
	import sandy.core.scenegraph.Group;
	import sandy.parser.*;
	import sandy_flar.*;

	/**
	* FLARToolKit/Sandy tutorial, features
	* a) minimal one-file setup,
	* b) automatic thresholding,
	* c) loading collada model.
	* @author makc
	*/
	public class DaeTest extends Sprite
	{
		private var video:Video;
		private var videoSnapshot:BitmapData;
		private var webcam:Camera;

		[Embed(source='camera_para.dat', mimeType='application/octet-stream')]
		private var CameraData:Class;
		[Embed(source='test.pat', mimeType='application/octet-stream')]
		private var MarkerData:Class;

		private var param:FLARParam;
		private var code:FLARCode;
		private var raster:FLARRgbRaster_BitmapData;
		private var detector:FLARSingleMarkerDetector;
		private var result:FLARTransMatResult;

		private var container:Sprite;
		private var scene:Scene3D;
		private var stuff:FLARBaseNode;

		public function DaeTest () 
		{
			stage.scaleMode = "noScale";
			webcam = Camera.getCamera ();
			if (webcam != null) {
				webcam.setMode(320, 240, stage.frameRate);
				video = new Video (320, 240); video.attachCamera (webcam);
				videoSnapshot = new BitmapData (320, 240, false, 0);

				container = Sprite (addChild (new Sprite));
				container.addChild (video);
				container.scaleX = 2;
				container.scaleY = 2;

				param = new FLARParam ();
				param.loadARParam (new CameraData);
				param.changeScreenSize (320, 240);

				code = new FLARCode (32, 32, 80, 80);
				code.loadARPatt (new MarkerData);

				raster = new FLARRgbRaster_BitmapData (videoSnapshot);
				detector = new FLARSingleMarkerDetector (param, code, 2);
				detector.setContinueMode (false);
				result = new FLARTransMatResult ();

				scene = new Scene3D ("scene", Sprite (container.addChild (new Sprite)),
					new FLARCamera3D (param, 1e-3), new Group ("root"));
				stuff = new FLARBaseNode; scene.root.addChild (stuff);

				addEventListener (Event.ENTER_FRAME, onEnterFrame);

				var parser:IParser = Parser.create ("cube.dae", Parser.COLLADA);
				parser.addEventListener (ParserEvent.INIT, addModel);
				parser.parse();
			}			
		}

		private var threshold:Number = 0.5;
		private var confidence:Number = 0, confidenceThreshold:Number = 0.5;
		private function onEnterFrame (e:Event):void
		{
			videoSnapshot.draw (video);

			if (confidence < confidenceThreshold) {
				// randomize threshold
				threshold *= 0.8;
				threshold += 0.2 * Math.random ();
			}

			confidence = 0;
			if (detector.detectMarkerLite (raster, 255 * threshold)) {
				confidence = detector.getConfidence ();

				detector.getTransformMatrix (result);
				stuff.setTransformMatrix (result);
			}

			scene.render ();
		}

		private function addModel (p_eEvent:ParserEvent):void
		{
			stuff.addChild (p_eEvent.group);
		}

	}

}