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
		private var channel:SoundChannel;
		private var oscillators:Array;

		public function OscillatorTest () {
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;

			// add info text field
			info = new TextField;
			info.autoSize = TextFieldAutoSize.LEFT;
			addChild (info);

			// load test.mp3
			sound = new Sound;
			sound.addEventListener (ProgressEvent.PROGRESS, progressHandler);
			sound.addEventListener (Event.COMPLETE, completeHandler);
			sound.load (new URLRequest ("test_beat.mp3"));
			channel = sound.play (0, int.MAX_VALUE);
		}

		private function progressHandler(event:ProgressEvent):void {
			// worry not, my user, we'll be there soon...
			info.text = "Тримайся, друже, ще " + (event.bytesTotal - event.bytesLoaded) + " байтів...";
		}

		private function completeHandler (event:Event):void {
			// now that we have something to work with...
			info.text = "Малюємо осцилятори, 1...9Гц, перший стовбчик - вхід осциляторів;\n"
				+"Миша зліва подає в осцилятори вихідний сигнал, миша зправа - похідну.";

			oscillators = [];
			// 1 to 9 Hz, 10 Hz is too close to Nyquist limit, 0.5 * (44100 / 2048) = 10.77 Hz
			for (var w:int = 1; w <= 9; w++)
				oscillators.push (new Oscillator (w, Oscillator.CalculateDamping (w, 0.1), 2048 / 44100));
			setInterval (updateOscillators, 2048 * 1000 / 44100);

			addEventListener (Event.ENTER_FRAME, enterFrameHandler);
		}

		private var lastv:Number = 0, feed:Number = 0;
		private function updateOscillators ():void {
			// get new peak
			var v:Number = Math.max (channel.leftPeak, channel.rightPeak); feed = v -mouseX / stage.stageWidth * lastv; lastv = v;

			// update oscillators
			for (var i:int = 0; i < oscillators.length; i++)
				Oscillator (oscillators [i]).update (feed);
		}

		private function enterFrameHandler (event:Event):void {
			var i:int, n:int = oscillators.length, w:int = 15;

			// draw oscillators and signal
			graphics.clear ();
			graphics.lineStyle (0, 255 * 256);
			for (i = -1; i < n; i++) {
				var p:Number = (i < 0) ? feed : Oscillator (oscillators [i]).x;
				graphics.drawRect ((w + 2) * (i+1), 150 + ((p > 0) ? 0 : 100 * p), w + 2, 100 * Math.abs (p));
			}
			graphics.lineStyle ();
			graphics.beginFill (255, 0.5);
			for (i = 0; i < n; i++)
				graphics.drawRect ((w + 2) * (i+1) + 1, 150, w, 100 * Oscillator (oscillators [i]).energy);
			graphics.endFill ();
			graphics.beginFill (255 * 65536, 0.5);
			graphics.drawRect (1, 150, w, 100 * lastv);
		}
	}
}
