package 
{
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Mesh;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Scene3D;
	import alternativa.engine3d.core.Sprite3D;
	import alternativa.engine3d.display.View;
	import alternativa.engine3d.loaders.Loader3DS;
	import alternativa.types.Matrix3D;
	import alternativa.types.Point3D;
	import alternativa.utils.FPS;
	import alternativa.utils.MathUtils;

	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.filters.GlowFilter;

	public class Main extends Sprite
	{
		private var scene:Scene3D;
		private var view:View;
		private var loader:Loader3DS;

		public function Main () 
		{
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			FPS.init (stage);

			scene = new Scene3D; scene.root = new Object3D;
			view = new View; view.camera = new Camera3D; scene.root.addChild (view.camera); addChild (view);

			loader = new Loader3DS;
			loader.addEventListener (Event.COMPLETE, onLoadingComplete);
			loader.load ("telias.free.fr/baselight.3ds");

			onResize (null);
			stage.addEventListener (Event.RESIZE, onResize);
			stage.addEventListener (Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener (KeyboardEvent.KEY_UP, onKeyUp);
		}

		private function onResize(e:Event):void {
			view.width = stage.stageWidth; view.height = stage.stageHeight;
		}

		private var thing:Mesh;
		private function onLoadingComplete (e:Event):void {
			thing = loader.content.children.peek ();
		}

		// vars for unrolled object addition loop
		// only one object per frame is added to distribute init delays
		private var vN:int = 1, vi:int = -vN, vj:int = -vN, va:Array = [], vt:Number = 0;

		private function duplicateThing ():void
		{
			// instead of what you'd normally do...

			// var obj:Object3D = thing.clone ();
			// scene.root.addChild (obj);
			
			// ...goes this code:

			var subView:SubView = new SubView (thing.clone (), view);
			scene.root.addChild (subView.sprite);

			// place subview sprite when we want it
			subView.sprite.x = 60 * vi; subView.sprite.y = 60 * vj;
			subView.sprite.scaleX = subView.sprite.scaleY = subView.sprite.scaleZ = 5;

			// remember subview
			va.push (subView);
		}

		private var filter:GlowFilter;

		private function onEnterFrame(e:Event):void
		{
			// unrolled object addition loop
			if ( (thing != null) && ((vi < vN + 1) || (vj < vN + 1)) )
			{
				duplicateThing ();

				vj ++; if (vj == vN + 1) { vi ++; if (vi < vN + 1) vj = -vN; }
			}

			// main demo
			else if (thing != null)
			{
				demo ();				
			}

			orbit (); scene.calculate ();
		}

		private function demo ():void {
			var i0:int = Math.round (Math.random () * (va.length -1));
			for (var i:int = 0; i < va.length; i++) {
				va [i].view.filters = (i == i0) ? [ new GlowFilter (0xFFFFFF * Math.random (), 1, 60, 60) ] : [];
				if (i == i0) va [i].sprite.rotationZ += 0.3;
			}
		}

		private var hard:Boolean = false;
		private var t:Number = Math.PI * 0.75;
		private function orbit ():void
		{
			// give it a hard time?
			if (hard) t += 0.1;
			if (t > Math.PI * 2) t -= Math.PI * 2;
			var cam:Camera3D = view.camera;

			// move along the orbit
			cam.x = 250 * Math.sin (t); cam.y = 250 * Math.cos (t); cam.z = 100;

			// look back at origin
			var dx:Number = 0 - cam.x;
			var dy:Number = 0 - cam.y;
			var dz:Number = 0 - cam.z;
			cam.rotationZ = -Math.atan2 (dx, dy);
			cam.rotationX = +Math.atan2 (dz, Math.sqrt (dx * dx + dy * dy)) - MathUtils.DEG90;
		}

		private function onKeyUp (e:KeyboardEvent):void {
			hard = !hard;
		}

	}
	
}