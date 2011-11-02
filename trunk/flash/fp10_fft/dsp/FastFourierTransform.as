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
			var n2:int = n >> 1, k2:int;
			nu = int (Math.log (n) * Math.LOG2E);
			var nu1:int = nu - 1;
			var tr:Number, ti:Number, p:Number, arg:Number, c:Number, s:Number;
			var i:int, k:int = 0;
			for (i = 0; i < n; i++) {
				xre [i] = samples [i]; xim [i] = 0.0;
			}

			var aS:Number = 2 * Math.PI / n;

			// bitrev vars
			var _br_i:int, _br_j1:int, _br_j2:int;

			for (var l:int = 1; l <= nu; l++) {
				while (k < n) {
					for (i = 1; i <= n2; i++) {
//						p = bitrev (k >> nu1);
						_br_j1 = k >> nu1; p = 0;
						for (_br_i = 1; _br_i <= nu; _br_i++) {
							_br_j2 = _br_j1 >> 1;
							p = 2 * (p - _br_j2) + _br_j1;
							_br_j1 = _br_j2;
						}

						arg = aS * p;
						c = Math.cos (arg);
						s = Math.sin (arg);
						k2 = k + n2;
						xr = xre [k2];
						xi = xim [k2];
						tr = xr * c + xi * s;
						ti = xi * c - xr * s;
						xre [k2] = xre [k] - tr;
						xim [k2] = xim [k] - ti;
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
//				r = bitrev (k);
				_br_j1 = k; r = 0;
				for (_br_i = 1; _br_i <= nu; _br_i++) {
					_br_j2 = _br_j1 >> 1;
					r = 2 * (r - _br_j2) + _br_j1;
					_br_j1 = _br_j2;
				}

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

	}
}