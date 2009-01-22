package  
{
	import flash.display.GraphicsTrianglePath;
	import flash.display.TriangleCulling;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	import flash.utils.unescapeMultiByte;
	
	/**
	* Parses single ASE mesh from ByteArray.
	* @author makc
	*/
	public class EmbeddedASEParser
	{
		// these vars is what senocular code needs
		
		public var vertices3D:Vector.<Number> = new Vector.<Number>();
		public var triangles:GraphicsTrianglePath	= new GraphicsTrianglePath(
			new Vector.<Number>(), new Vector.<int>(),
			new Vector.<Number>(), TriangleCulling.NEGATIVE);

		// these functions mimic classic engines 3D object

		private var vertexCoords:Array = [];
		private function createVertex (x:Number, y:Number, z:Number, id:String):void {
			vertexCoords [id] = [x, y, z];
		}

		private var uvs:Array = [];
		private function createUV (u:Number, v:Number, id:String):void {
			uvs [id] = [u, v];
		}

		private var faceVertices:Array = [];
		private function setFaceVertices (vertices:Array, id:String):void {
			faceVertices [id] = vertices;
		}

		private var faceUVs:Array = [];
		private function setFaceUVs (uvs:Array, id:String):void {
			faceUVs [id] = uvs;
		}

		private var faces:Array = [];
		private function registerFace (id:String):void {
			faces.push (id);
		}

		private function makeAllFaces ():void {
			var n:int = -1;
			for each (var id:String in faces) {
				for (var i:int = 0; i < Math.min (faceVertices [id].length, faceUVs [id].length); i++) {
					var vertex:Array = vertexCoords [faceVertices [id][i]];
					vertices3D.push (vertex [0], vertex [1], vertex [2]); n++;

					var uv:Array = uvs [faceUVs [id][i]];
					triangles.uvtData.push (uv [0], uv [1], 1);
				}
				triangles.indices.push (n-2, n-1, n);
			}
		}

		// parser

		public function EmbeddedASEParser (ba:ByteArray) 
		{
			var lines:Array = unescapeMultiByte (ba.toString ()).split ('\n');
			while (lines.length > 0) {
				var parsed:Array = String (lines.shift ()).split (/^\s*\*MESH_([^\s]+)\s*([^\s].*)\s+$/);
				if (parsed.length == 4) {
					switch (parsed [1]) {
						case "VERTEX":
							// *MESH_VERTEX 0	16.7500	20.0000	-19.2500
							var vertexData:Array = String (parsed [2]).split (/\s+/);
							createVertex (parseFloat (vertexData [1]), parseFloat (vertexData [2]), parseFloat (vertexData [3]),
								vertexData [0]);
						break;
						case "FACE":
							// *MESH_FACE 0:    A: 0 B: 1 C: 2 AB:    1 BC:    1 CA:    1	 *MESH_SMOOTHING 	*MESH_MTLID 0
							var faceData:Array = String (parsed [2]).split (/(\d+)[^\d]+(\d+)[^\d]+(\d+)[^\d]+(\d+)[^\d].*MTLID\s+(\d+)/);
							registerFace (faceData [1]);
							setFaceVertices ([faceData [2], faceData [3], faceData [4]], faceData [1]);
						break;
						case "TVERT":
							// *MESH_TVERT 1	0.9584	0.6362	0.0000
							var uvsData:Array = String (parsed [2]).split (/\s+/);
							createUV (parseFloat (uvsData [1]), parseFloat (uvsData [2]), uvsData [0]);
						break;
						case "TFACE":
							// *MESH_TFACE 68	5	43	20
							var uvsMapData:Array = String (parsed [2]).split (/\s+/);
							setFaceUVs ([uvsMapData [1], uvsMapData [2], uvsMapData [3]], uvsMapData [0]);
						break;
					}
				}
			}
	
			makeAllFaces ();
		}
	}
}