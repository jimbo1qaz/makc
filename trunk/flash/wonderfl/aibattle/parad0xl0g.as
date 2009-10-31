package {
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.system.Security;

	dynamic public class parad0xl0g extends Sprite {
	    /**
	     * parad0xl0g bot.
	     * @author parad0xl0g
	     * @see http://makc3d.wordpress.com/2009/10/31/ai-battle-again/
	     */
		public function parad0xl0g () {
			Security.allowDomain ("http://makc.googlecode.com/");
			if (stage != null) {
				var tf:TextField = new TextField;
				tf.autoSize = "left";
				tf.text = stage.loaderInfo.url;
				addChild (tf);
			}
			this.curAngle = 27;
		}

		public function behavior ():void {

var i:int, wallAt:int = -1, enemyAt:int = -1;
for (i=0; i< this.inColors.length; i++) {
  if (this.inColors[i] == 0 && this.inDistances[i]<20) {
    wallAt = i; break;
  }
}
if ( wallAt > -1 ){
  var minAngle:int = wallAt  + 18;
  var maxAngle:int  = minAngle + 9;
  var temp:int = Math.floor( Math.random()*(maxAngle-minAngle)+minAngle );
  this.curAngle = (temp >35)?(temp%35):temp;
}
this.outMoveAngle = this.curAngle;
this.outMoveSpeed = this.inMaxSpeed;
if (this.inHasBullet){
  var dangerAt:int = -1;
  enemyAt = -1;
  for (i=0; i< this.inColors.length; i++) {
    if (this.inColors[i] == 3) {
      dangerAt = i; break;
    }
    if (this.inColors[i] == 1) {
      enemyAt = i; break;
    }
  }
  if ( dangerAt > -1) {
    this.outMoveAngle = ( dangerAt >26 ) ? ( 35-(dangerAt+9)  ) : ( dangerAt-9 );
    this.outMoveSpeed = this.inMaxSpeed;
    if( this.inDistances[dangerAt]<50 ){
      enemyAt = -1;
      for (i=0; i< this.inColors.length; i++) {
        if (this.inColors[i] == 1) {
          enemyAt = i; break;
        }
      }
      if ( enemyAt > -1){
        this.outMoveSpeed = 0;
        this.outThrowBullet = true;
        this.outThrowAngle = enemyAt;
      }
    }
  }
  else if (enemyAt > -1 && this.inDistances[enemyAt]<250) {
    this.outMoveSpeed = 0;
    this.outThrowBullet = true;
    this.outThrowAngle = enemyAt;
  }
  else{
    this.outThrowBullet = false;
  }
}
else
{
  var bulletAt:int = -1;
  for (i=0; i< this.inColors.length; i++) {
    if (this.inColors[i] == 2) {
      bulletAt = i; break;
    }
  }
  if( bulletAt>-1 ){
    this.outMoveAngle = bulletAt ;
    this.outMoveSpeed = this.inMaxSpeed;
  } 
}

		}
	}
}