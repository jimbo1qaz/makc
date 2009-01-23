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
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix3D;
	import flash.geom.PerspectiveProjection;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.geom.Utils3D;
	import flash.text.TextField;
	
	/**
	 * ASE demo document class.
	 * Same as shuttle but with simple z-sorting.
	 * 
	 * @author senocular (Flash CS4 spinning globe example)
	 * @author makc (changed to ASE parser demo)
	 */
	public class Barge extends Sprite
	{
		private var barge:Shape;
		private var bargeTransform:Matrix3D = new Matrix3D();
		private var bargePerspective:Matrix3D = (new PerspectiveProjection()).toMatrix3D();

		// a GraphicsTrianglePath for the path
		// data to be drawn in Flash
		private var triangles:GraphicsTrianglePath	= new GraphicsTrianglePath(
				new Vector.<Number>(), new Vector.<int>(),
				new Vector.<Number>(), TriangleCulling.NEGATIVE);

		// a vector of Number objects to store
		// 3D locations of barge coordinates
		private var vertices3D:Vector.<Number>;

		// to be non-destructive, changes to the model
		// coordinates are added to this vector
		private var vertices3DTransformed:Vector.<Number> = new Vector.<Number>();

		private var bargeData:Vector.<IGraphicsData>;
		private var stroke:GraphicsStroke;

		[Embed(source='barge.jpg')]
		private var Texture:Class;

		[Embed(source='barge.ase', mimeType='application/octet-stream')]
		private var Model:Class;

		// sorting vars
		private var zsortOn:Boolean = true;
		private var zsortText:TextField = new TextField;
		private var faces:Vector.<Point> = new Vector.<Point>();
		private var sortedIndices:Vector.<int> = new Vector.<int>();

		public function Barge () 
		{
			stage.align = StageAlign.TOP; stage.scaleMode = StageScaleMode.NO_SCALE; stage.quality = StageQuality.BEST;

			// create barge shape
			barge = new Shape();
			barge.x = 800/2;
			barge.y = 600/2;
			addChild(barge);

			// push back in 3D space
			bargeTransform.appendTranslation(0, 0, -300); 

			// stroke for when mouse is pressed
			// start with a NaN width (no stroke)
			stroke = new GraphicsStroke(NaN, false, "normal", "none", "round", 3,
					new GraphicsSolidFill(0xFF0000));

			// populate triangles and vertices3D and with parsed ASE data
			var aseParser:EmbeddedASEParser = new EmbeddedASEParser (new Model);
			triangles = aseParser.triangles;
			vertices3D = aseParser.vertices3D;

			// IGraphicsData list of drawing commands
			bargeData = Vector.<IGraphicsData>([
				stroke, new GraphicsBitmapFill(Bitmap (new Texture).bitmapData, null, false, true), triangles
			]);

			// rotate barge in frame loop
			addEventListener(Event.ENTER_FRAME, draw);

			// show outlines when pressing the mouse
			stage.addEventListener(MouseEvent.MOUSE_DOWN, toggleStroke);
			stage.addEventListener(MouseEvent.MOUSE_UP, toggleStroke);

			// turn sorting on/of
			stage.addEventListener(KeyboardEvent.KEY_UP, toggleSorting);
			addChild (zsortText); toggleSorting (null);
		}


		private function draw(event:Event):void
		{
			// rotate the barge transform based on mouse position
			bargeTransform.prependRotation(0.01 * (mouseX - 800/2), Vector3D.X_AXIS);
			bargeTransform.prependRotation(0.01 * (mouseY - 600/2), Vector3D.Y_AXIS);

			// apply the transform to the barge vertices
			// to make the barge points actually rotated
			// (as well as pushed back in z)
			bargeTransform.transformVectors(vertices3D, // in
											vertices3DTransformed); // out
			// convert the 3D points to 2D points and update
			// the T data in the UVT to coorectly account for
			// the translation of 2D to 3D for the bitmaps
			Utils3D.projectVectors(bargePerspective, vertices3DTransformed, // in
								   triangles.vertices, triangles.uvtData); // out

			// z-sort triangles
			if (zsortOn) {
				var i:int;
				for (i = 0; i < triangles.indices.length / 3; i++) {
					var p:Point;
					if (i == faces.length) { p = new Point; faces [i] = p; } else p = faces [i];

					var depth:Number = vertices3DTransformed [3 * triangles.indices [3 * i] + 2];
					depth += vertices3DTransformed [3 * triangles.indices [3 * i + 1] + 2];
					depth += vertices3DTransformed [3 * triangles.indices [3 * i + 2] + 2];

					p.x = i; p.y = depth;
				}

				faces = faces.sort (zsort);
				for (i = 0; i < faces.length; i++) {
					sortedIndices [3 * i] = triangles.indices [3 * faces [i].x];
					sortedIndices [3 * i + 1] = triangles.indices [3 * faces [i].x + 1];
					sortedIndices [3 * i + 2] = triangles.indices [3 * faces [i].x + 2];
				}

				for (i = 0; i < triangles.indices.length; i++) {
					triangles.indices [i] = sortedIndices [i];
				}
			}

			// draw the triangles
			barge.graphics.clear();
			barge.graphics.drawGraphicsData(bargeData);
		}

		private function zsort (a:Point, b:Point):Number {
			if (a.y > b.y) return +1; else if (a.y < b.y) return -1; return 0;
		}

		private function toggleStroke(event:MouseEvent):void {
			stroke.thickness = (event.type == MouseEvent.MOUSE_DOWN) ? 1 : NaN;
		}

		private function toggleSorting(event:KeyboardEvent):void {
			zsortOn = !zsortOn; zsortText.text = "z-sorting " + (zsortOn ? "on" : "off") + "\n(any key to toggle)";
		}
	}

}