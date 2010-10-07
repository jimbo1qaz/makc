package {
	import com.bit101.components.HSlider;
	import com.bit101.components.Label;
	import com.bit101.components.PushButton;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.IBitmapDrawable;
	import flash.display.Loader;
	import flash.display.Shader;
	import flash.display.Shape;
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
	public class DistanceEstimator extends Sprite {
		public var video:Video;
		public var source:IBitmapDrawable;
		public var file:FileReference;
		public var loader:Loader;
		public var timeout:uint = 0;
		public var resized:BitmapData;
		public var input:BitmapData;
		public var output:BitmapData;
		public var output2:BitmapData;
		public var bfilter:BlurFilter;
		public var sfilter:ShaderFilter;
		public var dfilter:ShaderFilter;
		public var kslider:HSlider;
		public var kslider2:HSlider;
		public var info:Label;
		public var info2:Label;
		public var lines:Shape;
		public function DistanceEstimator () {
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
			var obmp2:Bitmap = new Bitmap (output2 = output.clone ());
			obmp2.x = 320; obmp2.y = 240; addChild (obmp2);
			// set up filters
			bfilter = new BlurFilter (4, 4, 2);
			[Embed(source='SlopeEstimator.pbj', mimeType='application/octet-stream')] var PBJData:Class;
			sfilter = new ShaderFilter (new Shader (new PBJData));
			[Embed(source='DistanceEstimator.pbj', mimeType='application/octet-stream')] var PBJData2:Class;
			dfilter = new ShaderFilter (new Shader (new PBJData2));
			// lines
			lines = new Shape; addChild (lines); lines.scrollRect = resized.rect;
			// image load button
			var button:PushButton = new PushButton (this, 0, 0, "LOAD IMAGE", onButtonClicked);
			// treshold slider
			var tslider:HSlider = new HSlider (this, 0, 0, onTSlider);
			tslider.minimum = 0; tslider.maximum = 9; tslider.tick = 0.01;
			tslider.value = sfilter.shader.data.threshold.value [0];
			tslider.x = 320 + (160 - tslider.width) / 2;
			tslider.y = 240 - tslider.height;
			var tslider2:HSlider = new HSlider (this, 0, 0, onTSlider2);
			tslider2.minimum = 0.001; tslider2.maximum = 0.1; tslider2.tick = 0.001;
			tslider2.value = dfilter.shader.data.threshold.value [0];
			tslider2.x = 320 + (160 - tslider2.width) / 2;
			tslider2.y = 360 - tslider2.height;
			// blur slider
			var bslider:HSlider = new HSlider (this, 0, 0, onBSlider);
			bslider.minimum = 1.0; bslider.maximum = 8.0; bslider.tick = 1.0;
			bslider.value = bfilter.blurX;
			bslider.x = 320 + (160 - bslider.width) / 2;
			bslider.y = 120 - bslider.height;
			// locality sliders
			kslider = new HSlider (this, 200, 270);
			kslider.minimum = 10; kslider.maximum = 60; kslider.tick = 5.0;
			kslider.value = 30;
			kslider2 = new HSlider (this, 200, 310);
			kslider2.minimum = 2; kslider2.maximum = 22; kslider2.tick = 2.0;
			kslider2.value = 2;
			// info label
			info = new Label (this, 200, 250, "");
			info2 = new Label (this, 200, 290, "");
			// processing
			addEventListener (Event.ENTER_FRAME, loop);
        }
		public var h_linear:Vector.<Number> = new Vector.<Number> (768, true);
		public var h_indices:Vector.<int> = new Vector.<int> (50, true);
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
			var h_max:Number = copyToLinearArray (h, h_linear);
			// find local maxima (and draw them)
			graphics.clear ();
			var j:int = findLocalMaxima (h_linear, h_indices, kslider.value);
			var i_max:int = 0, n_max:Number = 0;
			for (var k:int = 0; k < j; k++) {
				var i:int = h_indices [k];
				var n:Number = h_linear [i] / h_max;
				if (n_max < n) {
					n_max = n;
					i_max = i;
				}
				graphics.lineStyle (2, [65536, 256, 1][i >> 8] * (i % 256));
				var a:Number = Math.PI * i / (256 * 3 - 1);
				graphics.moveTo (2, 360);
				graphics.lineTo (2 + n * 120 * Math.sin (a), 360 - n * 120 * Math.cos (a));
			}
			info.text = j + " local maxima (angle)";
			if (j < 1) {
				output2.fillRect (output2.rect, 0);
				lines.graphics.clear ();
				return;
			}
			// mark dominant angle
			a = Math.PI * i_max / (256 * 3 - 1);
			graphics.lineStyle (2, 0);
			graphics.beginFill (0xFFFFFF);
			graphics.drawCircle (2 + n_max * 120 * Math.sin (a), 360 - n_max * 120 * Math.cos (a), 5);
			graphics.endFill ();
			// let's now find lines for this angle
			dfilter.shader.data.angle.value [0] = a;
			output2.applyFilter (output, output.rect, output2.rect.topLeft, dfilter);
			h = output2.histogram (r);
			h_max = copyToLinearArray (h, h_linear);
			// find local maxima (and draw them)
			lines.graphics.clear ();
			lines.graphics.lineStyle (2, 0xFF7F00);
			j = findLocalMaxima (h_linear, h_indices, kslider2.value);
			for (k = 0; k < j; k++) {
				i = h_indices [k];
				graphics.lineStyle (0, [65536, 256, 1][i >> 8] * (i % 256));
				graphics.moveTo (200 + i / 4, 470);
				graphics.lineTo (200 + i / 4, 470 - 100 * h_linear [i] / h_max);
				// implicit threshold
				if (h_linear [i] > 0.5 * h_max) {
					// draw lines: Ax + By + C = 0, y = - (Ax + C) / B (also scale up by 2)
					var A:Number = - Math.cos (+a);
					var B:Number = - Math.sin (+a);
					var C:Number = i - 384;
					lines.graphics.moveTo (0, -2 * C / B);
					lines.graphics.lineTo (2 * 160, -2 * (A * 160 + C) / B);
				}
			}
			info2.text = j + " local maxima (distance)";

			graphics.moveTo (200, 470);
			for (i = 0; i < 3; i++) {
				graphics.lineStyle (0, [0xFF0000, 0xFF00, 0xFF][i]);
				graphics.lineTo (200 + (768 / 12) * (i + 1), 470);
			}
		}
		public function copyToLinearArray (h_in:Vector.<Vector.<Number>>, h_out:Vector.<Number>):Number {
			var h_max:Number = 0;
			for (var i:int = 0; i < 256 * 3; i++) {
				if (i % 256 == 0) continue;
				var c:Number = h_in [i >> 8] [i % 256];
				if (c > h_max) h_max = c;
				h_out [i] = c;
			}
			for (i = 0; i < 3; i++) {
				h_out [256 * i] = 0.5 * (
					h_out [(256 * i - 1 + 768) % 768] +
					h_out [(256 * i + 1 + 768) % 768]
				);
			}
			return h_max;
		}
		public function findLocalMaxima (input:Vector.<Number>, output:Vector.<int>, K:int):int {
			var L:int = input.length, j:int = 0;
			var n:int = input.length / output.length;
			search: {
				for (var p:int = 0; p < output.length; p++) {
					for (var q:int = 0; q < n; q++) {
						var i:int = n * p + q;
						if (i < input.length) {
							var i_value:Number = input [i];
							var i_ismax:Boolean = true;
							for (var k:int = -K; k < K; k++) {
								if (k < 0) {
									if (input [(i + 768 + k) % 768] > i_value) {
										i_ismax = false; break;
									}
								} else if (k > 0) {
									if (input [(i + 768 + k) % 768] >= i_value) {
										i_ismax = false; break;
									}
								}
							}
							if (i_ismax) {
								// dijkstra would hate me :(
								output [j] = i; j++; if (j >= output.length) break search;
							}
						}
					}
				}
			}
			for (k = j; k < output.length; k++) {
				output [k] = -1;
			}
			return j;
		}
		public function onTSlider (e:Event):void {
			sfilter.shader.data.threshold.value [0] = HSlider (e.target).value;
		}
		public function onTSlider2 (e:Event):void {
			dfilter.shader.data.threshold.value [0] = HSlider (e.target).value;
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
			loader.contentLoaderInfo.addEventListener (Event.COMPLETE, onImageReady);
			loader.loadBytes (file.data);
		}
		public function onImageReady(e:Event):void {
			if (loader.content) {
				loader.contentLoaderInfo.removeEventListener (Event.COMPLETE, onImageReady);
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