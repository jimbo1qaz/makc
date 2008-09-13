package  
{
	import alternativa.engine3d.core.Camera3D;
	import alternativa.types.Point3D;
	import alternativa.types.Texture;
	import alternativa.engine3d.core.PolyPrimitive;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.display.Skin;
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.engine3d.core.Face;
	import com.suite75.quake1.io.BspEntity;
	import flash.geom.ColorTransform;
	import flash.utils.Dictionary;

	import alternativa.engine3d.alternativa3d;
	use namespace alternativa3d;

	/**
	* This class makes it possible to turn off mesh texture without detaching material.
	* @author makc
	*/
	public class QuakeTextureMaterial extends TextureMaterial
	{
		/**
		 * Save lights reference.
		 */
		public function QuakeTextureMaterial (texture:Texture, lights:Array, alpha:Number = 1, repeat:Boolean = true)
		{
			super (texture, alpha, repeat); _lights = lights; _transforms = new Dictionary (true);
		}

		/**
		 * PVS working horse.
		 */
		override alternativa3d function canDraw (param1:PolyPrimitive):Boolean
        {
			return visible && super.canDraw (param1);
        }

		/**
		 * Boolean value to control material visibility.
		 */
		public var visible:Boolean = true;

		/**
		 * Sloppy flat dynamic lighting.
		 */
		override alternativa3d function draw (camera:Camera3D, skin:Skin, vertexCount:uint, vertices:Array):void {
			// draw texture
			super.draw (camera, skin, vertexCount, vertices);

			var face:Face = skin.primitive.face;
			var faceTransform:ColorTransform = _transforms [face];

			if (faceTransform == null) {

				faceTransform = new ColorTransform; _transforms [face] = faceTransform;

				if (_lights.length > 0) {
					// ideally, we should have in _lights only lights affecting this face;
					// instead, we have all map lights there. so, for now we will take only
					// nearest light into account in order to deal with this; this way we
					// may end up with light behind the face, hence Math.abs (dot) below :(

					var faceCenter:Point3D = new Point3D;
					for each(var v:Vertex in face.vertices[0]) faceCenter.add (v.globalCoords);
					faceCenter.multiply (1.0 / face.verticesCount);

					var lightPos:Point3D = new Point3D, lightPosTmp:Point3D = new Point3D, distance:Number = 1e23;
					for each (var light:BspEntity in _lights) {
						lightPosTmp.x = light.origin [0]; lightPosTmp.y = light.origin [1]; lightPosTmp.z = light.origin [2];

						lightPosTmp.subtract (faceCenter);
						var d:Number = lightPosTmp.lengthSqr;
						if (distance > d) {
							distance = d;
							lightPos.x = light.origin [0]; lightPos.y = light.origin [1]; lightPos.z = light.origin [2];
						}
					}

					// abs (Lambert's cosine law) + ambient
					lightPos.subtract (faceCenter);
					lightPos.normalize ();
					var dot:Number = Point3D.dot (lightPos, face.globalNormal);
					var power:Number = 0.5 + 0.5 * Math.abs (dot);

					faceTransform.redMultiplier = faceTransform.greenMultiplier = faceTransform.blueMultiplier = power;
				}
			}

			skin.transform.colorTransform = faceTransform;
		}

		private var _lights:Array;
		private var _transforms:Dictionary;
	}
}