package {
	import flash.display.Sprite;
	public class Main extends Sprite {
		public function Main () {
			// anything preprocessed with GPP must be in 2nd source folder for things to work smoothly
			var t:Test = new Test; t.calculate ();
		}
	}
}