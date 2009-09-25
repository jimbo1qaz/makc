package {
	import dsp.*;
	import flash.display.*;
	import flash.events.*;
	import flash.media.*;
	import flash.net.*;
	import flash.text.*;
	import flash.utils.*;

	public class FFTTest extends Sprite {

		private var info:TextField;
		private var sound:Sound;
		private var channel:SoundChannel;
		private var bytes:ByteArray;
		private var samples:Array;
		private var fft:FastFourierTransform;

		public function FFTTest () {
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
			sound.load (new URLRequest ("test.mp3"));
			channel = sound.play (0, int.MAX_VALUE);
		}

		private function progressHandler(event:ProgressEvent):void {
			// worry not, my user, we'll be there soon...
			info.text = "Тримайся, друже, ще " + (event.bytesTotal - event.bytesLoaded) + " байтів...";
		}

		private function completeHandler (event:Event):void {
			// now that we have something to work with...
			info.text = "Малюємо частоти від 0 до 5КГц.\n" +
				"Тестовий файл: 2с білого шуму, 2с 500 Гц, 2с 1.5КГц, 2с 4КГц.";

			bytes = new ByteArray; samples = new Array; fft = new FastFourierTransform;
			addEventListener (Event.ENTER_FRAME, enterFrameHandler);
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
			// fft.magnitudes contain full spectrum, we want 1st 5KHz
			var limKHz:Number = 5000;
			var i:int, n:int = fft.magnitudes.length * limKHz / (44100 / 2), w:int = 800 / n;
			// draw spectrum
			graphics.clear ();
			graphics.lineStyle ();
			graphics.beginFill (0);
			for (i = 0; i < n; i++) {
				graphics.drawRect (w*i, 50, w, 400 * fft.magnitudes [i]);
			}
			graphics.endFill ();
			// draw 1KHz ticks
			var ticksWidth:Number = 1000;
			graphics.lineStyle (0);
			for (i = 0; i < limKHz / ticksWidth + 1; i++) {
				graphics.moveTo (w * (ticksWidth / limKHz * n * i), 50);
				graphics.lineTo (w * (ticksWidth / limKHz * n * i), 45);
			}
			
		}
	}
}
