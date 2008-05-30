package {
	import flash.display.*
	import flash.events.*

	/**
	* A document class.
	*/
	public class Maze extends Sprite {
		public function Maze () {
			addEventListener (Event.ADDED_TO_STAGE, onStage);
		}

		private var images:Images;
		private function onStage (e:Event):void {
			removeEventListener (Event.ADDED_TO_STAGE, onStage);
			images = new Images; images.addEventListener (Images.READY, onImagesReady);
		}
		private function onImagesReady (e:Event):void {
			images.removeEventListener (Images.READY, onImagesReady);
			// init
			trace ("hello");
		}
	}
}