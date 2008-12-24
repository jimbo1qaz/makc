package {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import sandy.core.data.UVCoord;
	import sandy.materials.Appearance;
	import sandy.materials.BitmapMaterial;
	
	public class Island extends Hexagon {

		[Embed (source="island_heightmap.jpg")]
		private var HeightMap:Class;

		[Embed (source="island_texture.jpg")]
		private var TextureMap:Class;

		public function Island () {
			super ("island", 600, 4, Hexagon.ZX_ALIGNED);

			var hmap:BitmapData = Bitmap (new HeightMap).bitmapData;
			for (var i:int = 0; i < geometry.aVertex.length; i++) {
				geometry.aVertex [i].y = 0xFF & hmap.getPixel (
					UVCoord (geometry.aUVCoords [i]).u * (hmap.width -1),
					UVCoord (geometry.aUVCoords [i]).v * (hmap.height -1)
				);
			}

			var mat:BitmapMaterial = new BitmapMaterial (Bitmap (new TextureMap).bitmapData);
			mat.smooth = true; appearance = new Appearance (mat);

			enableBackFaceCulling = true;
		}
	}
}