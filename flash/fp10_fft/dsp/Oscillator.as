package dsp {
	/**
	 * Driven harmonic oscillator, d^2x(t)/dt^2 + 2cw0 dx(t)/dt + w0^2 x(t) = F(t).
	 * @author makc
	 */
	public class Oscillator {
		/**
		 * Creates an oscillator instance.
		 * @param	w Oscillator frequency.
		 * @param	c Damping parameter, 0 < c << 1 for underdamped.
		 * @param	dt Integration step.
		 */
		public function Oscillator (w:Number, c:Number, dt:Number = 0.02) {
			b = c;
			tstep = dt;
			w0 = w;
			xold = [0, 0];
			xnew = [0, 0];
			// RK4
			coefs = [ 0.0, 0.5, 0.5, 1.0 ];
			nums  = [ 1.0, 2.0, 2.0, 1.0 ];
			arg = new Array (xold.length);
			A = new Array (xold.length);
			ff = [0, 0];
			// average energy
			ae = 0;
			es = []; for (var i:int = 0, N:Number = Math.max (1, 1 / (w0 * tstep)); i < N; i++) es [i] = 0;
		}

		/**
		 * Calculates c(w0) for similar resonance amplitude.
		 * @param	w Oscillator frequency.
		 * @param	c Damping parameter for w = 1.
		 */
		public static function CalculateDamping (w:Number, c:Number):Number {
			return c / (w * w);
		}

		/**
		 * Updates oscillator.
		 * @param	F Driving force.
		 */
		public function update (F:Number):void {
			RKstep (F, tstep * 6.28318531);
			xold [0] = xnew [0];
			xold [1] = xnew [1];

			// update average energy
			var inc:Number = 0.5 * (xnew [0] * xnew [0] + xnew [1] * xnew [1]) / es.length;
			var dec:Number = es.shift (); es.push (inc);
			ae += inc;
			ae -= dec;
		}

		/**
		 * Oscillator position.
		 */
		public function get x ():Number { return xnew [0]; }

		/**
		 * Oscillator energy averaged over 1/w.
		 */
		public function get energy ():Number { return ae; }

		/**
		 * Resonance frequency for a sinusoidal driving force.
		 */
		public function get resonanceFrequency ():Number {
			return w0 * Math.sqrt (1 - 2 * b * b);
		}

		private var b:Number;
		private var tstep:Number;
		private var w0:Number;
		private var xold:Array;
		private var xnew:Array;

		// RK4
		private var coefs:Array;
		private var nums:Array;
		private var arg:Array;
		private var A:Array;
		private var ff:Array;
		private function RKstep (f:Number, ttstep:Number):void {
			var j:int, k:int, len:int = xold.length;
			for (j = 0; j < len; ++j) {
				xnew [j] = xold [j];
				A[j] = 0.0;
			}
			for (k = 0; k < 4; ++k) {
				// REMOVED var tval:Number = tt + coefs[k] * ttstep;
				for (j = 0; j < len; ++j) {
					arg[j] = (xold[j] + coefs[k] * A[j]);
				}

				// oscillator equation for t = tval (current, f)
				ff[0] = arg[1];
				ff[1] = f - w0 * w0 * arg[0] - (2.0 * b * w0 * arg[1]);

				for (j = 0; j < len; ++j) {
					A[j] = (ttstep * ff[j]);
					xnew[j] += nums[k] * A[j] / 6.0;
				}
			}
		}

		// average energy
		private var ae:Number;
		private var es:Array;
	}
}