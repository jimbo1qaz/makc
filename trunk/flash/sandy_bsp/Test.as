package  {
	import flash.display.Sprite;
	import flash.events.*;
	import sandy.core.*;
	import sandy.core.scenegraph.*;
	import sandy.materials.*;
	import sandy.materials.attributes.*;

	/**
	 * BSP sorting + cutting polygons with frustum test.
	 * @author makc
	 */
	[SWF (width="800", height="600", frameRate="60")]
	public class Test extends Sprite {
		private var scene:Scene3D;
		private var thingy1:Shape3D;
		private var thingy2:Shape3D;
		private var appearance:Appearance;
		private var scale:Number = 2;

		public function Test () {
			scene = new Scene3D ("scene", this, new Camera3D (800, 600, 45, 0), new Group ("root"));
			scene.camera.z = -5 * scale;

			appearance = new Appearance (new ColorMaterial (0x7F007F, 1, new MaterialAttributes (new LineAttributes (0, 0))));

			thingy1 = new Crystal; thingy1.appearance = appearance;
			scene.root.addChild (thingy1);

			thingy2 = new BSPShapeHack (/* some damage is done to passed instance */ thingy1.clone ());
			scene.root.addChild (thingy2);

			addEventListener (Event.ENTER_FRAME, loop);
		}

		private function loop (e:Event):void {
			thingy1.resetCoords (); thingy1.x = -scale; thingy1.pan = mouseX; thingy1.rotateX = mouseY;
			thingy2.resetCoords (); thingy2.x = +scale; thingy2.pan = mouseX; thingy2.rotateX = mouseY;

			scene.render ();
		}
	}
}