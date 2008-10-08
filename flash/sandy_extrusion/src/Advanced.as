package 
{
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.display.StageAlign;
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
	
	[SWF(backgroundColor="#FFFFFF", frameRate="1", width="935", height="600")]
	public class Advanced extends Sprite
	{
		private var scene:Scene3D;
		private var ext:Extrusion;

		[Embed(source="Jack_Sparrow.jpg")]
		private var Jack:Class;

		[Embed(source="Tentacle.jpg")]
		private var Tentacle:Class;

		public function Advanced():void
		{
			stage.scaleMode = StageScaleMode.SHOW_ALL;
			stage.align = StageAlign.BOTTOM_RIGHT;

			var jack:Bitmap = new Jack; jack.y = 300; addChild (jack);
			var sandy:Sprite = new Sprite; addChild (sandy);

			// minimal sandy setup
			scene = new Scene3D ("scene", sandy, new Camera3D (400, 300), new Group("root"));

			// tentacle profile
			var profile:Polygon2D = new Polygon2D ([
				new Point (-3, 25), new Point (-34, -1), new Point (-2, -26), new Point (20, -13), new Point (20, 14)
			]);

			// create tentacle
			var tentacle:Curve3D = new Curve3D;
			for (var i:int = 0; i < 21; i++) {
				// add path point (arbitrary formula here)
				tentacle.v.push (new Vector (i * i - 100 - 100 * Math.sin ((i - 5) * 0.2), 100 - i * i, 20 * i));
				// specify tangent vector at that point (for best results, we derive this from path equation here)
				var t:Vector = new Vector (2 * i - 100 * 0.2 * Math.cos ((i - 5) * 0.2), -2 * i, 20); t.normalize ();
				tentacle.t.push (t);
				// specify normal vector at that point (as you see, it does not have to be accurate :)
				var n:Vector = new Vector (0.707, 0.707, 0); n.crossWith (t);
				tentacle.n.push (n);
				// specify profile scale at that point (arbitrary formula, again)
				tentacle.s.push (0.1 * i);
			}

			// create extrusion
			ext = new Extrusion ("kraken", profile, tentacle.toSections ()); scene.root.addChild (ext);

			// add some material
			var material:BitmapMaterial = new BitmapMaterial (Bitmap (new Tentacle).bitmapData,
				new MaterialAttributes (new MediumAttributes (0xFFFFFFFF, new Vector (0, 0, 310), new Vector (0, 0, 310))));
			material.setTiling (1, 15);
			ext.appearance = new Appearance (material);

			// show it
			scene.render ();
		}
	}
}