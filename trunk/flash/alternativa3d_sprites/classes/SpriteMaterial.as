﻿package
{
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.*;
	import alternativa.engine3d.display.*;
	import alternativa.engine3d.materials.*;
	import flash.display.DisplayObject;
	import flash.utils.ByteArray;

	use namespace alternativa3d
	public class SpriteMaterial extends SurfaceMaterial
	{
		private var _dobj:DisplayObject;

		public function SpriteMaterial(displayObject:DisplayObject, alpha:Number = 1, blendMode:String = "normal") {
			super(alpha, blendMode); _dobj = displayObject;
		}

		override alternativa3d function canDraw(poly:PolyPrimitive):Boolean {
			return (_dobj != null);
		}

		override alternativa3d function draw(camera:Camera3D, skin:Skin, vertexCount:uint, vertices:Array):void {
			// if no points, leave... does this really happen ??
			if (vertexCount < 1) return;

			// do what parent did not
			skin.alpha = _alpha;
			skin.blendMode = _blendMode;

			// take 1st point
			var pt:DrawPoint = vertices [0];

			// if _dobj is not in skin yet, add it... but how the hell we remove it ??
			if (!skin.contains (_dobj)) {
				skin.addChild (_dobj);
			}

			// place it accordingly
			var zoom:Number = camera.orthographic ? 1 : camera.focalLength / pt.z;
			_dobj.x = pt.x * zoom; _dobj.scaleX = zoom;
			_dobj.y = pt.y * zoom; _dobj.scaleY = zoom;

			// show
			_dobj.visible = true;
		}

		override alternativa3d function clear (skin:Skin):void {
			// hide
			_dobj.visible = false;
		}

		/**
		 * Can we clone supplied DisplayObject ?
		 */
		override public function clone():Material {
			return null;
		}

		/**
		 * Helper method to make a sprite in one line of code.
		 */
		public static function make (displayObject:DisplayObject):Mesh {
			var m:Mesh = new Mesh;
			m.createVertex(0, 0, 0, 0);
			m.createVertex(0, 0, 0, 1);
			m.createVertex(0, 0, 0, 2);
			m.createSurface([m.createFace([0, 1, 2], 0)], 0);
			m.setMaterialToSurface(new SpriteMaterial (displayObject), 0);
			m.mobility = 9e9;
			return m;
		}
	}
}
