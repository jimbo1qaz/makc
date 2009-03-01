// http://wonderfl.kayac.com/code/00cbe3ecbf0db2e865bc410a8ea54677c19ba4c6
package {
    import flash.display.Sprite;
    public class RandomGreenTreeSF extends Sprite {
        private var level:int = 0;

        // just some random tree :)
        private function drawTree (x:Number, y:Number, length:Number, angle:Number, cf:int):void {
            level += 1;

            var destx:Number = x + length * Math.cos(angle * (Math.PI/180));
            var desty:Number = y + length * Math.sin(angle * (Math.PI/180));

            // for the most of time, we use green,
            // but sometimes pink to make flowers
            if ((level == 10) && (Math.random () < 0.5)) cf = 0xF0007;

            graphics.lineStyle(1 + 5 / level, cf * level);
            graphics.moveTo (x, y);
            graphics.lineTo (destx, desty);

            if (level < 10) {
                drawTree (destx, desty, length * (1 + 3 * Math.random()) * 0.25,
                    angle + 60 * (Math.random() - Math.random()), cf);
                drawTree (destx, desty, length * (1 + 3 * Math.random()) * 0.25,
                    angle + 60 * (Math.random() - Math.random()), cf);
                drawTree (destx, desty, length * (1 + 3 * Math.random()) * 0.25,
                    angle + 60 * (Math.random() - Math.random()), cf);
            }

            level -= 1;
        }

        public function RandomGreenTreeSF() {
            drawTree (stage.stageWidth/2, stage.stageHeight, 90, -90, 0xF00);
        }
    }
}