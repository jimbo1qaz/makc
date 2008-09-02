package  
{
	import alternativa.types.Texture;
	import alternativa.engine3d.core.Camera3D;
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
        override alternativa3d function draw (param1:Camera3D, param2:Skin, param3:uint, param4:Array):void
        {
			if (visible) super.draw (param1, param2, param3, param4);
		}

		/**
		 * Boolean value to control material visibility.
		 */
		public var visible:Boolean = true;
	}
}