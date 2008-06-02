package sandy.primitive
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	import sandy.core.data.*;
	import sandy.core.scenegraph.Geometry3D;
	import sandy.core.scenegraph.Shape3D;
	import sandy.primitive.Primitive3D;

	/**
	* MD2 primitive.
	* 
	* @author Philippe Ajoux (philippe.ajoux@gmail.com)
	*/
	public class MD2 extends Shape3D implements Primitive3D
	{
		/**
		* Creates MD2 primitive.
		*/
		public function MD2 ( p_sName:String, data:ByteArray )
		{
			super (p_sName); geometry = generate (data); frame = 0;
		}

		/**
		* Generates the geometry for MD2. Sandy never actually calls this method,
		* but we still implement it according to Primitive3D, just in case :)
		*
		* @return The geometry object.
		*/
		public function generate (... arguments):Geometry3D
		{
			var i:int, j:int;
			var uvs:Array = [];
			var mesh:Geometry3D = new Geometry3D ();

			// okay, let's read out header 1st
			var data:ByteArray = ByteArray (arguments [0]);
			data.endian = Endian.LITTLE_ENDIAN;

			ident = data.readInt();
			version = data.readInt();

			if (ident != 844121161 || version != 8)
				throw new Error("Error loading MD2 file: Not a valid MD2 file/bad version");

			skinwidth = data.readInt();
			skinheight = data.readInt();
			framesize = data.readInt();
			num_skins = data.readInt();
			num_vertices = data.readInt();
			num_st = data.readInt();
			num_tris = data.readInt();
			num_glcmds = data.readInt();
			num_frames = data.readInt();
			offset_skins = data.readInt();
			offset_st = data.readInt();
			offset_tris = data.readInt();
			offset_frames = data.readInt();
			offset_glcmds = data.readInt();
			offset_end = data.readInt();

			// UV coordinates
			data.position = offset_st;
			for (i = 0; i < num_st; i++)
				uvs.push (new UVCoord (data.readShort() / skinwidth, 1 - ( data.readShort() / skinheight) ));

			// Faces
			data.position = offset_tris;
			for (i = 0; i < num_tris; i++)
			{
				var a:int = data.readUnsignedShort();
				var b:int = data.readUnsignedShort();
				var c:int = data.readUnsignedShort();
				var ta:int = data.readUnsignedShort();
				var tb:int = data.readUnsignedShort();
				var tc:int = data.readUnsignedShort();
trace ("face " + i)
trace (" vetex " + a + " uv " + ta + ": " + uvs [ta].u + ", " + uvs [ta].v)
trace (" vetex " + b + " uv " + tb + ": " + uvs [tb].u + ", " + uvs [tb].v)
trace (" vetex " + c + " uv " + tc + ": " + uvs [tc].u + ", " + uvs [tc].v)

				// create placeholder vertices (actual coordinates are set later)
				mesh.setVertex (a, 1, 0, 0);
				mesh.setVertex (b, 0, 1, 0);
				mesh.setVertex (c, 0, 0, 1);

				mesh.setUVCoords (a, uvs [ta].u, uvs [ta].v);
				mesh.setUVCoords (b, uvs [tb].u, uvs [tb].v);
				mesh.setUVCoords (c, uvs [tc].u, uvs [tc].v);

				mesh.setFaceVertexIds (i, a, b, c);
				mesh.setFaceUVCoordsIds (i, a, b, c);
			}

			// Frame animation data
			for (i = 0; i < num_frames; i++)
			{
				var sx:Number = data.readFloat();
				var sy:Number = data.readFloat();
				var sz:Number = data.readFloat();
				
				var tx:Number = data.readFloat();
				var ty:Number = data.readFloat();
				var tz:Number = data.readFloat();

				// store frame names as pointers to frame numbers
				var name:String = "", wasNotZero:Boolean = true;
				for (j = 0; j < 16; j++)
				{
					var char:int = data.readUnsignedByte ();
					wasNotZero &&= (char != 0);
					if (wasNotZero)
						name += String.fromCharCode (char);
				}
				frames [name] = i;

				// store vertices for every frame
				var vi:Array = [];
				vertices [i] = vi;
				for (j = 0; j < num_vertices; j++)
				{
					var v:Vector = new Vector ();

					// order of assignment is important here because of data reads...
					v.x = ((sx * data.readUnsignedByte()) + tx) * scaling;
					v.z = ((sy * data.readUnsignedByte()) + ty) * scaling;
					v.y = ((sz * data.readUnsignedByte()) + tz) * scaling;

					vi [j] = v;

					// ignore "vertex normal index"
					data.readUnsignedByte ();
				}
			}
trace ("check:");
for (i=0; i<mesh.aFacesVertexID.length; i++){
trace ("face " + i);
for (j = 0; j< 3; j++) {
var _a = mesh.aFacesVertexID[i][j];
var _ta = mesh.aFacesUVCoordsID[i][j]; // this should not coincide, it is == _a
trace (" vetex " + _a + " uv " + _ta + ": " + mesh.aUVCoords [_ta].u + ", " + mesh.aUVCoords [_ta].v)
}
}


			return mesh;
		}

		/**
		* Frames map. This maps frame names to frame numbers.
		*/
		public var frames:Array = [];

		/**
		* Frame number. You can tween this value to play MD2 animation.
		*/
		public function get frame ():Number { return t; }

		/**
		* @private (setter)
		*/
		public function set frame (value:Number):void
		{
			t = value;

			// interpolation frames
			var f1:Array = vertices [int (t) % num_frames];
			var f2:Array = vertices [(int (t) + 1) % num_frames];

			// interpolation coef-s
			var c2:Number = t - int (t), c1:Number = 1 - c2;

			// loop through vertices
			for (var i:int = 0; i < num_vertices; i++)
			{
				var v0:Vertex = Vertex (geometry.aVertex [i]);
				var v1:Vector = Vector (f1 [i]);
				var v2:Vector = Vector (f2 [i]);

				// interpolate
				v0.x = v1.x * c1 + v2.x * c2;
				v0.y = v1.y * c1 + v2.y * c2;
				v0.z = v1.z * c1 + v2.z * c2;
			}

			// update internal stuff - do we need this ?
			geometry.aFacesNormals.length = 0;
			geometry.generateFaceNormals ();
		}

		// animation "time" (frame number)
		private var t:Number;		

		// vertices list for every frame
		private var vertices:Array = [];

		// original Philippe vars
		private var ident:int;
		private var version:int;
		private var skinwidth:int;
		private var skinheight:int;
		private var framesize:int;
		private var num_skins:int;
		private var num_vertices:int;
		private var num_st:int;
		private var num_tris:int;
		private var num_glcmds:int;
		private var num_frames:int;
		private var offset_skins:int;
		private var offset_st:int;
		private var offset_tris:int;
		private var offset_frames:int;
		private var offset_glcmds:int;
		private var offset_end:int;
		private var scaling:Number = 2;

	}
}