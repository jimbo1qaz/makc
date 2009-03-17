package {
	
	import sandy.core.*
	import sandy.core.scenegraph.*
	import sandy.materials.*
	import sandy.materials.attributes.*
	import sandy.primitive.*
	
	public class SandyCube extends SandyARApp {
		
		private var _plane:Plane3D;
		private var _cube:Box;
		
		public function SandyCube() {
			this.init('Data/camera_para.dat', 'Data/flarlogo.pat');
		}
		
		protected override function onInit():void {
			super.onInit();

			var attr:MaterialAttributes = new MaterialAttributes (new LightAttributes);
			var mat1:ColorMaterial = new ColorMaterial (0xFFFF00, 0.5, attr); mat1.lightingEnable = true;
			var mat2:ColorMaterial = new ColorMaterial (0x00FFFF, 1.0, attr); mat2.lightingEnable = true;
			
			this._plane = new Plane3D("plane", 80, 80); // 80mm x 80mm。
			this._plane.rotateX = 180;
			this._baseNode.addChild(this._plane);
			this._plane.appearance = new Appearance (mat1);

			this._cube = new Box("cube", 40, 40, 40); // 40mm x 40mm x 40mm。
			this._cube.z = 20;
			this._baseNode.addChild(this._cube);
			this._cube.appearance = new Appearance (mat2);
		}
	}
}