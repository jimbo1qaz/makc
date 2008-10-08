package 
{
	import flash.display.Sprite;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.geom.Point;

	import sandy.core.*;
	import sandy.core.data.*;
	import sandy.core.scenegraph.*;
	import sandy.materials.*;
	import sandy.materials.attributes.*;
	import sandy.extrusion.*;
	import sandy.extrusion.data.*;
	
	[SWF(backgroundColor="#7F7F7F", frameRate="30", width="300", height="300")]
	public class LatheExample extends Sprite
	{
		private var scene:Scene3D;
		private var ext1:Extrusion, ext2:Extrusion;

		public function LatheExample():void
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;

			// minimal sandy setup
			scene = new Scene3D ("scene", this, new Camera3D (300, 300), new Group("root"));

			// profiles
			var p1:Polygon2D = new Polygon2D ([
				new Point (35, 2), new Point (65, 2), new Point (65, -18), new Point (35, -18)
			]);

			var p2:Polygon2D = new Polygon2D ([
				new Point (8, -43), new Point (8, 27), new Point (43, 27), new Point (43, 8), new Point (27, 8), new Point (27, -25), new Point (42, -25), new Point (42, -43)
			]);

			// curves
			var lathe1:Lathe = new Lathe (new Vector, new Vector (1, 1, 1), new Vector (1, 0, 0), -1);
			var lathe2:Lathe = new Lathe (new Vector, new Vector (1, 1, 1), new Vector (1, 0, 0), 0, 5);

			// extrusions
			ext1 = new Extrusion ("ext0", p1, lathe1.toSections ());
			ext1.useSingleContainer = false; scene.root.addChild (ext1);

			ext2 = new Extrusion ("ext1", p2, lathe2.toSections ());
			ext2.useSingleContainer = false; scene.root.addChild (ext2);

			// add some materials
			ext1.appearance = new Appearance (new ColorMaterial (0x7F0000, 1,
				new MaterialAttributes (new LightAttributes(false, 0.6), new GouraudAttributes(false, 0.6))));
			ext1.appearance.frontMaterial.lightingEnable = true;

			ext2.appearance = new Appearance (new ColorMaterial (0x7F00, 1,
				new MaterialAttributes (new LightAttributes(false, 0.6), new GouraudAttributes(false, 0.6))));
			ext2.appearance.frontMaterial.lightingEnable = true;

			// show it
			addEventListener ("enterFrame", render);
		}

		private function render (e:*):void {
			ext1.rotateY+=3; ext2.rotateY+=3; scene.render ();
		}
	}
}