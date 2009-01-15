package  
{
	import alternativa.engine3d.core.*;
	import alternativa.engine3d.display.*;
	import alternativa.engine3d.materials.*;
	import alternativa.types.*;

	import flash.display.*;
	import flash.events.Event;
	import flash.geom.ColorTransform;
	
	/**
	* Example of embedded ASE parsing.
	* @author makc
	*/
	public class Main extends Sprite
	{
		// The model used is by Ken 'kat' Beyer
		// http://www.katsbits.com/htm/models/kt_moai.htm

		[Embed(source = "moai_1_1a.ase", mimeType = "application/octet-stream")]
		private var ModelClass:Class;

		[Embed(source = "stone_granate.jpg")]
		private var TextureClass:Class;

		private var camHolder:Object3D;
		private var scene:Scene3D;

		public function Main () 
		{
			// create model object
			var model:Mesh = new EmbeddedASEParser (new ModelClass);
			model.cloneMaterialToAllSurfaces (
				new TextureMaterial (new Texture (Bitmap (new TextureClass).bitmapData)));

			// set up anaglyph view
			scene = new Scene3D; scene.root = new Object3D;
			scene.root.addChild (model); model.rotationX = Math.PI / 2;

			var viewLeft:View  = new View; viewLeft.camera  = new Camera3D; viewLeft.camera.x = -3;
			var viewRight:View = new View; viewRight.camera = new Camera3D; viewRight.camera.x = 3;

			// from http://en.wikipedia.org/wiki/Anaglyph_image#Anaglyphs_containing_color_information
			// "To make an anaglyph containing color information using color images, replace the red
			// channel of the right-eye image with the red channel of the left-eye image... Eye sensitivity
			// balance can be improved by selecting the green channel and reducing it using a linear curve
			// selection (e.g. reduce to 12.5%). Select the blue channel and reduce somewhat less (e.g.
			// reduce by 5%). This action compensates for the eye's lower sensitivity to red and its high
			// sensitivity to green".
			viewLeft.transform.colorTransform  = new ColorTransform (1, 0, 0);
			viewRight.transform.colorTransform = new ColorTransform (0, 1 - 0.125, 1 - 0.05);

			camHolder = new Object3D; scene.root.addChild (camHolder);
			camHolder.addChild (viewLeft.camera); camHolder.addChild (viewRight.camera);

			viewLeft.width  = viewRight.width  = stage.stageWidth;
			viewLeft.height = viewRight.height = stage.stageHeight;
			viewLeft.camera.z = viewRight.camera.z = -300;
			addChild (viewLeft); addChild (viewRight);

  			viewRight.blendMode = BlendMode.ADD;

			// move it a bit to reduce anaglyph ghosting
			viewRight.x = 9;

			addEventListener (Event.ENTER_FRAME, render);
			stage.align = StageAlign.TOP; stage.scaleMode = StageScaleMode.NO_SCALE; stage.quality = StageQuality.LOW;
		}

		private function render (e:Event):void
		{
			camHolder.rotationX = 0.005 * (stage.stageHeight * 0.5 - stage.mouseY);
			camHolder.rotationY += 0.1; scene.calculate ();
		}
		
	}
	
}