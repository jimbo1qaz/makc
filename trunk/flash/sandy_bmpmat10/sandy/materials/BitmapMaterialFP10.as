package sandy.materials
{
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import sandy.core.data.Polygon;
	import sandy.core.Scene3D;
	import sandy.core.scenegraph.Camera3D;
	import sandy.materials.attributes.MaterialAttributes;

	/*
	 * BitmapMaterial hack to use flash player 10 native 3D rendering in Sandy.
	 */
	public class BitmapMaterialFP10 extends BitmapMaterial
	{
		public function BitmapMaterialFP10 (p_oTexture:BitmapData = null, p_oAttr:MaterialAttributes = null) {
			// precision is always 1 now
			super (p_oTexture, p_oAttr, 1);
		}

		override protected function _createTextureMatrix(p_nU0:Number, p_nV0:Number, p_nU1:Number, p_nV1:Number, p_nU2:Number, p_nV2:Number):Matrix 
		{
			// since precision is not setter, we need to override it here to prevent user from setting it to 0
			precision = 1;
			// computing texture matrix is no longer necessary, but BitmapMaterial code needs it to be present
			// we will just store these UVs there
			return new Matrix (p_nU0, p_nV0, p_nU1, p_nV1, p_nU2, p_nV2);
		}

		protected var focalLength:Number, screenZScale:Number;

		override public function renderPolygon(p_oScene:Scene3D, p_oPolygon:Polygon, p_mcContainer:Sprite):void 
		{
			var cam:Camera3D = p_oScene.camera;
			focalLength = cam.focalLength; screenZScale = cam.projectionMatrix.n22 * cam.viewport.height2;

			super.renderPolygon(p_oScene, p_oPolygon, p_mcContainer);
		}

		protected var vertices:Vector.<Number> = new Vector.<Number>();
		protected var uvtData:Vector.<Number> = new Vector.<Number>();

		override protected function renderRec(u0:Number, v0:Number, u1:Number, v1:Number, u2:Number, v2:Number,
		ax:Number, ay:Number, az:Number, bx:Number, by:Number, bz:Number, cx:Number, cy:Number, cz:Number):void
		{
			// init drawTriangles() parameters for single triangle
			vertices [0] = ax; vertices [1] = ay; uvtData [0] = u0; uvtData [1] = v0; uvtData [2] = focalLength / (focalLength + az * screenZScale);
			vertices [2] = bx; vertices [3] = by; uvtData [3] = u1; uvtData [4] = v1; uvtData [5] = focalLength / (focalLength + bz * screenZScale);
			vertices [4] = cx; vertices [5] = cy; uvtData [6] = u2; uvtData [7] = v2; uvtData [8] = focalLength / (focalLength + cz * screenZScale);
			// render it
			graphics.lineStyle ();
			graphics.beginBitmapFill (m_oTexture, matrix /* ignored */, repeat, smooth);
			graphics.drawTriangles (vertices, null, uvtData);
			graphics.endFill ();
		}
	}
}