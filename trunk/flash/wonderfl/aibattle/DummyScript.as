// work in progres... wait...
package {
	import flash.display.Sprite;
	import flash.text.TextField;

	dynamic public class DummyScript extends Sprite {
		public function DummyScript () {
			if (stage != null) {
				var tf:TextField = new TextField;
				tf.autoSize = "left";
				tf.text = stage.loaderInfo.url;
				addChild (tf);
			}
		}

		public function behavior ():void {
			var i:int;
			if (!this.inHasBullet) {
				// no bullet, let's get it
				var bulletAt:int = -1;
				for (i=0; i< this.inColors.length; i++) {
					if (this.inColors[i] == 2) {
						bulletAt = i; break;
					}
				}
				// go up until we see it
				this.outMoveAngle = (bulletAt < 0) ? 27 : bulletAt;
				this.outMoveSpeed = this.inMaxSpeed;
			} else {
				// look around for enemy
				var enemyAt:int = -1;
				for (i=0; i< this.inColors.length; i++) {
					if (this.inColors[i] == 1) {
						enemyAt = i; break;
					}
				}
				if (enemyAt > -1) {
					// throw the bullet
					this.outThrowBullet = true;
					this.outThrowAngle = enemyAt;
				}
				// up we go
				this.outMoveAngle = 27;
				this.outMoveSpeed = this.inMaxSpeed;
			}
		}
	}
}