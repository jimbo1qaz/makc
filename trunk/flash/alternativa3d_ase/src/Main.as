package  
{
	import alternativa.engine3d.core.*     
	import alternativa.engine3d.display.*     
	import alternativa.engine3d.materials.*     
	import alternativa.types.*;

	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	
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

			// set up some view
			scene = new Scene3D; scene.root = new Object3D;
			scene.root.addChild (model); model.rotationX = Math.PI / 2;
			var view:View = new View; view.camera = new Camera3D;
  
			camHolder = new Object3D;
			camHolder.addChild (view.camera); scene.root.addChild (camHolder);

			view.width = stage.stageWidth; view.height = stage.stageHeight; addChild (view);
			view.camera.z = -500;
  
			addEventListener (Event.ENTER_FRAME, render); stage.quality = "low";
		}

		private function render (e:Event):void
		{
			// show up
			camHolder.rotationY += 0.1; scene.calculate ();
		}
		
	}
	
}