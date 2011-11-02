package dsp {
	
	/**
	* Port of java FFT class.
	* @author Dr Iain A Robin iain@xunil.uklinux.net
	* @see http://www.dsptutor.freeuk.com/analyser/SpectrumAnalyser.html
	*/
	public class FastFourierTransform {

		/**
		 * Magnitudes (corresponding frequency ranges from 0 to half of sampling frequency).
		 */
		public var magnitudes:Vector.<Number> = new <Number> [];

		/**
		 * Analyzes samples and fills <code>magnitudes</code> array.
		 * @param	samples Array of numbers to analyze (length must be power of 2).
		 */
		public function analyze (samples:Vector.<Number>):void {
			// minimal sanity check
			if ((samples == null) || (samples.length < 2)) {
				magnitudes.length = 0; return;
			}
			// find power of 2 not exceeding samles length
			var n:int = 2; while (n * 2 <= samples.length) n *= 2;
			// transform samples
			var n2:int = n >> 1;
			nu = int (Math.log (n) * Math.LOG2E);
			var nu1:int = nu - 1;
			var tr:Number, ti:Number, p:Number, arg:Number, c:Number, s:Number;
			var i:int, k:int = 0;
			for (i = 0; i < n; i++) {
				xre [i] = samples [i]; xim [i] = 0.0;
			}

			for (var l:int = 1; l <= nu; l++) {
				while (k < n) {
					for (i = 1; i <= n2; i++) {
						p = bitrev (k >> nu1);
						arg = 2 * Math.PI * p / n;
						c = Math.cos (arg);
						s = Math.sin (arg);
						tr = xre [k + n2] * c + xim [k + n2] * s;
						ti = xim [k + n2] * c - xre [k + n2] * s;
						xre [k + n2] = xre [k] - tr;
						xim [k + n2] = xim [k] - ti;
						xre [k] += tr;
						xim [k] += ti;
						k++;
					}
					k += n2;
				}
				k = 0;
				nu1--;
				n2 = n2 >> 1;
			}

			k = 0;
			var r:int;
			while (k < n) {
				r = bitrev (k);
				if (r > k) {
					tr = xre [k];
					ti = xim [k];
					xre [k] = xre [r];
					xim [k] = xim [r];
					xre [r] = tr;
					xim [r] = ti;
				}
				k++;
			}

			n2 = n >> 1;
			var n2i:Number = 2 / n, xr:Number, xi:Number;
			
			for (i = 0; i < n2; i++) {
				xr = xre [i]; xi = xim [i];
				magnitudes [i] = Math.sqrt (xr * xr + xi * xi) * n2i;
			}
			magnitudes [0] *= 0.5;
			magnitudes.length = n2;
		}

		private var xre:Vector.<Number> = new <Number> [];
		private var xim:Vector.<Number> = new <Number> [];

		private var nu:int;
		private function bitrev (j:int):int {
			var j2:int;
			var j1:int = j;
			var k:int = 0;
			for (var i:int = 1; i <= nu; i++) {
				j2 = j1 >> 1;
				k = 2 * k + j1 - 2 * j2;
				j1 = j2;
			}
			return k;
		}

	}
}