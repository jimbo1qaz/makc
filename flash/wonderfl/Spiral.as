// http://wonderfl.kayac.com/code/27767f8a59a3ca518570f9a0cc0e9574d1a38b84
package {
    import flash.display.*;
    import flash.geom.*;
    import flash.filters.*;

    // Yet another AS2-to-AS3 port from '07

    [SWF(backgroundColor="#000000", frameRate="20")]
    public class Spiral extends Sprite {


        private const H:Number = 465, W:Number = 465;
        private const SY:Number = 2.0001 / H, SX:Number = 2.0001 / W, DY:Number = -15, DX:Number = DY;
        private const FadeOut:ColorTransform = new ColorTransform(1, 1, 1, 1, -1, -6, -9, 0);
        private const MixPixels:BlurFilter = new BlurFilter(2, 2, 2);
        private const CopyMatrix:Matrix = new Matrix (1, 0, 0, 1, 0, 0);
        private const CopyRatios:ColorTransform = new ColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
        private const Origin:Point = new Point (0, 0);
        private const ScaleMatrix:Matrix = new Matrix(1 - SX * DX, 0, 0, 1 - SY * DY, DX, DY);

        private function spiral (a:Number, t:Number):Number {
            var f:Number = 0.5 * (1 + Math.sqrt (5));
            var c:Number = Math.pow (f, 2 / Math.PI);

            return a * Math.pow (c, t);
        }

        private var zz:Number = 0;
        private var b1:BitmapData = new BitmapData (W, H, true, 0);
        private var b2:BitmapData = new BitmapData (W, H, true, 0);

        public function Spiral () {
            addChild (new Bitmap (b1));
            addEventListener ("enterFrame", onEnterFrame);
        }

        private function onEnterFrame (e:*):void {
            zz += 0.1;
            if (zz > 2 * Math.PI)
                zz -= 2 * Math.PI;

            graphics.clear ();
            for (var t:Number = -8; t < 20; t += 0.1) {
                var c:int = 100 + Math.floor(155 * Math.random ());
                var r:Number = spiral (1, t + 2 * Math.PI - zz);
                // and now some color voodoo
                c = Math.floor (c * (100 - r) * 0.01); if (r > 100) c = 0;
                var xx:Number = stage.stageWidth/2  + r * Math.sin (t);
                var yy:Number = stage.stageHeight/2 + r * Math.cos (t);
                if (t == -8) {
                    graphics.moveTo (xx, yy);
                }
                graphics.lineStyle (3, c + (c + c * 256) * 256);
                graphics.lineTo (xx, yy);
            }

            // here goes my flamy crap again
            b1.draw(this, CopyMatrix, CopyRatios, "normal", b1.rect);
            b2.applyFilter(b1, b1.rect, Origin, MixPixels);
            b1.draw(b2, ScaleMatrix, FadeOut, "normal", b1.rect);
        }
    }
}