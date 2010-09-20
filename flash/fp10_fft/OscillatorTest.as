package {
	import dsp.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.media.*;
	import flash.net.*;
	import flash.text.*;
	import flash.utils.*;

	public class OscillatorTest extends Sprite {

		private var info:TextField;
		private var sound:Sound;
		private var soundOutput:Sound;
		private var channel:SoundChannel;
		private var oscillators:Array;

		public function OscillatorTest () {
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;

			// add info text field
			info = new TextField;
			info.autoSize = TextFieldAutoSize.LEFT;
			addChild (info);

			var loader:ClientMP3Loader = new ClientMP3Loader;
			loader.addEventListener (Event.CANCEL, cancelHandler);
			loader.addEventListener (Event.COMPLETE, completeHandler);
			loader.load ();
		}

		private function cancelHandler(event:Event):void {
			// load test.mp3
			sound = new Sound;
			sound.addEventListener (ProgressEvent.PROGRESS, progressHandler);
			sound.addEventListener (Event.COMPLETE, completeHandler);
			sound.load (new URLRequest ("test_beat.mp3"));
		}

		private function progressHandler(event:ProgressEvent):void {
			// worry not, my user, we'll be there soon...
			info.text = "Тримайся, друже, ще " + (event.bytesTotal - event.bytesLoaded) + " байтів...";
		}

		private function completeHandler (event:Event):void {
			if (event.target as ClientMP3Loader) {
				sound = ClientMP3Loader (event.target).sound;
			}

			// now that we have something to work with...
			info.text = "Малюємо осцилятори, 1...9Гц, перший стовбчик - вхід осциляторів;\n";

			oscillators = [];
			// 1 to 9 Hz, 10 Hz is too close to Nyquist limit, 0.5 * (44100 / 2048) = 10.77 Hz
			for (var w:int = 1; w <= 9; w++) {
				var c:Number = Oscillator.CalculateDamping (w, 0.1);
				var osc:Oscillator = new Oscillator (w, c, 2048 / 44100);
				oscillators.push (osc);
				info.appendText ("\nOcsillator w0 = " + w + " Hz, c = " + c.toFixed (5) + ", expected resonance at " + osc.resonanceFrequency.toFixed (5) + " Hz");
			}

			// start playing
			soundOutput = new Sound;
			soundOutput.addEventListener (SampleDataEvent.SAMPLE_DATA, supplyData);
			soundOutput.play ();

			addEventListener (Event.ENTER_FRAME, enterFrameHandler);
		}

		private var lastv:Number = 0, feed:Number = 0, maxv:Number = 50;
		private function supplyData (e:SampleDataEvent):void {
			// loop from sound data
			var n:int = sound.extract (e.data, 2048, e.position % (sound.length * 44.1));
			if (n < 2048) sound.extract (e.data, 2048 - n, 0);

			// the above writes 2048 * 2 (left, right) * 4 (4 bytes per float) bytes = 16384
			// we go back 16384 bytes and calculate sound energy
			e.data.position -= 16384;
			var e1:Number = 0, e2:Number = 0;
			var last1:Number = e.data.readFloat (), last2:Number = e.data.readFloat ();
			for (var k:int = 0; k < 2048 - 1; k++) {
				var v1:Number = e.data.readFloat (), v2:Number = e.data.readFloat ();
				e1 += v1 * v1 + (v1 - last1) * (v1 - last1); last1 = v1;
				e2 += v2 * v2 + (v2 - last2) * (v2 - last2); last2 = v2;
			}

			// get new peak
			var v:Number = Math.sqrt (e1 + e2) / maxv; feed = v -/*mouseX / stage.stageWidth */ lastv; lastv = v;
			maxv *= 0.99; maxv += 0.01 * v; if (maxv < 15 /* fail-safety hack */) maxv = 15;

			// update oscillators
			for (var i:int = 0; i < oscillators.length; i++)
				Oscillator (oscillators [i]).update (feed);
		} 

		private function enterFrameHandler (event:Event):void {
			var i:int, n:int = oscillators.length, w:int = 15;

			var max_blue:Number = 0, max_green:Number = 0;

			// draw oscillators and signal
			graphics.clear ();
			graphics.lineStyle (0, 255 * 256);
			for (i = -1; i < n; i++) {
				var p:Number = (i < 0) ? feed : Oscillator (oscillators [i]).x;
				graphics.drawRect ((w + 2) * (i+1), 250 + ((p > 0) ? 0 : 100 * p), w + 2, 100 * Math.abs (p));
				if (i >= 0) {
					if (Oscillator (oscillators [i]).energy > max_blue) {
						max_blue = Oscillator (oscillators [i]).energy;
						max_green = Oscillator (oscillators [i]).x;
					}
				}
			}
			graphics.lineStyle ();
			graphics.beginFill (255, 0.5);
			for (i = 0; i < n; i++)
				graphics.drawRect ((w + 2) * (i+1) + 1, 250, w, 100 * Oscillator (oscillators [i]).energy);
			graphics.endFill ();
			graphics.beginFill (255 * 65536, 0.5);
			graphics.drawRect (1, 250, w, 100 * lastv);

			// viz app test
			graphics.lineStyle ();
			graphics.beginFill (255 * 257);
			graphics.drawCircle (400, 300, 10);
			graphics.drawCircle (400 + Math.min (100, Math.max (-100, 50 * max_green)), 300, 20);
		}
	}
}