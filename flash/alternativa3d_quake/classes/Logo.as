package {
	import flash.display.*; 
	import flash.events.*;

	public class Logo extends Sprite {

		/**
		 * In order to compile with CS3, comment next two lines.
		 */
		[Embed(source="../quake.png")]
		private var QuakePng:Class;

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

			logo = new QuakePng; addChild (logo);
			stage.addEventListener(Event.RESIZE, onResize); onResize(null);
		}

		/**
		 * Centers the logo.
		 */
		private function onResize(e:Event):void {
			logo.x = (stage.stageWidth - logo.width) / 2;
			logo.y = (stage.stageHeight - logo.height) / 2;
		}

		private var logo:Bitmap;
	}
}