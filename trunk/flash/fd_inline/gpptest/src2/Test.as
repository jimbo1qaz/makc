/* Obfuscation:
 *
 #define A _local12
 #define B _local13
 #define C _local14
 #define D _local15
 *
 * (for release build you don't have to obfuscate local variables names)
 *
 #define P _local16
 #define Q _local17
 #define R _local18
 #define S _local19
 #define p _local8
 #define q _local7
 #define r _local6
 #define s _local5
 #define X1 _local4
 #define X2 _local3
 #define X3 _local2
 #define X4 _local1
 *
 * Inlined complex arithmetics:
 *
 #define initVars(foo) var _D:Number, _X:Number, _Y:Number, _B:Complex
 #define copy(a,b) _B = b as Complex; if (_B) { a.x = _B.x; a.y = _B.y; } else { a.x = Number(b); a.y = 0; }
 #define add(a,b) a.x += b.x; a.y += b.y;
 #define sub(a,b) a.x -= b.x; a.y -= b.y;
 #define mul(a,b) _X = a.x * b.x - a.y * b.y; _Y = a.y * b.x + a.x * b.y; a.x = _X; a.y = _Y;
 #define div(a,b) _D = b.x * b.x + b.y * b.y; _X = (a.x * b.x + a.y * b.y) / _D; _Y = (a.y * b.x - a.x * b.y) / _D; a.x = _X; a.y = _Y;
 #define neg(a) a.x = -a.x; a.y = -a.y;
 */

package {

	public class Test {

		/* in case FD code completion is confused by undeclared functions - declare them
		 * as a bonus, you get code completion in macros :)
		 #ifdef undefined_constant
		 */
		private function initVars(foo:Number):void {}
		private function copy(a:Complex,b:*):void {}
		private function add(a:Complex,b:Complex):void {}
		private function sub(a:Complex,b:Complex):void {}
		private function mul(a:Complex,b:Complex):void {}
		private function div(a:Complex,b:Complex):void {}
		private function neg(a:Complex):void {}
		/*
		 #endif
		 */

		// following variables names will be obfuscated
		private var A:Complex;
		private var B:Complex;
		private var C:Complex;
		private var D:Complex;

		public function calculate ():void {
			initVars(0);

			A = new Complex ( Math.random () );
			B = new Complex ( Math.random () );
			C = new Complex ( Math.random () );
			D = new Complex ( Math.random () );

			// f(z)
			trace ("equation z^4 +",
				A.x.toPrecision (4), "z^3 +",
				B.x.toPrecision (4), "z^2 +",
				C.x.toPrecision (4), "z +",
				D.x.toPrecision (4), "= 0");

			// http://en.wikipedia.org/wiki/Durand-Kerner_method#Explanation
			var p:Complex = new Complex (1.0, 0.0); // ^0
			var q:Complex = new Complex (0.4, 0.9); // ^1
			var r:Complex = new Complex (0.4, 0.9); mul(r, r); // ^2
			var s:Complex = new Complex (0.4, 0.9); mul(s, r); // ^3
			var P:Complex = new Complex;
			var Q:Complex = new Complex;
			var R:Complex = new Complex;
			var S:Complex = new Complex;
			var X1:Complex = new Complex;
			var X2:Complex = new Complex;
			var X3:Complex = new Complex;
			var X4:Complex = new Complex;

			var N:int = 20;
			while (N-->0) {
				// P = p-f(p)/((p-q)(p-r)(p-s))
				copy(X1, p);
				copy(X2, X1); mul(X2, p);
				copy(X3, X2); mul(X3, p);
				copy(X4, X3); mul(X4, p);
				copy(P, D);
				mul(X1, C); add(P, X1);
				mul(X2, B); add(P, X2);
				mul(X3, A); add(P, X3);
				add(P, X4);
				copy(X1, p); sub(X1, q);
				copy(X2, p); sub(X2, r);
				copy(X3, p); sub(X3, s);
				mul(X1, X2); mul(X1, X3); div(P, X1);
				neg(P); add(P, p);
				// Q = q-f(q)/((q-p)(q-r)(q-s))
				copy(X1, q);
				copy(X2, X1); mul(X2, q);
				copy(X3, X2); mul(X3, q);
				copy(X4, X3); mul(X4, q);
				copy(Q, D);
				mul(X1, C); add(Q, X1);
				mul(X2, B); add(Q, X2);
				mul(X3, A); add(Q, X3);
				add(Q, X4);
				copy(X1, q); sub(X1, p);
				copy(X2, q); sub(X2, r);
				copy(X3, q); sub(X3, s);
				mul(X1, X2); mul(X1, X3); div(Q, X1);
				neg(Q); add(Q, q);
				// R = r-f(r)/((r-p)(r-q)(r-s))
				copy(X1, r);
				copy(X2, X1); mul(X2, r);
				copy(X3, X2); mul(X3, r);
				copy(X4, X3); mul(X4, r);
				copy(R, D);
				mul(X1, C); add(R, X1);
				mul(X2, B); add(R, X2);
				mul(X3, A); add(R, X3);
				add(R, X4);
				copy(X1, r); sub(X1, p);
				copy(X2, r); sub(X2, q);
				copy(X3, r); sub(X3, s);
				mul(X1, X2); mul(X1, X3); div(R, X1);
				neg(R); add(R, r);
				// S = s-f(s)/((s-p)(s-q)(s-r))
				copy(X1, s);
				copy(X2, X1); mul(X2, s);
				copy(X3, X2); mul(X3, s);
				copy(X4, X3); mul(X4, s);
				copy(S, D);
				mul(X1, C); add(S, X1);
				mul(X2, B); add(S, X2);
				mul(X3, A); add(S, X3);
				add(S, X4);
				copy(X1, s); sub(X1, p);
				copy(X2, s); sub(X2, q);
				copy(X3, s); sub(X3, r);
				mul(X1, X2); mul(X1, X3); div(S, X1);
				neg(S); add(S, s);
				// on to next iteration
				copy(p, P); copy(q, Q); copy(r, R); copy(s, S);
			}

			trace ("roots: ", p, q, r, s);
		}
	}
}

class Complex {
	public var x:Number;
	public var y:Number;
	public function Complex (x:Number = 0, y:Number = 0) {
		this.x = x;
		this.y = y;
	}
	CONFIG::debug {
		public function toString ():String {
			return "(" + x.toPrecision (4) + " " + ((y > 0) ? "+" : "") + y.toPrecision (4) + "i)";
		}
	}
}