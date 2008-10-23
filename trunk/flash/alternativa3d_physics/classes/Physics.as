package {
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Mesh;
	import alternativa.engine3d.core.Scene3D;
	import alternativa.engine3d.core.Surface;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.display.View;
	import alternativa.engine3d.primitives.GeoPlane;
	import alternativa.types.Point3D;
	import alternativa.types.Set;
	import alternativa.types.Texture;
	import alternativa.utils.FPS;
	import alternativa.utils.MathUtils;

	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.BlendMode;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display.StageQuality;
	import flash.events.Event;
	import flash.events.MouseEvent;

	[SWF(backgroundColor="#000000", frameRate="100")]

	public class Physics extends Sprite
	{
		[Embed(source="alternativa3d_medium.png")]
		private var _Logo:Class;
		
		private var scene:Scene3D;
		private var view:View;
		private var camera:Camera3D;

		private var ground:GeoPlane;
		private var groundSize:Number = 200;

		private var ball:Ball, ballSprite:Mesh;

		public function Physics() {
			stage.quality = StageQuality.LOW;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			scene = new Scene3D; scene.root = new Object3D;
			camera = new Camera3D; camera.coords = new Point3D (100, -100, 100); scene.root.addChild (camera);
			view = new View; view.camera = camera; addChild (view);

			var grass:BitmapData = new BitmapData (100, 100); grass.noise (123, 0, 255, BitmapDataChannel.GREEN);
			var material:LightTextureMaterial = new LightTextureMaterial (new Texture (grass), 1, true, false, BlendMode.NORMAL, 1, 0x9FFF00);
			var light:Light3D = new Light3D; light.direction = new Point3D (1, 1, 0); material.lights = [ light ];

			ground = new GeoPlane (groundSize, groundSize, 10, 10);
			var vertices:Array = ground.vertices.toArray (true);
			for (var i:int = 0; i < vertices.length; i++) Vertex (vertices [i]).z += Math.random () * groundSize * 0.06;
			ground.cloneMaterialToAllSurfaces (material);
			scene.root.addChild(ground);

			ball = new Ball (scene); ball.acceleration.z = -0.1;

			ballSprite = SpriteMaterial.make (ball.shape);

			// exclude "sprite" mesh from collision checks
			var excludeSet:Set = new Set; excludeSet.add (ballSprite); ball.excludeSet = excludeSet;

			resetBall (); scene.root.addChild (ballSprite);

			FPS.init(stage);

			stage.addEventListener(Event.RESIZE, onResize); onResize(null);
			stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			stage.addEventListener(MouseEvent.CLICK, onClick);

			// do what license says
			addChild (new _Logo);
		}
		
		private function onResize(e:Event):void {
			view.width = stage.stageWidth;
			view.height = stage.stageHeight;
		}

		private var _angle:Number = 0;
		private function onEnterFrame(e:Event):void {

			// move camera, calculate scene, etc
			var targetAngle:Number = 2 * Math.PI * mouseX / view.width;
			
			if (Math.abs (_angle - targetAngle) > 0.1)
			{
				// move camera only if we really have to;
				// but when we move it, do it as smooth as we can

				_angle = _angle * 0.6 + (2 * Math.PI * mouseX / view.width) * 0.4;

				var camCoords:Point3D = camera.coords;
				camCoords.x = 150 * Math.sin (_angle);
				camCoords.y = 150 * Math.cos (_angle);

				camera.coords = camCoords; lookAt(ground.coords);
			}
			
			SpriteMaterial.prepare (); scene.calculate ();

			// move the ball
			ball.step (); ballSprite.coords = ball.position;

			// reset the ball, if it's in abyss
			if (ball.position.z < -100) resetBall ();
		}

		private function resetBall ():void {
			// random position
			ball.position = new Point3D (
				groundSize * (Math.random () - 0.5),
				groundSize * (Math.random () - 0.5),
				150
			);

			// zero speed
			ball.velocity = new Point3D;

			// random radius
			ball.radius = 5 + 25 * Math.random ();
		}

		private function onClick (event:MouseEvent):void {
			resetBall ();
		}

		private function lookAt (pt:Point3D):void {
			var dx:Number = pt.x - camera.x;
			var dy:Number = pt.y - camera.y;
			var dz:Number = pt.z - camera.z;
			camera.rotationZ = -Math.atan2(dx, dy);
			camera.rotationX = Math.atan2(dz, Math.sqrt(dx * dx + dy * dy)) - MathUtils.DEG90;
		}
	}
}