package  
{
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import sandy.core.Scene3D;
	import sandy.core.scenegraph.*;
	import sandy.materials.Appearance;
	import sandy.materials.BitmapMaterial;
	import sandy.materials.BitmapMaterialFP10;
	import sandy.primitive.*;
	
	/**
	* Test player 10 material.
	* @author makc
	*/
	[SWF(backgroundColor="#FFFFFF", frameRate="30", width="800", height="600")]
	public class Test extends Sprite
	{
		[Embed(source='chess.gif')]
		private var Texture:Class;

		private var scene:Scene3D;

		public function Test () 
		{
			// create old and new materials
			var matOld:BitmapMaterial = new BitmapMaterial (Bitmap (new Texture).bitmapData, null, 1);
			var matNew:BitmapMaterialFP10 = new BitmapMaterialFP10 (Bitmap (new Texture).bitmapData);

			// usual sandy stuff from here
			scene = new Scene3D ("scene", this, new Camera3D (800, 600), new Group ("root"));

			var p_Old:Plane3D = new Plane3D; p_Old.appearance = new Appearance (matOld);
			p_Old.x = -70; p_Old.rotateY = +40; scene.root.addChild (p_Old);

			var p_New:Plane3D = new Plane3D; p_New.appearance = new Appearance (matNew);
			p_New.x = +70; p_New.rotateY = -40; scene.root.addChild (p_New);

			// test it
			addEventListener (Event.ENTER_FRAME, run);
		}

		private function run (e:Event):void
		{
			scene.camera.x = 200 * (2 * mouseX / stage.stageWidth - 1);
			scene.camera.y = 200 * (2 * mouseY / stage.stageHeight - 1);
			scene.camera.z = -200; scene.camera.lookAt (0, 0, 0);
			scene.render();
		}
		
	}
	
}