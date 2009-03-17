package {
	
	import flash.display.Sprite;
	import flash.events.Event;
	
	import org.libspark.flartoolkit.core.transmat.FLARTransMatResult;
	import sandy_flar.FLARBaseNode;
	import sandy_flar.FLARCamera3D;

	import sandy.core.*;
	import sandy.core.scenegraph.*;
	
	public class SandyARApp extends ARAppBase {
		
		protected var _viewport:Sprite;
		protected var _camera3d:FLARCamera3D;
		protected var _scene:Scene3D;
		protected var _baseNode:FLARBaseNode;
		
		protected var _resultMat:FLARTransMatResult = new FLARTransMatResult();
		
		public function SandyARApp() {
		}
		
		protected override function onInit():void {
			super.onInit();

			this._capture.width = 640;
			this._capture.height = 480;
			this.addChild (this._capture);

			this._viewport = this.addChild(new Sprite()) as Sprite;
			this._viewport.scaleX = 640 / 320;
			this._viewport.scaleY = 480 / 240;

			this._camera3d = new FLARCamera3D(this._param, 320, 240);

			this._scene = new Scene3D ("s", this._viewport, this._camera3d, new Group);
			this._baseNode = new FLARBaseNode(); this._scene.root.addChild (this._baseNode);
			
			this.addEventListener(Event.ENTER_FRAME, this._onEnterFrame);
		}
		
		private function _onEnterFrame(e:Event = null):void {
			this._capture.bitmapData.draw(this._video);
			if (this._detector.detectMarkerLite(this._raster, 80) && this._detector.getConfidence() > 0.5) {
				this._detector.getTransformMatrix(this._resultMat);
				this._baseNode.setTransformMatrix(this._resultMat);
				this._baseNode.visible = true;
			} else {
				this._baseNode.visible = false;
			}
			this._baseNode.changed = true; // just in case...
			this._scene.render();
		}
	}
}