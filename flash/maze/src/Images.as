package {
	import flash.display.*
	import flash.events.*
	import flash.net.*

	/**
	* Images object loads images and generates READY event.
	*/
	public class Images extends EventDispatcher {
		public static var READY:String = "ready";

		public var Maze:BitmapData, Wall:BitmapData, Floor:BitmapData;

		public function Images () {
			var mazeLoader:Loader = new Loader ();
			mazeLoader.load (new URLRequest ("maze.gif"));
			mazeLoader.contentLoaderInfo.addEventListener (Event.COMPLETE, gotMaze);

			var wallLoader:Loader = new Loader ();
			wallLoader.load (new URLRequest ("wall.jpg"));
			wallLoader.contentLoaderInfo.addEventListener (Event.COMPLETE, gotWall);

			var floorLoader:Loader = new Loader ();
			floorLoader.load (new URLRequest ("floor.jpg"));
			floorLoader.contentLoaderInfo.addEventListener (Event.COMPLETE, gotFloor);
		}

		private var _loaded:int = 0;
		private function gotImage () {
			_loaded++; if (_loaded == 3) {
				dispatchEvent (new Event (READY));
			}
		}

		private function gotMaze (e:Event):void {
			Maze = Bitmap (e.target.content).bitmapData; gotImage ();
		}

		private function gotWall (e:Event):void {
			Wall = Bitmap (e.target.content).bitmapData; gotImage ();
		}

		private function gotFloor (e:Event):void {
			Floor = Bitmap (e.target.content).bitmapData; gotImage ();
		}
	}
}