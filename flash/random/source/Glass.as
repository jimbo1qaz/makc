package {
	import dsp.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.media.*;
	import flash.net.*;
	import flash.text.*;
	import flash.utils.*;

	public class Glass extends Sprite {

		private var info:TextField;
		private var sound:Sound;
		private var channel:SoundChannel;
		private var bytes:ByteArray;
		private var samples:Array;
		private var fft:FastFourierTransform;

		public function Glass () {
			//stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;

			// add info text field
			info = new TextField;
			info.autoSize = TextFieldAutoSize.LEFT;
			addChild (info);

			// load test.mp3
			sound = new Sound;
			sound.addEventListener (ProgressEvent.PROGRESS, progressHandler);
			sound.addEventListener (Event.COMPLETE, completeHandler);
			sound.load (new URLRequest ("test.mp3"));
			channel = sound.play (0, int.MAX_VALUE);
		}

		private function progressHandler(event:ProgressEvent):void {
			// worry not, my user, we'll be there soon...
			info.text = "Тримайся, друже, ще " + (event.bytesTotal - event.bytesLoaded) + " байтів...";
		}

		private function completeHandler (event:Event):void {
			// now that we have something to work with...
			info.text = "Ґрай, гармонь!";

			bytes = new ByteArray; samples = new Array; fft = new FastFourierTransform;
			addEventListener (Event.ENTER_FRAME, enterFrameHandler);

			// glasses
			glassBMs = [];
			[Embed(source = '../assets/images/glass0.jpg')]var G0:Class; glassBMs.push (getTweakedBitmapData ((new G0).bitmapData));
			[Embed(source = '../assets/images/glass1.jpg')]var G1:Class; glassBMs.push (getTweakedBitmapData ((new G1).bitmapData));
			[Embed(source = '../assets/images/glass2.jpg')]var G2:Class; glassBMs.push (getTweakedBitmapData ((new G2).bitmapData));
			[Embed(source = '../assets/images/glass3.jpg')]var G3:Class; glassBMs.push (getTweakedBitmapData ((new G3).bitmapData));
			[Embed(source = '../assets/images/glass4.jpg')]var G4:Class; glassBMs.push (getTweakedBitmapData ((new G4).bitmapData));
			[Embed(source = '../assets/images/glass5.jpg')]var G5:Class; glassBMs.push (getTweakedBitmapData ((new G5).bitmapData));
			[Embed(source = '../assets/images/glass6.jpg')]var G6:Class; glassBMs.push (getTweakedBitmapData ((new G6).bitmapData));

			glassYs = [129, 117, 93, 75, 59, 41, 27];

			glasses = new Sprite;
			for (var b:int = 0; b < N; b++ ) {
				var sh:Shape = new Shape; glasses.addChild (sh);
				if (b > 0) sh.x = (glassBMs [0].width - 22) * b;
			}

			glassesComposite = new BitmapData (glassBMs [0].width + (glassBMs [0].width - 22) * (N - 1), glassBMs [0].height + 50, true, 0xFFFFFF);
			graphics.lineStyle (); graphics.beginBitmapFill (glassesComposite); graphics.drawRect (0, 0, glassesComposite.width, glassesComposite.height);
		}

		private var N:int = 5, glasses:Sprite, glassesComposite:BitmapData;

		private function getTweakedBitmapData (input:BitmapData):BitmapData {
			[Embed(source = '../assets/images/glassMask.gif')]var GMask:Class; var mask:BitmapData = (new GMask).bitmapData;

			var tmp:BitmapData = new BitmapData (input.width, input.height, true, 0xFFFFFFFF); tmp.draw (input);
			tmp.copyChannel (mask, mask.rect, mask.rect.topLeft, 1, 8);

			return tmp;
		}

		private var glassBMs:Array, glassYs:Array;
		private function getGlassIndex (value:Number):int {
			// map 0..0.4 to glassYs
			var gy:Number = glassYs [0] + (glassYs [glassYs.length - 1] - glassYs [0]) * (value / 0.4);
			// find best match
			var i:int, j:int = -1, d:Number = 1e6;
			for (i = 0; i < glassYs.length; i++) {
				var di:Number = Math.abs (glassYs [i] - gy);
				if (di < d) {
					d = di; j = i;
				}
			}
			return j;
		}

		private function enterFrameHandler (event:Event):void {
			// get bytes of 1024 samples
			bytes.position = 0;
			sound.extract (bytes, 1024, channel.position * 44.1);

			// get samples of left channel
			bytes.position = 0;
			while (bytes.bytesAvailable > 0) {
				samples [int (bytes.position / 8)] = bytes.readFloat (); bytes.readFloat ();
			}

			// analyze samples
			fft.analyze (samples);

			// fft.magnitudes contain full spectrum, we want 1st KHz
			var limitHz:Number = 1000;
			var i:int, n:int = fft.magnitudes.length * limitHz / (44100 / 2);

			// sum up 200Hz bands
			var bands:Array = [];
			for (i = 0; i < n; i++) {
				var j:int = i / (n / N);
				if (j > bands.length - 1)
					bands [j] = fft.magnitudes [i];
				else
					bands [j] += fft.magnitudes [i];
			}

			// draw spectrum
			for (i = 0; i < bands.length; i++) {
				var sh:Shape = glasses.getChildAt (i) as Shape;
				sh.graphics.clear ();
				sh.graphics.lineStyle ();
				var bd:BitmapData = glassBMs [getGlassIndex (bands [i])];
				sh.graphics.beginBitmapFill (bd);
				sh.graphics.drawRect (0, 0, bd.width, bd.height);
				sh.graphics.endFill ();
			}

			//
			glassesComposite.fillRect (glassesComposite.rect, 0xFFFFFF);
			glassesComposite.draw (glasses, new Matrix (1, 0, 0, 1, 0, 25));
			for (i = 1; i < 25; i++) {
				glassesComposite.draw (glasses, new Matrix (1, 0, 0, 1, 0, 25 - i), new ColorTransform (1, 1, 1, 1 - i / 24.0),
					"normal", new Rectangle (0, 25 - i, glassesComposite.width, 1));
				glassesComposite.draw (glasses, new Matrix (1, 0, 0, 1, 0, 25 + i), new ColorTransform (1, 1, 1, 1 - i / 24.0),
					"normal", new Rectangle (0, 25 + glassBMs [0].height + i - 2, glassesComposite.width, 1));
			}
		}
	}
}
