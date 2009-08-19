package  {
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.engine3d.primitives.Box;
	import flash.geom.Point;
	
	/**
	* Sky box.
	* @author makc
	*/
	public class SkyBox extends Box {

		/**
		 * Constructor.
		 * @param	rotateTop top image rotation angle in degrees (0, 90, 180 or 270).
		 * @param	rotateBottom bottom image rotation angle in degrees (0, 90, 180 or 270).
		 */
		public function SkyBox (front:TextureMaterial, back:TextureMaterial, left:TextureMaterial, right:TextureMaterial, top:TextureMaterial, bottom:TextureMaterial,
			rotateTop:Number = 0, rotateBottom:Number = 0) {

			// large box with inward face normales
			super (50000, 50000, 50000, 1, 1, 1, true);

			// assign materials
			setMaterialToSurface (front, "front"); front.repeat = false;
			setMaterialToSurface (back, "back"); back.repeat = false;
			setMaterialToSurface (left, "left"); left.repeat = false;
			setMaterialToSurface (right, "right"); right.repeat = false;
			setMaterialToSurface (top, "top"); top.repeat = false;
			setMaterialToSurface (bottom, "bottom"); bottom.repeat = false;

			var i:int, n:int, f:Face;

			// rotate top
			f = surfaces ["top"].faces.peek ();
			n = Math.max (0, rotateTop / 90);
			for (i = 0; i < n; i++) rotateFaceBy90 (f);

			// rotate bottom
			f = surfaces ["bottom"].faces.peek ();
			n = Math.max (0, rotateBottom / 90);
			for (i = 0; i < n; i++) rotateFaceBy90 (f);
		}

		private function rotateFaceBy90 (f:Face):void {
			var aUV:Point, bUV:Point, cUV:Point;
			aUV = f.aUV;
			bUV = f.bUV;
			cUV = f.cUV;
			f.aUV = aUV.add (cUV).subtract (bUV);
			f.bUV = aUV;
			f.cUV = bUV;
		}

	}
	
}