package {
	import flash.display.*; 
	import flash.events.*;

	public class Logo extends Sprite {

		/**
		 * In order to compile with CS3, comment next two lines.
		 */
		[Embed(source="../quake.png")]
		private var LogoPng:Class;

		/**
		 * Constructor.
		 */
		public function Logo() {
			addEventListener (Event.ADDED_TO_STAGE, onStage);
		}

		/**
		 * Fired when stage reference is accessible.
		 */
		private function onStage (event:Event):void {
			removeEventListener (Event.ADDED_TO_STAGE, onStage);

			logoPng = new LogoPng; addChild (logoPng);
			stage.addEventListener(Event.RESIZE, onResize); onResize(null);
		}

		/**
		 * Centers the logo.
		 */
		private function onResize(e:Event):void {
			logoPng.x = (stage.stageWidth - logoPng.width) / 2;
			logoPng.y = (stage.stageHeight - logoPng.height) / 2;
		}

		private var logoPng:Bitmap;
	}
}