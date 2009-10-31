package {
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.system.Security;

	dynamic public class scooby56 extends Sprite {
	    /**
	     * scooby56 bot.
	     * @scooby56
	     * @see http://makc3d.wordpress.com/2009/10/31/ai-battle-again/
	     */
		public function scooby56 () {
			Security.allowDomain ("http://makc.googlecode.com/");
			if (stage != null) {
				var tf:TextField = new TextField;
				tf.autoSize = "left";
				tf.text = stage.loaderInfo.url;
				addChild (tf);
			}
this.objective = 2;
this.danger = false;
		}

private function search ():int {
	var d:scooby56 = this;
	//loop through all angles return direction to items in the following priority
	for (var i:int=0; i< d.inColors.length; i++){
		//1. check theres no danger
		if (d.inColors[i] == 3 && d.inDistances[i] < 100){
			
			//make a desision on direction to evade
			var evadeDirection:Array = new Array();
			evadeDirection[1] = i - 9;
			evadeDirection[2] = i - 18;
			evadeDirection[3] = i + 9;
			
			var bestDirection:int = 0
			for (var j:int=0;j<3;j++){
				if (evadeDirection[j] < 0)
					evadeDirection[j] += 36;
				if (evadeDirection[j] > 36)
					evadeDirection[j] -= 36;
				
				if (d.inDistances[evadeDirection[j]] > bestDirection)
					bestDirection = evadeDirection[j];
			}
			
			//d.trace('retreat bestDirection:' + bestDirection)
			d.danger = true;
			return bestDirection;
		}
		
		d.danger = false;
		
				
		//2. current objective location
		if (d.inColors[i] == d.objective)
			return i;	
			
	}
	// next line was not part of scooby56 script
	return -1;
}

private function changeDirection ():void {
	var d:scooby56 = this;
	var i:int, arrOptions:Array = new Array();
	//look in all 4 directions
	for (i=0;i<37;i+=9){
		//over 100 px = possible option
		if(d.inDistances[i] > 100)
			arrOptions.push(i)		
	}
	
	//if cornered, (ie all options < 100) loop all angles for exit, take most open option
	if(arrOptions.length < 1){
		var intLargest:Number = 0;
		for (i=0;i<37;i++){
			if(d.inDistances[i] > intLargest)
				intLargest = d.inDistances[i]
		}
		arrOptions.push(intLargest)
	};
		
	//pick one direction from available at random
	var rand:int = Math.floor(Math.random() * 2)
	d.outMoveAngle = arrOptions[rand]
	d.outMoveSpeed = d.inMaxSpeed;
}


		public function behavior ():void {

this.outThrowBullet = false;

//set away if not moving
if(!this.outMoveSpeed || this.outMoveAngle == undefined || this.inDistances[this.outMoveAngle] == undefined){
	this.changeDirection();	
};

//set objective
this.objective = (this.inHasBullet) ? 1: 2;
//this.trace("objective: " + this.objective)

//look for objects
var dir:int = this.search();
if (dir > -1){
	//this.trace("dir @ " + dir)
	this.outMoveSpeed = this.inMaxSpeed;
	this.outMoveAngle = dir;
	if(this.objective == 1){
		if(!this.danger){
			if(this.inHasBullet){
				if(this.inDistances[dir] < 120){
					//this.trace("firing at " + dir + " danger: " + this.danger)
					this.outThrowAngle = dir;
					this.outThrowBullet = true;
					this.objective = 2;
				}
			};
		};
	};
	
} else {
	//if heading towards a wall
	if(this.inColors[this.outMoveAngle] == 0 ){		
		if(this.inDistances[this.outMoveAngle] < 50){			
			this.changeDirection();	
			//this.trace("angle: " + this.outMoveAngle + " distance: " + this.inDistances[this.outMoveAngle])
			
		}		 	
	}
}

		}
	}
}