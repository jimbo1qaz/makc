package {
	import alternativa.engine3d.controllers.CameraController;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Scene3D;
	import alternativa.engine3d.display.View;
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.types.Texture;
	import alternativa.utils.FPS;
	
	import flash.display.*; 
	import flash.events.*;
	import flash.net.*
	import flash.utils.*

	[SWF(backgroundColor="#000000", frameRate="100")]
	public class Main extends Sprite {

		private var scene:Scene3D;
		private var view:View;
		private var camera:Camera3D;
		private var wasd:CameraController;

		private var flag:MD2;

		public function Main() {
			addEventListener (Event.ADDED_TO_STAGE, onStage);
		}

		private function onStage (e:Event):void
		{
			removeEventListener (Event.ADDED_TO_STAGE, onStage);

			// load model
			var md2loader:URLLoader = new URLLoader ();
			md2loader.dataFormat = URLLoaderDataFormat.BINARY;
			md2loader.addEventListener (Event.COMPLETE, completeHandler);
			md2loader.load (new URLRequest ("telias.free.fr/flag.md2"));
		}

		private function completeHandler (event:Event):void
		{
			var loader:URLLoader = URLLoader(event.target);
			flag = new MD2("flag", loader.data);

			// load material
			var pngloader:Loader = new Loader ();
			pngloader.contentLoaderInfo.addEventListener (Event.INIT, initHandler);
			pngloader.load (new URLRequest ("telias.free.fr/flag.png"));
		}

		private function initHandler (event:Event):void
		{
			var info:LoaderInfo = LoaderInfo (event.target);
			flag.setMaterialToAllSurfaces (new TextureMaterial (new Texture (Bitmap (info.content).bitmapData)));

			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			// code below was mostly copied from alternativa3d GeometryTutorial:
			// http://docs.alternativaplatform.com/pages/viewpage.action?pageId=19398661

			scene = new Scene3D(); scene.root = new Object3D(); scene.root.addChild(flag);
			camera = new Camera3D(); camera.x = 150; camera.y = 150; camera.z = 150; scene.root.addChild(camera);
			view = new View(); addChild(view); view.camera = camera;

			wasd = new CameraController(stage); wasd.camera = camera; wasd.lookAt(flag.coords);
			wasd.setDefaultBindings(); wasd.controlsEnabled = true;
			
			FPS.init(stage);

			stage.addEventListener(Event.RESIZE, onResize);
			stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			onResize(null);
		}

		private function onResize(e:Event):void {
			view.width = stage.stageWidth;
			view.height = stage.stageHeight;
		}
		
		private function onEnterFrame(e:Event):void {
			// play MD2
			flag.frame += 0.3;
			// process user input and render
			wasd.processInput(); scene.calculate();
		}
	}
}