package  {
	import alternativa.engine3d.controllers.WalkController;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Scene3D;
	import alternativa.engine3d.display.View;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	/**
	* Skybox demo.
	* @author makc
	*/
	public class SBTest extends View {
		private var ctrl:WalkController;
		private var scene:Scene3D;
		private var box:SkyBox;


		public function SBTest () {
			super (); camera = new Camera3D;

			scene = new Scene3D; scene.root = new Object3D; scene.root.addChild (camera);
			ctrl = new WalkController (stage); ctrl.object = camera; //ctrl.unbindAll ();

			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;

			addEventListener (Event.ENTER_FRAME, render);
			addEventListener (Event.ADDED_TO_STAGE, resize);

			// set up skybox buttons for the demo
			[Embed(source='panos/fae04/thumb.jpg')] var ThumbA:Class;
			createSkyBoxButton (new ThumbA, "fae04", 10);

			[Embed(source='panos/farcry/thumb.jpg')] var ThumbB:Class;
			createSkyBoxButton (new ThumbB, "farcry", 52);

			[Embed(source='panos/sky15/thumb.jpg')] var ThumbC:Class;
			createSkyBoxButton (new ThumbC, "sky15", 94);
		}

		private function render (e:Event):void {
			ctrl.processInput (); scene.calculate ();
		}

		private function resize (e:Event):void {
			if (e.type == Event.ADDED_TO_STAGE) {
				removeEventListener (Event.ADDED_TO_STAGE, resize);
				stage.addEventListener (Event.RESIZE, resize);
			}

			width = stage.stageWidth;
			height = stage.stageHeight;
		}

		// skybox images map
		private var imap:Object = {
			fae04: {
				front:	"panos/fae04/faesky04b.jpg",
				back:	"panos/fae04/faesky04f.jpg",
				left:	"panos/fae04/faesky04l.jpg",
				right:	"panos/fae04/faesky04r.jpg",
				top:	"panos/fae04/faesky04u.jpg",
				bottom:	"panos/fae04/faesky04d.jpg",
				rotTop:	180,
				rotBot: 180
			},
			farcry: {
				front:	"panos/farcry/Farcry15_ft.jpg",
				back:	"panos/farcry/Farcry15_bk.jpg",
				left:	"panos/farcry/Farcry15_lf.jpg",
				right:	"panos/farcry/Farcry15_rt.jpg",
				top:	"panos/farcry/Farcry15_up.jpg",
				bottom:	"panos/farcry/Farcry15_dn.jpg",
				rotTop:	90,
				rotBot: 90
			},
			sky15: {
				front:	"panos/sky15/Side4.jpg",
				back:	"panos/sky15/Side2.jpg",
				left:	"panos/sky15/Side5.jpg",
				right:	"panos/sky15/Side3.jpg",
				top:	"panos/sky15/Side6.jpg",
				bottom:	"panos/sky15/Side1.jpg",
				rotTop:	0,
				rotBot: 180
			}
		}

		private function loadSkyBoxByName (name:String):void {
			if (box != null) scene.root.removeChild (box);

			// create selected skybox
			box = new SkyBox (
				new TextureLoadMaterial (imap [name]["front"]),
				new TextureLoadMaterial (imap [name]["back"]),
				new TextureLoadMaterial (imap [name]["left"]),
				new TextureLoadMaterial (imap [name]["right"]),
				new TextureLoadMaterial (imap [name]["top"]),
				new TextureLoadMaterial (imap [name]["bottom"]),
				imap [name]["rotTop"],
				imap [name]["rotBot"]
			); scene.root.addChild (box);
		}

		private function createSkyBoxButton (thumb:Bitmap, skybox:String, x:Number):void {
			var button:Sprite = new Sprite; button.addChild (thumb); addChild (button);
			button.x = x; button.y = 10; button.buttonMode = true; button.name = skybox;
			button.addEventListener (MouseEvent.CLICK, function (e:MouseEvent):void {
				loadSkyBoxByName (Sprite (e.currentTarget).name);
			});
		}
	}

}