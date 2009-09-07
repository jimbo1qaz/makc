package  {
	import alternativa.engine3d.controllers.WalkController;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Scene3D;
	import alternativa.engine3d.display.View;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.engine3d.primitives.Box;
	import alternativa.engine3d.primitives.Plane;
	import alternativa.types.Point3D;
	import alternativa.types.Texture;
	import alternativa.utils.FPS;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	
	/**
	* Dynamic BSP performance test.
	* @author makc
	*/
	public class Test extends View {
		private var scene:Scene3D;
		private var controller:WalkController;

		private var cubesA:Object3D;
		private var cubesB:Object3D;

		public function Test () {
			super (new Camera3D, 800, 600); FPS.init (this);
			stage.scaleMode = StageScaleMode.NO_SCALE; stage.quality = StageQuality.LOW;

			scene = new Scene3D; scene.root = new Object3D; scene.root.addChild (camera);

			scene.splitAnalysis = false; // unreal otherwise

			controller = new WalkController (stage, camera);
			controller.setDefaultBindings (); controller.speed = 300;
			controller.coords = new Point3D (0, 0, 5000);
			controller.lookAt (scene.root.coords);

			var i:int, j:int, box:Box;
			var bd:BitmapData = new BitmapData (32, 32); bd.noise (123, 123);
			var material:TextureMaterial = new TextureMaterial (new Texture (bd), 1, true, false, BlendMode.NORMAL, 0);

			// two planes
			var planeA:Plane = new Plane (6000, 6000); scene.root.addChild (planeA); planeA.rotationX = Math.PI * 0.5;
			planeA.cloneMaterialToAllSurfaces (new FillMaterial (0xFF00, 0.3, BlendMode.NORMAL, 0));

			var planeB:Plane = new Plane (6000, 6000); scene.root.addChild (planeB); planeB.rotationY = Math.PI * 0.5;
			planeB.cloneMaterialToAllSurfaces (new FillMaterial (0x00FF, 0.3, BlendMode.NORMAL, 0));

			// wall of cubes A
			cubesA = new Object3D; cubesA.mobility = 2; scene.root.addChild (cubesA);
			for (i = 0; i < 36; i++) {
				for (j = 0; j < 4; j++) {
					box = new Box; box.cloneMaterialToAllSurfaces (material);
					box.x = 1000 * Math.sin (i * 10 * Math.PI / 180);
					box.y = 1000 * Math.cos (i * 10 * Math.PI / 180);
					box.z = 600 * j;
					cubesA.addChild (box);
				}
			}

			// wall of cubes B
			cubesB = new Object3D; cubesB.mobility = 4; scene.root.addChild (cubesB);
			for (i = 0; i < 36; i++) {
				for (j = 0; j < 4; j++) {
					box = new Box; box.cloneMaterialToAllSurfaces (material);
					box.x = 1000 * Math.sin (i * 10 * Math.PI / 180);
					box.y = 1000 * Math.cos (i * 10 * Math.PI / 180);
					box.z = 600 * (j + 0.5);
					cubesB.addChild (box);
				}
			}

			addEventListener (Event.ENTER_FRAME, loop);
		}

		private function loop (e:Event):void {
			cubesA.rotationZ += 0.01;
			cubesB.rotationZ -= 0.01;

			controller.processInput ();
			scene.calculate ();
		}
	}
	
}