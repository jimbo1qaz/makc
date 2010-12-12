package {
	import apparat.inline.Macro;
	public class ComplexMath extends Macro {
		public static function copy (a:Complex, b:*):void {
			var B:Complex = b as Complex;
			if (B) {
				a.x = B.x;
				a.y = B.y;
			} else {
				a.x = b;
				a.y = 0;
			}
		}
		public static function add (a:Complex, b:Complex):void {
			a.x += b.x;
			a.y += b.y;
		}
		public static function sub (a:Complex, b:Complex):void {
			a.x -= b.x;
			a.y -= b.y;
		}
		public static function mul (a:Complex, b:Complex):void {
			var X:Number = a.x * b.x - a.y * b.y;
			var Y:Number = a.y * b.x + a.x * b.y;
			a.x = X;
			a.y = Y;
		}
		public static function div (a:Complex, b:Complex):void {
			var D:Number = b.x * b.x + b.y * b.y;
			var X:Number = (a.x * b.x + a.y * b.y) / D;
			var Y:Number = (a.y * b.x - a.x * b.y) / D;
			a.x = X;
			a.y = Y;
		}
		public static function neg (a:Complex):void {
			a.x = -a.x;
			a.y = -a.y;
		}
	}
}