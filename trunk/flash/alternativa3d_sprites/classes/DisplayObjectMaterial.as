package  
{
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.*;
	import alternativa.engine3d.display.*;
	import alternativa.engine3d.materials.*;
	import alternativa.types.*;
	import flash.display.DisplayObject;
	
	use namespace alternativa3d
	public class DisplayObjectMaterial extends SpriteMaterial
	{
		private var _dobj:DisplayObject;

		public function get dobj ():DisplayObject { return _dobj; }
		public function set dobj (v:DisplayObject):void {
			// remove from skin 1st
			if (_dobj != null)
				if (_dobj.parent != null)
					_dobj.parent.removeChild (_dobj);
			_dobj = v;
		}
		
		public function DisplayObjectMaterial (displayObject:DisplayObject = null, alpha:Number = 1, blendMode:String = "normal") {
			super (alpha, blendMode); _dobj = displayObject;
		}

		private var _pt:Point3D;

		// TODO handle clipping?
		override alternativa3d function canDraw (camera:Camera3D):Boolean {
			if (_dobj == null) return false;

			// global coords of the sprite
			_pt = camera.globalToLocal (sprite.globalCoords);

			// in front of camera only, please
			_dobj.visible = (0 < _pt.z); return _dobj.visible;
		}

		override alternativa3d function draw (camera:Camera3D, skin:Skin):void {

			// do what parent did not
			skin.alpha = _alpha;
			skin.blendMode = _blendMode;

			// if _dobj is not in skin yet, add it
			if (skin != _dobj.parent) {
				skin.addChild (_dobj);
			}

			// place it accordingly
			var zoom:Number = camera.orthographic ? 1 : camera.focalLength / _pt.z;
			_dobj.x = _pt.x * zoom; _dobj.scaleX = zoom;
			_dobj.y = _pt.y * zoom; _dobj.scaleY = zoom;
		}

	}
	
}