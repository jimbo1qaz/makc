package 
{
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import sandy.core.data.Plane;
	import sandy.core.data.Polygon;
	import sandy.core.Scene3D;
	import sandy.core.scenegraph.Camera3D;
	import sandy.core.scenegraph.Group;
	import sandy.materials.Appearance;
	import sandy.materials.BitmapMaterial;
	import sandy.primitive.Plane3D;
	import sandy.view.Frustum;
	
	public class Main extends Sprite
	{
		[Embed (source = "water.jpg")]
		private var WaterTexture:Class;

		private var screen:Sprite;
		private var island:Island;
		private var plane:Plane3D;
		private var scene:Scene3D;
		public function Main():void {
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			screen = new Sprite; addChild (screen);

			island = new Island;
			island.enableClipping = true;

			plane = new Plane3D ("water", 800, 800, 1, 1, Plane3D.ZX_ALIGNED);
			var waterMat:BitmapMaterial = new BitmapMaterial (Bitmap (new WaterTexture).bitmapData, null, 50);
			waterMat.smooth = true; plane.appearance = new Appearance (waterMat);
			plane.enableForcedDepth = true; plane.forcedDepth = 1e4;
			plane.enableClipping = false;

			scene = new Scene3D ("scene", screen, new Camera3D, new Group ("root"));
			scene.root.addChild (island); scene.root.addChild (plane);
			addEventListener (Event.ENTER_FRAME, render);
		}

		private var a:Number = 0;
		private var d:Number = 350;
		private function render (e:Event):void {
			screen.x = 0.5 * (stage.stageWidth - scene.camera.viewport.width);
			screen.y = 0.5 * (stage.stageHeight - scene.camera.viewport.height);

			d = (scene.camera.y - 255 * (0.95 - 0.85 * stage.mouseY / stage.stageHeight));
			var p:Plane = scene.camera.frustrum.aPlanes [Frustum.BOTTOM];
			p.a = scene.camera.invModelMatrix.n12;
			p.b = scene.camera.invModelMatrix.n22;
			p.c = scene.camera.invModelMatrix.n32;
			p.d = d; plane.y = scene.camera.y - d;

			scene.render ();

			a *= 0.8; a += 0.2 * 2 * Math.PI * stage.mouseX / stage.stageWidth;
			scene.camera.x = 600 * Math.sin (a);
			scene.camera.z = 600 * Math.cos (a);
			scene.camera.y = 600 * (1 + Math.sin (a / 2));
			scene.camera.lookAt (0, 100, 0);
		}
	}
}