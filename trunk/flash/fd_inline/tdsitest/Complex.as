package {
	public class Complex {
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
}