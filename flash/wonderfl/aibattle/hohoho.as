// forked from makc3d's Basic bot
package {
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.system.Security;

	dynamic public class hohoho extends Sprite {
	    /**
	     * hohoho bot.
	     * @author hohoho
	     * @see http://makc3d.wordpress.com/2009/10/31/ai-battle-again/
	     */
		public function hohoho () {
			Security.allowDomain ("http://makc.googlecode.com/");
			if (stage != null) {
				var tf:TextField = new TextField;
				tf.autoSize = "left";
				tf.text = stage.loaderInfo.url;
				addChild (tf);
			}
this.dodging=false;
		}

		public function behavior ():void {
var lookang:int, theta:int, bestangle:int;

this.outMoveSpeed = this.inMaxSpeed;
this.outThrowBullet = false;

// Find a bullet
var closestbullet:Number = 1000;
if(!this.inHasBullet){
for(lookang=0;lookang<36;lookang++){
if (this.inColors[lookang] == 2){
if(this.inDistances[lookang] < closestbullet){
bestangle = lookang;
closestbullet = this.inDistances[lookang];
}
}
}
}
// Find open spaces
var maxdist:Number = 0;
if (closestbullet == 1000){
for(theta=-8;theta<=8;theta++){
lookang = this.outMoveAngle + theta;
if (lookang > 35) lookang = lookang - 36;
if (lookang < 0) lookang = 36 + lookang;
if ((this.inDistances[lookang] > maxdist) && (this.inColors[lookang] == 0)){
maxdist = this.inDistances[lookang];
if(theta>1)
bestangle = this.outMoveAngle + 2;
else if(theta<-1)
bestangle = this.outMoveAngle - 2;
else bestangle = lookang; 
}
if(maxdist < 15){
bestangle = bestangle - 18;
}
}
//Randomize when it's aimless.
if(Math.random() < 0.4){ 
bestangle = bestangle + 1
}
if(bestangle < 0) bestangle = bestangle + 36;
if(bestangle > 35) bestangle = bestangle - 36;

}


// Find enemy
var foundenemy:Boolean = false;
if (this.inHasBullet){
for(lookang=0;lookang<36;lookang++){
if (this.inColors[lookang] == 1){
bestangle = lookang;
this.outThrowAngle = lookang;
foundenemy = true;
}
}
}

// Dodge bullets
if((this.dodging==false) && this.inMaxSpeed >= 3){
for(lookang=0; lookang<36; lookang++){
if(this.inColors[lookang] == 3){
this.dodging = true;
theta = lookang + 11;
if (theta > 35) theta = theta - 36;
maxdist = this.inDistances[theta];
bestangle = lookang - 11;
if (bestangle < 0) bestangle = bestangle + 36;
if(this.inDistances[bestangle] < maxdist) bestangle = theta;
this.outMoveAngle = bestangle;
}
}
}

// Finish dodging bullets
if(this.inMaxSpeed >= 3){
this.dodging = false;
for(lookang=0; lookang<36; lookang++){
if(this.inColors[lookang] == 3)
this.dodging = true;
}
}
else this.dodging = false;
if (!this.dodging) this.outMoveAngle = bestangle;
if (foundenemy && (this.inDistances[this.outMoveAngle] < 80)) this.outThrowBullet = true;


		}
	}
}