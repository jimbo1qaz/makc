package {
	import flash.display.*; 

	public class LogoPng extends Bitmap {

		/**
		 * This needs image named QuakePngLinkageIdentifier in library.
		 */
		public function LogoPng() {
			super (new QuakePngLinkageIdentifier (1, 1));
		}
	}
}