package  {
	import flash.display.BitmapData;
	import flash.display.Shader;
	import flash.display.Sprite;
	import flash.geom.Point;

	[SWF(width=600,height=200)]
	public class ThreePointGradient extends Sprite {

		public function ThreePointGradient () {
			// shader from http://www.petrileskinen.fi/Actionscript/ThreePointGradient/ThreePointGradientPBK.html
			[Embed(source="pixelero.pbj",mimeType="application/octet-stream")] var S1:Class;

			// non-linear shader
			[Embed(source="makc.pbj",mimeType="application/octet-stream")] var S2:Class;

			// via beginBitmapFill
			drawTri (new Point (  0, 100), new Point (100, 0), new Point (100, 200),
				0x000000, 0x00ff00, 0xff00cc);
			drawTri (new Point (200, 100), new Point (100, 0), new Point (100, 200),
				0xffffff, 0x00ff00, 0xff00cc);

			// via beginShaderFill
			drawTri2 (new Point (200, 100), new Point (300, 0), new Point (300, 200),
				0x000000, 0x00ff00, 0xff00cc, new Shader (new S1));
			drawTri2 (new Point (400, 100), new Point (300, 0), new Point (300, 200),
				0xffffff, 0x00ff00, 0xff00cc, new Shader (new S1));

			drawTri2 (new Point (400, 100), new Point (500, 0), new Point (500, 200),
				0x000000, 0x00ff00, 0xff00cc, new Shader (new S2));
			drawTri2 (new Point (600, 100), new Point (500, 0), new Point (500, 200),
				0xffffff, 0x00ff00, 0xff00cc, new Shader (new S2));
		}

		private var dtFill:BitmapData;
		private var dtXYs:Vector.<Number> = new Vector.<Number>(6, true);
		private var dtUVs:Vector.<Number> = new Vector.<Number>(6, true);
		private function drawTri (p0:Point, p1:Point, p2:Point, c0:uint, c1:uint, c2:uint):void {

			dtXYs [0] = p0.x; dtXYs [1] = p0.y;
			dtXYs [2] = p1.x; dtXYs [3] = p1.y;
			dtXYs [4] = p2.x; dtXYs [5] = p2.y;

			dtUVs [0] = 0; dtUVs [1] = 0;
			dtUVs [2] = 0; dtUVs [3] = 1;
			dtUVs [4] = 1; dtUVs [5] = 0;

			dtFill = new BitmapData (2, 2, false, 0);
			dtFill.setPixel (0, 0, c0);
			dtFill.setPixel (0, 1, c1);
			dtFill.setPixel (1, 0, c2);
			dtFill.setPixel (1, 1,
				Math.min (255, ((c1 & 0xFF0000) >> 16) + ((c2 & 0xFF0000) >> 16)) * 65536 +
				Math.min (255, ((c1 & 0x00FF00) >>  8) + ((c2 & 0x00FF00) >>  8)) * 256 +
				Math.min (255, ((c1 & 0x0000FF) >>  0) + ((c2 & 0x0000FF) >>  0)) * 1
			);

			graphics.lineStyle ();
			graphics.beginBitmapFill (dtFill, null, false, true);
			graphics.drawTriangles (dtXYs, null, dtUVs);
		}

		private function drawTri2 (p0:Point, p1:Point, p2:Point, c0:uint, c1:uint, c2:uint, s:Shader):void {
			s.data.point1.value = [p0.x, p0.y];
			s.data.point2.value = [p1.x, p1.y];
			s.data.point3.value = [p2.x, p2.y];
			s.data.color1.value = [((c0 & 0xFF0000) >> 16) / 255.0, ((c0 & 0x00FF00) >>  8) / 255.0, (c0 & 255) / 255.0, 1.0];
			s.data.color2.value = [((c1 & 0xFF0000) >> 16) / 255.0, ((c1 & 0x00FF00) >>  8) / 255.0, (c1 & 255) / 255.0, 1.0];
			s.data.color3.value = [((c2 & 0xFF0000) >> 16) / 255.0, ((c2 & 0x00FF00) >>  8) / 255.0, (c2 & 255) / 255.0, 1.0];
			graphics.beginShaderFill (s);
			graphics.moveTo (p0.x, p0.y);
			graphics.lineTo (p1.x, p1.y);
			graphics.lineTo (p2.x, p2.y);
			graphics.endFill ();
		}
	}
}