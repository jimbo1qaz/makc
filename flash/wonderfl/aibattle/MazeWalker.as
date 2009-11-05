package {
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.system.Security;

	dynamic public class MazeWalker extends Sprite {
	    /**
	     * Simple maze walker for http://tinyurl.com/aibattle
	     * @see http://makc3d.wordpress.com/2009/10/31/ai-battle-again/
	     */
		public function MazeWalker () {
			Security.allowDomain ("http://makc.googlecode.com/");
			if (stage != null) {
				var tf:TextField = new TextField;
				tf.autoSize = "left";
				tf.text = stage.loaderInfo.url;
				addChild (tf);
			}
		}

		private var lastAngle:int = -1;
		public function behavior ():void {
			// find closest wall
			var i:int, d:Number = 1e6, a:Number = 0;
			for (i=0; i< this.inColors.length; i++) {
				if (this.inColors [i] == 0) {
					if (this.inDistances [i] < d) {
						a = i; d = this.inDistances [i];
					}
				}
			}

			if (d > 20) {
				if (lastAngle < 0) {
					// get closer
					this.outMoveAngle = a;
				} else {
					// maintain direction
					this.outMoveAngle = lastAngle;
				}
			} else {
				// move along the wall
				lastAngle = (a + 9) % 36;
				this.outMoveAngle = lastAngle;
			}
			this.outMoveSpeed = this.inMaxSpeed;
		}
	}
}