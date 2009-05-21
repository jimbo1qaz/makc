package {
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Mesh;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Scene3D;
	import alternativa.engine3d.core.Sprite3D;
	import alternativa.engine3d.display.View;
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.engine3d.materials.TextureMaterialPrecision;
	import alternativa.engine3d.primitives.Box;
	import alternativa.types.Point3D;
	import alternativa.types.Texture;
	import alternativa.utils.FPS;
	import alternativa.utils.MathUtils;
	
	import flash.display.*; 
	import flash.geom.*;
	import flash.events.*;
	import flash.net.*
	import flash.utils.*

	[SWF(backgroundColor="#000000", frameRate="100", width="300", height="300")]
	public class Main extends Sprite {

		private var scene:Scene3D;
		private var view:View;
		private var camera:Camera3D;
		private var box:Box;
		private var tex:TextureMaterial;

		public function Main() {
			addEventListener (Event.ADDED_TO_STAGE, onStage);
		}

		private function onStage (e:Event):void
		{
			removeEventListener (Event.ADDED_TO_STAGE, onStage);

			// load logo.jpg
			var loader:Loader = new Loader ();
			loader.contentLoaderInfo.addEventListener (Event.INIT, initHandler);
			loader.load (new URLRequest ("logo.jpg"));
		}

		private function initHandler (event:Event):void
		{
			var info:LoaderInfo = LoaderInfo (event.target);

			tex = new TextureMaterial (new Texture (Bitmap (info.content).bitmapData));
			tex.precision = TextureMaterialPrecision.VERY_HIGH;

			box = new Box (200, 200, 200);
			box.cloneMaterialToAllSurfaces (tex);

			// load logo.png
			var loader:Loader = new Loader ();
			loader.contentLoaderInfo.addEventListener (Event.INIT, initHandler2);
			loader.load (new URLRequest ("logo.png"));
		}

		private function initHandler2 (event:Event):void
		{
			var info:LoaderInfo = LoaderInfo (event.target);

			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.quality = StageQuality.HIGH;

			scene = new Scene3D(); scene.root = new Object3D(); scene.root.addChild(box);
			camera = new Camera3D(); camera.z = 200; scene.root.addChild(camera);
			view = new View(); addChild(view); view.camera = camera;

			var b:BitmapData = Bitmap (info.content).bitmapData;
			var m:Matrix = new Matrix (1, 0, 0, 1, -b.width/2, -b.height/2);

			for (var i:int = 0; i < 20; i++)
			{
				var r:Number = 200 + 100 * Math.random ();
				var a:Number = 2 * Math.PI * Math.random ();
				var h:Number = 100 - 200 * Math.random ();

				var s:Sprite = new Sprite;
				s.graphics.beginBitmapFill (b, m);
				s.graphics.drawRect (m.tx, m.ty, b.width, b.height);
				s.graphics.endFill ();

				// magic happens here :)
				var sprite:Sprite3D = new Sprite3D;
				sprite.material = new DisplayObjectMaterial (s);

				sprite.x = r * Math.sin (a); sprite.y = r * Math.cos (a); sprite.z = h;
				scene.root.addChild (sprite);
			}

			FPS.init(stage);

			stage.addEventListener(Event.RESIZE, onResize);
			stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			onResize(null);
		}

		private function onResize(e:Event):void {
			view.width = stage.stageWidth;
			view.height = stage.stageHeight;
		}

		private var t:Number = 0;
		private function onEnterFrame(e:Event):void {
			// orbit and render
			camera.x = 2 * camera.z * Math.sin (t); camera.y = 2 * camera.z * Math.cos (t); lookAt (box.coords);
			scene.calculate(); t += 1e-2; if (t > 2 * Math.PI) t -= 2 * Math.PI;
		}

		private function lookAt(pt:Point3D):void {
			var dx:Number = pt.x - camera.x;
			var dy:Number = pt.y - camera.y;
			var dz:Number = pt.z - camera.z;
			camera.rotationZ = -Math.atan2(dx, dy);
			camera.rotationX = Math.atan2(dz, Math.sqrt(dx * dx + dy * dy)) - MathUtils.DEG90;
		}

	}
}