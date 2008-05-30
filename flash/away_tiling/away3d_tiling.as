package {
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.geom.Rectangle;

	import away3d.core.math.Number3D;
	import away3d.core.clip.RectangleClipping;
	import away3d.containers.View3D;
	import away3d.materials.TransformBitmapMaterial;
	import away3d.primitives.Plane;

	/**
	* Away3D port of Sandy bitmap tiling tutorial (r554)
	* http://www.flashsandy.org/tutorials/3.0/v302_tiling
	*/
	public class away3d_tiling extends Sprite {
		public function away3d_tiling () {
		        addEventListener (Event.ADDED_TO_STAGE, init);
		}

		private var view:View3D;

		private var dsMat1:TransformBitmapMaterial;
		private var dsMat2:TransformBitmapMaterial;
		private var dsMat3:TransformBitmapMaterial;

		private function init(foo:Event):void {
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP;

			// init away stuff
			view = new View3D();
			view.clip = new RectangleClipping(-300, -150, +300, +150);
			view.scrollRect = new Rectangle(-300 ,-150, 600, 300);
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			addChild(view);

			// create death star materials
			dsMat1 = new TransformBitmapMaterial (new ImageDS1 (1, 1), {precision: 3, repeat: true});
			dsMat2 = new TransformBitmapMaterial (new ImageDS2 (1, 1), {precision: 3, repeat: true});
			dsMat3 = new TransformBitmapMaterial (new ImageDS3 (1, 1), {precision: 3, repeat: true});

			// create planes
			var pLeft:Plane = new Plane ({ name:"pLeft", segmentsW:20, segmentsH:20, material:dsMat1,
				width: 10000, height: 10000, x: -5000 -200, y: -200, z: -4000 });

			var pRiht:Plane = new Plane ({ name:"pRiht", segmentsW:20, segmentsH:20, material:dsMat1,
				width: 10000, height: 10000, x: +5000 +200, y: -200, z: -4000 });

			var pSidL:Plane = new Plane ({ name:"pSidL", segmentsW:2, segmentsH:20, material:dsMat2,
				width: 400, height: 10000, x: -200, y: -400, z: -4000, rotationZ: 90,
				// we are actually going to be looking at plane backface
				bothsides: true });

			var pSidR:Plane = new Plane ({ name:"pSidR", segmentsW:2, segmentsH:20, material:dsMat2,
				width: 400, height: 10000, x: +200, y: -400, z: -4000, rotationZ: 90 });

			var pBott:Plane = new Plane ({ name:"pBott", segmentsW:2, segmentsH:20, material:dsMat3,
				width: 400, height: 10000, y: -600, z: -4000 });

			// add them to scene
			view.scene.addChild (pLeft); view.scene.addChild (pRiht);
			view.scene.addChild (pSidL); view.scene.addChild (pSidR);
			view.scene.addChild (pBott);
			
			// scale materials
			dsMat1.scaleX = dsMat1.scaleY = dsMat2.scaleY = dsMat3.scaleY = -1/10;
		}

		private var offset:Number = 0;
		private var target:Number3D = new Number3D (0, -200, 0);

		private function onEnterFrame(foo:Event):void {
			dsMat1.offsetY = -offset * dsMat1.height;
			dsMat2.offsetY = -offset * dsMat2.height;
			dsMat3.offsetY = -offset * dsMat3.height;

			// add some interactivity
			offset += 1e-3 + 5e-5 * (300 - mouseY); if (offset > 1) offset -= 1;

			view.camera.x = mouseX - 300;
			view.camera.y = mouseY;

			view.camera.lookAt (target);
			view.render();
		}
	}
}