package  
{
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.GraphicsBitmapFill;
	import flash.display.GraphicsSolidFill;
	import flash.display.GraphicsStroke;
	import flash.display.GraphicsTrianglePath;
	import flash.display.IGraphicsData;
	import flash.display.StageAlign;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	import flash.display.TriangleCulling;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix3D;
	import flash.geom.PerspectiveProjection;
	import flash.geom.Vector3D;
	import flash.geom.Utils3D;
	
	/**
	 * ASE demo document class.
	 * 
	 * @author senocular (Flash CS4 spinning globe example)
	 * @author makc (changed to ASE parser demo)
	 */
	public class Shuttle extends Sprite
	{
		private var shuttle:Shape;
		private var shuttleTransform:Matrix3D = new Matrix3D();
		private var shuttlePerspective:Matrix3D = (new PerspectiveProjection()).toMatrix3D();

		// a GraphicsTrianglePath for the path
		// data to be drawn in Flash
		private var triangles:GraphicsTrianglePath	= new GraphicsTrianglePath(
				new Vector.<Number>(), new Vector.<int>(),
				new Vector.<Number>(), TriangleCulling.NEGATIVE);

		// a vector of Number objects to store
		// 3D locations of shuttle coordinates
		private var vertices3D:Vector.<Number>;

		// to be non-destructive, changes to the sphere
		// coordinates are added to this vector
		private var vertices3DTransformed:Vector.<Number> = new Vector.<Number>();

		private var shuttleData:Vector.<IGraphicsData>;
		private var stroke:GraphicsStroke;

		[Embed(source='shuttle.jpg')]
		private var Texture:Class;

		[Embed(source='shuttle.ase', mimeType='application/octet-stream')]
		private var Model:Class;

		public function Shuttle () 
		{
			stage.align = StageAlign.TOP; stage.scaleMode = StageScaleMode.NO_SCALE; stage.quality = StageQuality.BEST;

			// create shuttle shape
			shuttle = new Shape();
			shuttle.x = 800/2;
			shuttle.y = 600/2;
			addChild(shuttle);

			// push back in 3D space
			shuttleTransform.appendTranslation(0, 0, -100); 

			// stroke for when mouse is pressed
			// start with a NaN width (no stroke)
			stroke = new GraphicsStroke(NaN, false, "normal", "none", "round", 3,
					new GraphicsSolidFill(0xFF0000));

			// populate triangles and vertices3D and with parsed ASE data
			var aseParser:EmbeddedASEParser = new EmbeddedASEParser (new Model);
			triangles = aseParser.triangles;
			vertices3D = aseParser.vertices3D;

			// IGraphicsData list of drawing commands
			shuttleData = Vector.<IGraphicsData>([
				stroke, new GraphicsBitmapFill(Bitmap (new Texture).bitmapData, null, false, true), triangles
			]);

			// rotate shuttle in frame loop
			addEventListener(Event.ENTER_FRAME, draw);

			// show outlines when pressing the mouse
			stage.addEventListener(MouseEvent.MOUSE_DOWN, toggleStroke);
			stage.addEventListener(MouseEvent.MOUSE_UP, toggleStroke);
		}


		private function draw(event:Event):void
		{
			// rotate the shuttle transform based on mouse position
			shuttleTransform.prependRotation(0.01 * (mouseX - 800/2), Vector3D.X_AXIS);
			shuttleTransform.prependRotation(0.01 * (mouseY - 600/2), Vector3D.Y_AXIS);

			// apply the transform to the shuttle vertices
			// to make the shuttle points actually rotated
			// (as well as pushed back in z)
			shuttleTransform.transformVectors(vertices3D, // in
											vertices3DTransformed); // out
			// convert the 3D points to 2D points and update
			// the T data in the UVT to coorectly account for
			// the translation of 2D to 3D for the bitmaps
			Utils3D.projectVectors(shuttlePerspective, vertices3DTransformed, // in
								   triangles.vertices, triangles.uvtData); // out

			// draw the triangles
			shuttle.graphics.clear();
			shuttle.graphics.drawGraphicsData(shuttleData);
		}

		private function toggleStroke(event:MouseEvent):void {
			stroke.thickness = (event.type == MouseEvent.MOUSE_DOWN) ? 1 : NaN;
		}

	}

}