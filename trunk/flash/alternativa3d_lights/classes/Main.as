package {
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Mesh;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Scene3D;
	import alternativa.engine3d.display.View;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.engine3d.materials.TextureMaterialPrecision;
	import alternativa.engine3d.primitives.Box;
	import alternativa.engine3d.primitives.Cone;
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
		private var cone1:Cone, cone2:Cone;
		private var tex:LightTextureMaterial;
		private var lights:Array;
		private var materials:Array;

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

			tex = new LightTextureMaterial (new Texture (Bitmap (info.content).bitmapData));
			tex.precision = TextureMaterialPrecision.VERY_HIGH;

			materials = [tex, tex.clone (), tex.clone (), tex.clone (), tex.clone (), tex.clone ()];

			box = new Box (200, 200, 200);
			box.setMaterialToSurface (materials [0], "front");
			box.setMaterialToSurface (materials [1], "back");
			box.setMaterialToSurface (materials [2], "left");
			box.setMaterialToSurface (materials [3], "right");
			box.setMaterialToSurface (materials [4], "top");
			box.setMaterialToSurface (materials [5], "bottom");

			cone1 = new Cone (7, 5, 0, 1, 3);
			cone1.x = cone1.y = cone1.z = 150;
			cone1.cloneMaterialToAllSurfaces (new FillMaterial (0xFFFFFF));

			var light1:Light3D = new Light3D;
			light1.setDirection (cone1.coords, box.coords);

			cone2 = new Cone (7, 5, 0, 1, 3);
			cone2.x = cone1.y = 150; cone1.z = 0;
			cone2.cloneMaterialToAllSurfaces (new FillMaterial (0xFFFFFF));

			var light2:Light3D = new Light3D;
			light2.setDirection (cone2.coords, box.coords); light2.power = 0.5;

			lights = [light1, light2];

			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.quality = StageQuality.LOW;

			scene = new Scene3D(); scene.root = new Object3D();
			scene.root.addChild(box);
			scene.root.addChild(cone1);
			scene.root.addChild(cone2);
			camera = new Camera3D(); camera.z = 200; scene.root.addChild(camera);
			view = new View(); addChild(view); view.camera = camera;

			// let's do magic

			FPS.init(stage);

			stage.addEventListener(Event.RESIZE, onResize);
			stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			onResize(null);
		}

		private function onResize(e:Event):void {
			view.width = stage.stageWidth;
			view.height = stage.stageHeight;
		}

		private var t:Number = 0, lightPos:Point3D = new Point3D;
		private function onEnterFrame(e:Event):void {
			LightTextureMaterial.prepare ();

			// animate light [0];
			lightPos.x = camera.z * Math.sin (2 * t); lightPos.y = camera.z * Math.cos (2 * t); lightPos.z = lightPos.y;
			var coneCoords:Point3D = box.coords; coneCoords.subtract (lightPos); cone1.coords = coneCoords;

			Light3D (lights [0]).direction = lightPos;
			for each (var mat:LightTextureMaterial in materials) mat.lights = lights;

			// orbit and render
			camera.x = 2 * camera.z * Math.sin (t); camera.y = 2 * camera.z * Math.cos (t); lookAt (box.coords);
			scene.calculate();

			t += 1e-2; if (t > 2 * Math.PI) t -= 2 * Math.PI;
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