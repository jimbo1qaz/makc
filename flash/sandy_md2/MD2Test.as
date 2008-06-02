package {
	import flash.display.*; 
	import flash.events.*;
	import flash.net.*
	import flash.utils.*
	import sandy.core.Scene3D;
	import sandy.core.data.*;
	import sandy.core.scenegraph.*;
	import sandy.materials.*;
	import sandy.materials.attributes.*;
	import sandy.primitive.*;

	public class MD2Test extends Sprite {
		private var scene:Scene3D;
		private var imp:MD2;

		public function MD2Test() { 
			scene = new Scene3D( "scene", this, new Camera3D( 300, 300 ), new Group() );
			addEventListener( Event.ENTER_FRAME, enterFrameHandler );

			var md2loader:URLLoader = new URLLoader ();
			md2loader.dataFormat = URLLoaderDataFormat.BINARY;
			md2loader.addEventListener (Event.COMPLETE, completeHandler);
			md2loader.load (new URLRequest ("jdoom/imp.md2"));
		}

		private function completeHandler(event:Event):void {
			var loader:URLLoader = URLLoader(event.target);

			// make imp
			imp = new MD2 ( "imp", loader.data );
			scene.root.addChild( imp );

			// load material
			var gifloader:Loader = new Loader ();
			gifloader.contentLoaderInfo.addEventListener (Event.INIT, initHandler);
			gifloader.load (new URLRequest ("jdoom/imp.gif"));
		}
 
		private function initHandler(event:Event):void {
			var info:LoaderInfo = LoaderInfo(event.target);
			imp.appearance = new Appearance (new BitmapMaterial (Bitmap (info.content).bitmapData));
		}

		private function enterFrameHandler( event : Event ) : void {
			if (imp != null) {
				imp.rotateY += 1; imp.frame += 0.1;
			}
			scene.render();
		}
	}
}