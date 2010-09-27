package {
	import com.bit101.components.HSlider;
	import com.bit101.components.Label;
	import com.bit101.components.PushButton;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.IBitmapDrawable;
	import flash.display.Loader;
	import flash.display.Shader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.BlurFilter;
	import flash.filters.ShaderFilter;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	[SWF (width=480,height=480)]
	public class SlopeEstimator extends Sprite {
		public var video:Video;
		public var source:IBitmapDrawable;
		public var file:FileReference;
		public var loader:Loader;
		public var timeout:uint = 0;
		public var resized:BitmapData;
		public var input:BitmapData;
		public var output:BitmapData;
		public var bfilter:BlurFilter;
		public var sfilter:ShaderFilter;
		public var kslider:HSlider;
		public var info:Label;
		public function SlopeEstimator () {
			stage.scaleMode = "noScale";
			// for lines to draw fast
			stage.quality = "low";
			// set up webcam feed
			stage.frameRate = 25;
			var cam:Camera = Camera.getCamera ();
			cam.setMode (320, 240, stage.frameRate);
			source = video = new Video; video.attachCamera (cam);
			video.x = 320; video.scaleX = -1;
			addChild (video);
			// set up file feed
			file = new FileReference;
			file.addEventListener (Event.SELECT, onFileSelected);
			file.addEventListener (Event.COMPLETE, onFileLoaded);
			// set up images
			with (addChild (new Bitmap (resized = new BitmapData (320, 240, true, 0)))) {
				x = 320; scaleX = -1;
			}
			var ibmp:Bitmap = new Bitmap (input = new BitmapData (160, 120, false, 0));
			ibmp.x = 320; addChild (ibmp);
			var obmp:Bitmap = new Bitmap (output = input.clone ());
			obmp.x = 320; obmp.y = 120; addChild (obmp);
			// set up filters
			bfilter = new BlurFilter (4, 4, 2);
			[Embed(source='SlopeEstimator.pbj', mimeType='application/octet-stream')] var PBJData:Class;
			sfilter = new ShaderFilter (new Shader (new PBJData));
			// image load button
			var button:PushButton = new PushButton (this, 0, 0, "LOAD IMAGE", onButtonClicked);
			// treshold slider
			var tslider:HSlider = new HSlider (this, 0, 0, onTSlider);
			tslider.minimum = 0; tslider.maximum = 9; tslider.tick = 0.01;
			tslider.value = sfilter.shader.data.threshold.value [0];
			tslider.x = 320 + (160 - tslider.width) / 2;
			tslider.y = 240 - tslider.height;
			// blur slider
			var bslider:HSlider = new HSlider (this, 0, 0, onBSlider);
			bslider.minimum = 1.0; bslider.maximum = 8.0; bslider.tick = 1.0;
			bslider.value = bfilter.blurX;
			bslider.x = 320 + (160 - bslider.width) / 2;
			bslider.y = 120 - bslider.height;
			// locality slider
			kslider = new HSlider (this, 250, 270);
			kslider.minimum = 10; kslider.maximum = 60; kslider.tick = 5.0;
			kslider.value = 30;
			// info label
			info = new Label (this, 250, 250, "");
			// processing
			addEventListener (Event.ENTER_FRAME, loop);
        }
		public var h_linear:Vector.<Number> = new Vector.<Number> (768, true);
		public function loop (e:Event):void {
			input.fillRect (input.rect, 0); input.draw (source,
				new Matrix (-0.5, 0, 0, 0.5, 160), null, null, null, true
			);
			input.applyFilter (input, input.rect, input.rect.topLeft, bfilter);
			output.applyFilter (input, input.rect, output.rect.topLeft, sfilter);
			// fetch results
			var r:Rectangle = output.rect; r.inflate ( -2 * bfilter.blurX, -2 * bfilter.blurY);
			var h:Vector.<Vector.<Number>> = output.histogram (r);
			// copy to linear array, and find max value
			var h_max:Number = 0;
			for (var i:int = 0; i < 256 * 3; i++) {
				if (i % 256 == 0) continue;
				var c:Number = h [i >> 8] [i % 256];
				if (c > h_max) h_max = c;
				h_linear [i] = c;
			}
			for (i = 0; i < 3; i++) {
				h_linear [256 * i] = 0.5 * (
					h_linear [(256 * i - 1 + 768) % 768] +
					h_linear [(256 * i + 1 + 768) % 768]
				);
			}
			// find local maxima (and draw them)
			graphics.clear ();
			var j:int = 0, K:int = kslider.value;
			for (i = 0; i < 256 * 3; i++) {
				var is_loc_max:Boolean = true;
				var h_i:Number = h_linear [i];
				for (var k:int = -K; k < K; k++) {
					if (k == 0) continue;
					if (h_linear [(i + 768 + k) % 768] >= h_i) {
						is_loc_max = false; break;
					}
				}
				if (is_loc_max) {
					j++;
					var n:Number = h_linear [i] / h_max;
					graphics.lineStyle (2, [65536, 256, 1][i >> 8] * (i % 256));
					var a:Number = Math.PI * i / (256 * 3 - 1);
					graphics.moveTo (2, 360);
					graphics.lineTo (2 + n * 120 * Math.sin (a), 360 - n * 120 * Math.cos (a));
				}
			}
			info.text = j + " local maxima";
		}
		public function onTSlider (e:Event):void {
			sfilter.shader.data.threshold.value [0] = HSlider (e.target).value;
		}
		public function onBSlider (e:Event):void {
			bfilter.blurX = bfilter.blurY = HSlider (e.target).value;
		}
        public function onButtonClicked (e:MouseEvent):void {
			file.browse ([new FileFilter ("Images", "*.jpe;*.jpeg;*.jpg;*.gif;*.png")]);
		}
        public function onFileSelected (e:Event):void { file.load (); }
        public function onFileLoaded (e:Event):void {
			loader = new Loader;
			loader.loadBytes (file.data);
			// why can't Event.COMPLETE just fuckin' work?
			addEventListener (Event.ENTER_FRAME, onImageReady);
		}
		public function onImageReady(e:Event):void {
			if (loader.content) {
				removeEventListener (Event.ENTER_FRAME, onImageReady);
				resized.draw (loader.content,
					new Matrix (
						-320 / loader.content.width, 0, 0,
						+240 / loader.content.height, 320
					), null, null, null, true
				);
				source = resized;
				if (timeout != 0) clearTimeout (timeout);
				timeout = setTimeout (backToWebcamFeed, 15000);
			}
		}
		public function backToWebcamFeed ():void {
			resized.fillRect (resized.rect, 0); source = video;
		}
	}
}