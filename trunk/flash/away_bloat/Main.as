package  
{
	import away3d.containers.View3D;
	import away3d.core.clip.RectangleClipping;
	import away3d.core.base.Mesh;
	import away3d.lights.DirectionalLight3D;
	import away3d.loaders.Md2still;
	import away3d.materials.Dot3BitmapMaterial;

	import com.as3dmod.ModifierStack;
	import com.as3dmod.modifiers.Bloat;
	import com.as3dmod.plugins.away3d.LibraryAway3d;

	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.geom.Rectangle;

	import net.hires.utils.Stats;

	/**
	* Away3D boobies demo re-visited.
	* @author makc
	*/
	[SWF(backgroundColor="#000333", frameRate="25", width="800", height="600")]
	public class Main extends Sprite
	{
		private var torso:Mesh;
		private var view:View3D;

		[Embed(source="md2/torsov2.md2", mimeType="application/octet-stream")]
		private var Torso:Class;

		[Embed(source="md2/torso_marble2.jpg")]
		private var TorsoImage:Class;
		
		[Embed(source="md2/torso_normal_400.jpg")]
		private var TorsoNormal:Class;

		private var stack:ModifierStack;
		private var bLeft:Bloat, bRight:Bloat;

		public function Main() 
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP;

			// create view
			view = new View3D; addChild (view);
			view.clip = new RectangleClipping(-400, -300, +400, +300);
			view.scrollRect = new Rectangle(-400 ,-300, 800, 600);

			// create light
			var light:DirectionalLight3D = new DirectionalLight3D ({color:0xFFFFFF, ambient:0.25, diffuse:0.75, specular:0.9});
			light.x = light.y = light.z = 40000; view.scene.addChild( light );

			// create torso
			torso = Md2still.parse (new Torso, {
				material: new Dot3BitmapMaterial (Bitmap (new TorsoImage).bitmapData, Bitmap (new TorsoNormal).bitmapData)
			}); torso.rotationX = 10; view.scene.addChild (torso);

			// fit torso on the screen
			torso.scale (0.1); torso.movePivot ((torso.minX + torso.maxX)/2, (torso.minY + torso.maxY)/2, (torso.minZ + torso.maxZ)/2);

			// create modifier stack
			stack = new ModifierStack (new LibraryAway3d, torso);

			// add breast implants
			bLeft = new Bloat; bLeft.a = 0.001; bLeft.center.y = 1100; bLeft.center.z = 10300; bLeft.radius = 0;
			bLeft.center.x = +900; stack.addModifier (bLeft);
			
			bRight = new Bloat; bRight.a = 0.001; bRight.center.y = 1100; bRight.center.z = 10300; bRight.radius = 0;
			bRight.center.x = -900; stack.addModifier (bRight);

			// wire events
			addEventListener (Event.ENTER_FRAME, onEnterFrame);

			// add stats
			addChild (new Stats);
		}

		private var angle:Number = 180;
		private var radius:Number = 0;

		private function onEnterFrame (foo:Event):void {

			// mouse controls (k > 0 gives mouse some easing)
			var k:Number = 0.6;
			angle = k * angle + (1 - k) * (180 + 0.3 * (stage.stageWidth / 2 - mouseX));
			radius = k * radius + (1 - k) * Math.min (400, Math.max (0, stage.stageHeight - mouseY));

			// inflate breasts
			bLeft.radius = bRight.radius = radius;

			// rotate torso
			torso.rotationY = angle;

			// apply modifiers and render
			stack.apply (); view.render();
		}

	}
	
}