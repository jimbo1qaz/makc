package  
{
	import alternativa.types.Texture;
	import alternativa.engine3d.core.PolyPrimitive;
	import alternativa.engine3d.display.Skin;
	import alternativa.engine3d.materials.TextureMaterial;

	import alternativa.engine3d.alternativa3d;
	use namespace alternativa3d;

	/**
	* This class makes it possible to turn off mesh texture without detaching material.
	* @author makc
	*/
	public class QuakeTextureMaterial extends TextureMaterial
	{
		/**
		 * Just call papa here...
		 */
		public function QuakeTextureMaterial (texture:Texture, alpha:Number = 1, repeat:Boolean = true)
		{
			super (texture, alpha, repeat);
		}

		/**
		 * That's where magic happens...
		 */
		override alternativa3d function canDraw (param1:PolyPrimitive):Boolean
		{
			return _visible && super.canDraw (param1);
		}

		private var _visible:Boolean = true;

		/**
		 * Boolean value to control material visibility.
		 */
		public function get visible ():Boolean { return _visible; }
		public function set visible (v:Boolean):void {
			_visible = v;
			if (_surface != null) {
				_surface.addMaterialChangedOperationToScene ();
			}
		}
	}
}