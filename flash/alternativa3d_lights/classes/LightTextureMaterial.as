package  
{
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.display.Skin;
	import alternativa.engine3d.materials.Material;
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.types.Point3D;
	import alternativa.types.Texture;

	import flash.geom.ColorTransform;
	import flash.utils.Dictionary;

	import alternativa.engine3d.alternativa3d;
	use namespace alternativa3d;

	/**
	* Simple dynamic flat lighting for alternativa3d v5.0.4.
	* @author makc
	*/
	public class LightTextureMaterial extends TextureMaterial {
		/**
		 * Constructor to take all TextureMaterial parameters.
		 */
		public function LightTextureMaterial (texture:Texture, alpha:Number = 1, repeat:Boolean = true, smooth:Boolean = false, blendMode:String = "normal", wireThickness:Number = -1, wireColor:uint = 0, precision:Number = 10) {
			super (texture, alpha, repeat, smooth, blendMode, wireThickness, wireColor, precision);

			if (_skins == null) _skins = new Dictionary (true);
		}

		private var _lights:Array;
		private var _transforms:Dictionary;

		/**
		 * Lights array. Lights are static; to animate them, re-set this property.
		 */
		public function get lights ():Array { return _lights; }

		/**
		 * @private setter
		 */
		public function set lights (staticLights:Array):void {
			_lights = staticLights; _transforms = new Dictionary (true);
		}

		public var ambient:Number = 0.2;
		public var diffuse:Number = 0.8;

		/**
		 * Let's do magic!
		 */
		override alternativa3d function draw (camera:Camera3D, skin:Skin, vertexCount:uint, vertices:Array):void {
			// draw texture
			super.draw (camera, skin, vertexCount, vertices);

			if (_lights != null) {
				var face:Face = skin.primitive.face;
				var faceTransform:ColorTransform = _transforms [face];

				if (faceTransform == null) {
					faceTransform = new ColorTransform; _transforms [face] = faceTransform;

					var power:Number = ambient;
					for each (var light:Light3D in _lights) {
						power += diffuse * light.power * Math.max (0, -Point3D.dot (light.direction, face.globalNormal));
					}

					var multiplier:Number = Math.max (0, Math.min (1, power));
					var offset:Number = 0; if (power > 1) offset = 255 * Math.min (1, power -1);

					faceTransform.redMultiplier = faceTransform.greenMultiplier = faceTransform.blueMultiplier = multiplier;
					faceTransform.redOffset     = faceTransform.greenOffset     = faceTransform.blueOffset     = offset;
				}

				skin.transform.colorTransform = faceTransform; _skins [skin] = skin;
			}
		}


		/**
		 * Keep this LightTextureMaterial in cloneMaterialToAllSurfaces(), etc.
		 */
		override public function clone ():Material {
			var mat:LightTextureMaterial = new LightTextureMaterial (texture, alpha, repeat, smooth, blendMode, wireThickness, wireColor, precision);
			mat.lights = lights; return mat;
		}

		private static var _skins:Dictionary;
		private static var _defaultColorTransform:ColorTransform;

		/**
		 * Prepares materials for rendering.
		 * Always call this before calculate() in order for other materials to render corectly.
		 */
		public static function prepare ():void {
			if (_skins != null) {
				if (_defaultColorTransform == null)
					_defaultColorTransform = new ColorTransform;
				for each (var skin:Skin in _skins)
					skin.transform.colorTransform = _defaultColorTransform;
			}
		}

		
		/**
		 * This approximates 1/r^2 falloff but supresses singularity.
		 * pproximate values should be: 10000 at 0, 4000 at 1, 100 at 10, 1 at 100 units, etc.
		 * @param	distance
		 * @return
		 */
		private function _fallOff (r:Number):Number {
			r = Math.max (0.00001, Math.abs (r));
			var f:Number = (1 - Math.exp ( -r)) / r;
			return f * f / 1e-4;
		}
	}
}