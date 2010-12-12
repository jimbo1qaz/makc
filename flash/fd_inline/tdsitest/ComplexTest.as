package {
	import flash.display.Sprite;
	
	public class ComplexTest extends Sprite {
		
		public function ComplexTest () {

			var A:Complex = new Complex ( Math.random () );
			var B:Complex = new Complex ( Math.random () );
			var C:Complex = new Complex ( Math.random () );
			var D:Complex = new Complex ( Math.random () );

			// f(z)
			trace ("equation z^4 +",
				A.x.toPrecision (4), "z^3 +",
				B.x.toPrecision (4), "z^2 +",
				C.x.toPrecision (4), "z +",
				D.x.toPrecision (4), "= 0");

			// http://en.wikipedia.org/wiki/Durand-Kerner_method#Explanation
			var p:Complex = new Complex (1.0, 0.0); // ^0
			var q:Complex = new Complex (0.4, 0.9); // ^1
			var r:Complex = new Complex (0.4, 0.9); ComplexMath.mul (r, r); // ^2
			var s:Complex = new Complex (0.4, 0.9); ComplexMath.mul (s, r); // ^3
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
				ComplexMath.copy (X1, p);
				ComplexMath.copy (X2, X1); ComplexMath.mul (X2, p);
				ComplexMath.copy (X3, X2); ComplexMath.mul (X3, p);
				ComplexMath.copy (X4, X3); ComplexMath.mul (X4, p);
				ComplexMath.copy (P, D);
				ComplexMath.mul (X1, C); ComplexMath.add (P, X1);
				ComplexMath.mul (X2, B); ComplexMath.add (P, X2);
				ComplexMath.mul (X3, A); ComplexMath.add (P, X3);
				ComplexMath.add (P, X4);
				ComplexMath.copy (X1, p); ComplexMath.sub (X1, q);
				ComplexMath.copy (X2, p); ComplexMath.sub (X2, r);
				ComplexMath.copy (X3, p); ComplexMath.sub (X3, s);
				ComplexMath.mul (X1, X2); ComplexMath.mul (X1, X3); ComplexMath.div (P, X1);
				ComplexMath.neg (P); ComplexMath.add (P, p);
				// Q = q-f(q)/((q-p)(q-r)(q-s))
				ComplexMath.copy (X1, q);
				ComplexMath.copy (X2, X1); ComplexMath.mul (X2, q);
				ComplexMath.copy (X3, X2); ComplexMath.mul (X3, q);
				ComplexMath.copy (X4, X3); ComplexMath.mul (X4, q);
				ComplexMath.copy (Q, D);
				ComplexMath.mul (X1, C); ComplexMath.add (Q, X1);
				ComplexMath.mul (X2, B); ComplexMath.add (Q, X2);
				ComplexMath.mul (X3, A); ComplexMath.add (Q, X3);
				ComplexMath.add (Q, X4);
				ComplexMath.copy (X1, q); ComplexMath.sub (X1, p);
				ComplexMath.copy (X2, q); ComplexMath.sub (X2, r);
				ComplexMath.copy (X3, q); ComplexMath.sub (X3, s);
				ComplexMath.mul (X1, X2); ComplexMath.mul (X1, X3); ComplexMath.div (Q, X1);
				ComplexMath.neg (Q); ComplexMath.add (Q, q);
				// R = r-f(r)/((r-p)(r-q)(r-s))
				ComplexMath.copy (X1, r);
				ComplexMath.copy (X2, X1); ComplexMath.mul (X2, r);
				ComplexMath.copy (X3, X2); ComplexMath.mul (X3, r);
				ComplexMath.copy (X4, X3); ComplexMath.mul (X4, r);
				ComplexMath.copy (R, D);
				ComplexMath.mul (X1, C); ComplexMath.add (R, X1);
				ComplexMath.mul (X2, B); ComplexMath.add (R, X2);
				ComplexMath.mul (X3, A); ComplexMath.add (R, X3);
				ComplexMath.add (R, X4);
				ComplexMath.copy (X1, r); ComplexMath.sub (X1, p);
				ComplexMath.copy (X2, r); ComplexMath.sub (X2, q);
				ComplexMath.copy (X3, r); ComplexMath.sub (X3, s);
				ComplexMath.mul (X1, X2); ComplexMath.mul (X1, X3); ComplexMath.div (R, X1);
				ComplexMath.neg (R); ComplexMath.add (R, r);
				// S = s-f(s)/((s-p)(s-q)(s-r))
				ComplexMath.copy (X1, s);
				ComplexMath.copy (X2, X1); ComplexMath.mul (X2, s);
				ComplexMath.copy (X3, X2); ComplexMath.mul (X3, s);
				ComplexMath.copy (X4, X3); ComplexMath.mul (X4, s);
				ComplexMath.copy (S, D);
				ComplexMath.mul (X1, C); ComplexMath.add (S, X1);
				ComplexMath.mul (X2, B); ComplexMath.add (S, X2);
				ComplexMath.mul (X3, A); ComplexMath.add (S, X3);
				ComplexMath.add (S, X4);
				ComplexMath.copy (X1, s); ComplexMath.sub (X1, p);
				ComplexMath.copy (X2, s); ComplexMath.sub (X2, q);
				ComplexMath.copy (X3, s); ComplexMath.sub (X3, r);
				ComplexMath.mul (X1, X2); ComplexMath.mul (X1, X3); ComplexMath.div (S, X1);
				ComplexMath.neg (S); ComplexMath.add (S, s);
				// on to next iteration
				ComplexMath.copy (p, P); ComplexMath.copy (q, Q); ComplexMath.copy (r, R); ComplexMath.copy (s, S);
			}

			trace ("roots: ", p, q, r, s);
		}
	}
}