/* 
 * Experimental modification of FLARToolKit rgb2bin filter
 *
 * This work is based on the FLARToolKit by Saqoosha
 * http://www.libspark.org/wiki/saqoosha/FLARToolKit
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this framework; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */
package rgb2bin {
	
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.filters.BlurFilter;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import org.libspark.flartoolkit.core.raster.FLARRaster_BitmapData;
	import org.libspark.flartoolkit.core.raster.IFLARRaster;
	import org.libspark.flartoolkit.core.raster.rgb.FLARRgbRaster_BitmapData;
	import org.libspark.flartoolkit.core.raster.rgb.IFLARRgbRaster;

	import org.libspark.flartoolkit.core.FLARSquare;
	import org.libspark.flartoolkit.core.rasterfilter.rgb2bin.IFLARRasterFilter_RgbToBin;

	public class AdaptiveToBinFilter implements IFLARRasterFilter_RgbToBin {
		
		private static const ZERO_POINT:Point = new Point();
		private static const ONE_POINT:Point = new Point(1, 1);
		private static const MONO_FILTER:ColorMatrixFilter = new ColorMatrixFilter([
			0.2989, 0.5866, 0.1145, 0, 0,
			0.2989, 0.5866, 0.1145, 0, 0,
			0.2989, 0.5866, 0.1145, 0, 0,
			0, 0, 0, 1, 0
		]);

		// averaging filter
		private static const AVG_FILTER:BlurFilter = new BlurFilter;

		// rectangle to look for marker at
		public var searchArea:Rectangle;

		public function adjustSearchArea (rect:Rectangle, square:FLARSquare, confidence:Number):void {
			var imageRect:Rectangle = rect.clone ();
			imageRect.inflate (-1, -1);

			if (searchArea == null)
				searchArea = imageRect.clone ();

			var targetRect:Rectangle = imageRect.clone ();
			if (square != null) {
				var i:int;
				var x:Number = Number.MAX_VALUE;
				var y:Number = Number.MAX_VALUE;
				for (i = 0; i < 4; i++) {
					x = Math.min (x, square.sqvertex [i].x);
					y = Math.min (y, square.sqvertex [i].y);
				}
				var w:Number = 0;
				var h:Number = 0;
				for (i = 0; i < 4; i++) {
					w = Math.max (w, Math.abs (square.sqvertex [i].x - x));
					h = Math.max (h, Math.abs (square.sqvertex [i].y - y));
				}
				if (w * h > 0) {
					targetRect.x = x; targetRect.width = w;
					targetRect.y = y; targetRect.height = h;
				} else {
					// some really thin square :(
				}
			}

			// poor confidence means marker could move and we need to search larger area
			var a:Number = 0.9 * confidence, b:Number = 1 - a;
			searchArea.x = int (a * targetRect.x + b * imageRect.x);
			searchArea.y = int (a * targetRect.y + b * imageRect.y);
			searchArea.width  = int (a * targetRect.width  + b * imageRect.width);
			searchArea.height = int (a * targetRect.height + b * imageRect.height);

		}

		private var _threshold:int;
		private var _tmp:BitmapData;

		public function AdaptiveToBinFilter(i_threshold:int) {
			this._threshold = i_threshold;
		}

		public function setThreshold(i_threshold:int):void {
			this._threshold = i_threshold;
		}

		public function doFilter(i_input:IFLARRgbRaster, i_output:IFLARRaster):void {
	
			// most of FLARToolKit samples have threshold hardcoded to be 80,
			// we want those to result into reasonable blur values here (32)
			AVG_FILTER.blurX = 0.4 * this._threshold;
			AVG_FILTER.blurY = 0.4 * this._threshold;
			AVG_FILTER.quality = 2;

			var inbmp:BitmapData = FLARRgbRaster_BitmapData(i_input).bitmapData;
			if (!this._tmp) {
				this._tmp = new BitmapData(inbmp.width, inbmp.height, false, 0x0);
				adjustSearchArea (this._tmp.rect, null, 0);
			} else if (inbmp.width != this._tmp.width || inbmp.height != this._tmp.height) {
				this._tmp.dispose();
				this._tmp = new BitmapData(inbmp.width, inbmp.height, false, 0x0);
				adjustSearchArea (this._tmp.rect, null, 0);
			}
			this._tmp.applyFilter(inbmp, inbmp.rect, ZERO_POINT, MONO_FILTER);
			var outbmp:BitmapData = FLARRaster_BitmapData(i_output).bitmapData;
			outbmp.fillRect(outbmp.rect, 0x0);

			if (standardOperation) {
				// so that we can switch on-the-fly in test runs
				outbmp.threshold(this._tmp, searchArea, searchArea.topLeft, '<=', this._threshold, 0xffffffff, 0xff);
			} else {
				// adapt threshold to local average value
				outbmp.copyPixels (this._tmp, searchArea, searchArea.topLeft);
				this._tmp.applyFilter (this._tmp, searchArea, searchArea.topLeft, AVG_FILTER);
				this._tmp.draw (outbmp, null, null, BlendMode.SUBTRACT);
				outbmp.copyPixels (this._tmp, searchArea, searchArea.topLeft);
				outbmp.threshold(outbmp, searchArea, searchArea.topLeft, '>', 0, 0xffffffff, 0xff);
			}
		}


		public var standardOperation:Boolean = false;
	}
}