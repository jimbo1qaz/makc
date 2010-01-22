package  {
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.text.TextField;
	
	/**
	 * Very bad ray tracer :)
	 * @author makc
	 * @license WTFPLv2
	 */
	public class RayTracer extends Sprite {
		public function RayTracer () {
			// lightmap
			var loader:Loader = new Loader;
			loader.contentLoaderInfo.addEventListener (Event.COMPLETE, function onHazLightmap (e:Event):void {
				lightmap = loader.content ["bitmapData"]; init ();
			});
			loader.load (new URLRequest ("http://assets.wonderfl.net/images/related_images/0/0d/0dbe/0dbe43b47f333087e064078a329b331c73ad6dd7"/*"lightmap.jpg"*/), 
				new LoaderContext (true));
		}

		private const S:int = 100; // tracing SxS bitmap
		private const N:int = 7; // rays per ray per generation
		private const TTL:int = 2; // generations: rays per pixel should be < N^TTL
		private const M:int = 50; // max steps per frame
		private const STEP:Number = 0.002; // 0.0 < step << 1.0
		private const NPF:int = 666; // rays per frame

		private var SS:int = S * S;

		private var canvas:BitmapData;
		private var lightmap:BitmapData;

		private var red:Vector.<Number>;
		private var green:Vector.<Number>;
		private var blue:Vector.<Number>;
		private var num:Vector.<int>;
		private var rays:Vector.<Ray>;
		private var directions:Vector.<Ray>;
		private var frame:int = 0;

		private var stats:TextField;

		private function init ():void {
			canvas = new BitmapData (S, S, false, 0);
			graphics.beginBitmapFill (canvas); graphics.drawRect (0, 0, S, S);
			var scale:Number = 465 / S; scaleX = scale; scaleY = scale;

			stats = new TextField; addChild (stats);
			stats.scaleX = 1 / scaleX; stats.scaleY = 1 / scaleY;
			stats.autoSize = "left"; stats.textColor = 0xFFFFFF;

			// init arrays
			red = new Vector.<Number> (SS);
			green = new Vector.<Number> (SS);
			blue = new Vector.<Number> (SS);
			num = new Vector.<int> (SS);
			rays = new Vector.<Ray>;
			directions = new Vector.<Ray>;

			var i:int, j:int, k:int;

			// uniformly distributed directions:
			// Bauer, Robert, "Distribution of Points on a Sphere with Application to Star Catalogs",
			// Journal of Guidance, Control, and Dynamics, January-February 2000, vol.23 no.1 (130-137).
			for (i = 1; i <= N; i++) {
				var d:Ray = new Ray;
				var phi:Number = Math.acos ( -1 + (2 * i -1) / N);
				var theta:Number = Math.sqrt (N * Math.PI) * phi;
				d.dx = Math.cos (theta) * Math.sin (phi);
				d.dy = Math.sin (theta) * Math.sin (phi);
				d.dz = Math.cos (phi);
				directions.push (d);
			}

			// select random spot on unit sphere
			k = int (Math.random () * N) % N;
			var camPosX:Number = directions [k].dx;
			var camPosY:Number = directions [k].dy;
			var camPosZ:Number = directions [k].dz;

			// select random camera orientation
			k = int (Math.random () * N) % N;
			var camFwdX:Number = 0.3 * directions [k].dx - camPosX;
			var camFwdY:Number = 0.3 * directions [k].dy - camPosY;
			var camFwdZ:Number = 0.3 * directions [k].dz - camPosZ;
			var camFwdL:Number = 1 / Math.sqrt (camFwdX * camFwdX + camFwdY * camFwdY + camFwdZ * camFwdZ);
			camFwdX *= camFwdL; camFwdY *= camFwdL; camFwdZ *= camFwdL;
			// unless we are extremely unlucky, camFwdZ should be never 0
			var camUpX:Number = 0;
			var camUpY:Number = camFwdZ;
			var camUpZ:Number = -camFwdY;
			var camUpL:Number = 1 / Math.sqrt (camUpX * camUpX + camUpY * camUpY + camUpZ * camUpZ);
			camUpX *= camUpL; camUpY *= camUpL; camUpZ *= camUpL;
			var camSideX:Number = camFwdY * camUpZ - camUpY * camFwdZ;
			var camSideY:Number = camFwdZ * camUpX - camUpZ * camFwdX;
			var camSideZ:Number = camFwdX * camUpY - camUpX * camFwdY;
/*camPosX = -0.498168;
camPosY = 0.334408;
camPosZ = 0.800000;
camFwdX = 0.454971;
camFwdY = -0.593262;
camFwdZ = -0.664109;
camUpX = 0.000000;
camUpY = -0.745766;
camUpZ = 0.666208;
camSideX = -0.890506;
camSideY = -0.303105;
camSideZ = -0.339302;*/

			// generation zero
			var fovAtan:Number = 1.5; // 1 = 90°, ∞ = 180°
			for (i = 0; i < S; i++)
			for (j = 0; j < S; j++) {
				var r:Ray = new Ray;
				r.s = i + S * j;
				r.x = camPosX; r.dx = camFwdX + ((i - 0.5 * S) * camUpX + (j - 0.5 * S) * camSideX) * fovAtan / S;
				r.y = camPosY; r.dy = camFwdY + ((i - 0.5 * S) * camUpY + (j - 0.5 * S) * camSideY) * fovAtan / S;
				r.z = camPosZ; r.dz = camFwdZ + ((i - 0.5 * S) * camUpZ + (j - 0.5 * S) * camSideZ) * fovAtan / S;
				var rdL:Number = STEP / Math.sqrt (r.dx * r.dx + r.dy * r.dy + r.dz * r.dz);
				r.dx *= rdL; r.dy *= rdL; r.dz *= rdL;
				rays.push (r);
			}

			addEventListener (Event.ENTER_FRAME, loop);
		}

		private function floatmod (i:Number, j:Number):Number {
			return i - (int (i / j) * j);
		}

		private function hitTest (x:Number, y:Number, z:Number):Boolean {
			// Menger sponge:
			// http://www.fractalforums.com/3d-fractal-generation/revenge-of-the-half-eaten-menger-sponge/
			/*x *= 2;
			y *= 2;
			z *= 2;*/
			x += 0.5;
			y += 0.5;
			z += 0.5;
			var iterations:int = 4;
			if ((x<0)||(x>1)||(y<0)||(y>1)||(z<0)||(z>1)) return false;
			var p:Number = 3;
			for (var m:int = 1; m < iterations; m++) {
				var xa:Number = floatmod (x*p, 3);
				var ya:Number = floatmod (y*p, 3);
				var za:Number = floatmod (z*p, 3);
				if (
					((xa > 1.0) && (xa < 2.0)   &&   (ya > 1.0) && (ya < 2.0)) ||
					((ya > 1.0) && (ya < 2.0)   &&   (za > 1.0) && (za < 2.0)) ||
					((xa > 1.0) && (xa < 2.0)   &&   (za > 1.0) && (za < 2.0))
					) return false;
				p *= 3;
			}
			return true;
			//return (x * x + y * y + z * z < 0.1);
		}

		private function appDist (x:Number, y:Number, z:Number):Number {
			/*x *= 2;
			y *= 2;
			z *= 2;*/
			x += 0.5;
			y += 0.5;
			z += 0.5;

			var iterations:int = 4;
			var d:Number = -1;
			if (x < 0) if ((d < 0)||(-x < d)) d = -x;
			if (x > 1) if ((d < 0)||(x-1 < d)) d = x-1;
			if (y < 0) if ((d < 0)||(-y < d)) d = -y;
			if (y > 1) if ((d < 0)||(y-1 < d)) d = y-1;
			if (z < 0) if ((d < 0)||(-z < d)) d = -z;
			if (z > 1) if ((d < 0)||(z-1 < d)) d = z-1;
			if (d > 0) return d;

			var p:Number = 3;
			for (var m:int = 1; m < iterations; m++) {
				var xa:Number = floatmod (x*p, 3);
				var ya:Number = floatmod (y*p, 3);
				var za:Number = floatmod (z*p, 3);
				d = -1;
				if ((xa > 1.0) && (xa < 2.0)   &&   (ya > 1.0) && (ya < 2.0)) {
					if ((d < 0)||(xa-1 < d)) d = xa-1;
					if ((d < 0)||(2-xa < d)) d = 2-xa;
					if ((d < 0)||(ya-1 < d)) d = ya-1;
					if ((d < 0)||(2-ya < d)) d = 2-ya;
				}
				if ((za > 1.0) && (za < 2.0)   &&   (ya > 1.0) && (ya < 2.0)) {
					if ((d < 0)||(za-1 < d)) d = za-1;
					if ((d < 0)||(2-za < d)) d = 2-za;
					if ((d < 0)||(ya-1 < d)) d = ya-1;
					if ((d < 0)||(2-ya < d)) d = 2-ya;
				}
				if ((xa > 1.0) && (xa < 2.0)   &&   (za > 1.0) && (za < 2.0)) {
					if ((d < 0)||(xa-1 < d)) d = xa-1;
					if ((d < 0)||(2-xa < d)) d = 2-xa;
					if ((d < 0)||(za-1 < d)) d = za-1;
					if ((d < 0)||(2-za < d)) d = 2-za;
				}
				if (d > 0) return d / p;
				p *= 3;
			}
			return 0;
		}

		private function loop (e:Event):void {
			frame++;
			if (frame % 30 == 0) {
				// update once in a while
				var s:int, sum:Number = 1;
				for (s = 0; s < SS; s++) sum += num [s]; sum /= SS;
				
				canvas.lock ();
				for (s = 0; s < SS; s++) {
					// ugly hack for sky :(
					var ns:int = (num [s] > 1) ? /* body */ sum : /* sky: */1;
					var ir:int = int (red   [s] / ns); if (ir > 255) ir = 255;
					var ig:int = int (green [s] / ns); if (ig > 255) ig = 255;
					var ib:int = int (blue  [s] / ns); if (ib > 255) ib = 255;
					canvas.setPixel (s % S, s / S, ir * 65536 + ig * 256 +ib);
				}
				canvas.unlock ();

				stats.text = rays.length + " rays left...";
			}

			for (var foo:int = 0; foo < NPF; foo++) {
				if (rays.length > 0) {
					// process one ray
					var r:Ray = rays [0];
					for (var bar:int = 0; bar < M; bar++) {
						/*r.x += r.dx; r.y += r.dy; r.z += r.dz;
						if (hitTest (r.x, r.y, r.z)) {*/
						var step:Number = appDist (r.x, r.y, r.z);
						if (step < STEP) step = STEP;

						var rx0:Number = r.x, rx1:Number = r.x + r.dx * step, rx:Number = rx1;
						var ry0:Number = r.y, ry1:Number = r.y + r.dy * step, ry:Number = ry1;
						var rz0:Number = r.z, rz1:Number = r.z + r.dz * step, rz:Number = rz1;

						if (hitTest (rx, ry, rz)) while (
							(rx1 - rx0) * (rx1 - rx0) +
							(ry1 - ry0) * (ry1 - ry0) +
							(rz1 - rz0) * (rz1 - rz0) > (0.00001 * 0.00001)) {
							// http://www.codinginstinct.com/2008/11/raytracing-4d-fractals-visualizing-four.html
							rx = 0.5 * (rx0 + rx1); ry = 0.5 * (ry0 + ry1); rz = 0.5 * (rz0 + rz1);
							if (hitTest (rx, ry, rz)) {
								rx1 = rx; ry1 = ry; rz1 = rz;
							} else {
								rx0 = rx; ry0 = ry; rz0 = rz;
							}
						}

						r.x = rx1; r.y = ry1; r.z = rz1;

						if (hitTest (r.x, r.y, r.z)) {
							// we hit something - scatter
							if (r.generation < TTL)
							for (var n1:int = 0; n1 < N; n1++) {
								var r1:Ray = new Ray;
								r1.s = r.s;
								r1.generation = r.generation + 1;
								r1.x = r.x; r1.y = r.y; r1.z = r.z;
								r1.dx = directions [n1].dx;
								r1.dy = directions [n1].dy;
								r1.dz = directions [n1].dz;
								// this basically defines "material"
								r1.magnitude = r.magnitude * 0.9;
								rays.push (r1);
							}

							rays.shift (); break;
						} else {
							var d2:Number = r.x * r.x + r.y * r.y + r.z * r.z;
							if (d2 > 1.1) {
								// we hit light - get color from lightmap
								// this SHOULD be determined by the way lightmap is made ;)
								d2 = 1 / Math.sqrt (d2); r.x *= d2; r.y *= d2; r.z *= d2;
								var lx:int = lightmap.width * 0.25 * ( (r.z > 0) ? 1 + r.x : 3 - r.x );
								var ly:int = lightmap.height * 0.5 * (1 + r.y);
								var c:uint = lightmap.getPixel (lx, ly);
								red [r.s] += r.magnitude * ((c & 0xFF0000) >> 16);
								green [r.s] += r.magnitude * ((c & 0xFF00) >> 8);
								blue [r.s] += r.magnitude * (c & 0xFF);
								num [r.s] += 1;

								rays.shift (); break;
							}
						}
					}
				} else {
					// no more rays left
					break;
				}
			}
		}
	}
}

class Ray {
	public var generation:int = 0, magnitude:Number = 1;
	public var x:Number = 0, y:Number = 0, z:Number = 0;
	public var dx:Number, dy:Number, dz:Number;
	public var s:int;
}