package  
{
	import alternativa.engine3d.core.Mesh;
	import alternativa.engine3d.core.Vertex;
	import alternativa.engine3d.materials.FillMaterial;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	import flash.utils.unescapeMultiByte;
	
	/**
	* Parses single ASE mesh from ByteArray.
	* @author makc
	*/
	public class EmbeddedASEParser extends Mesh
	{
		
		public function EmbeddedASEParser (ba:ByteArray) 
		{
			var uvs:Array = [];
			var polysInSurfaces:Array = [];

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
							createFace ([faceData [2], faceData [3], faceData [4]], faceData [1]);
							// sort to surfaces by material id
							if (polysInSurfaces [faceData [5]] == null) polysInSurfaces [faceData [5]] = [];
							polysInSurfaces [faceData [5]].push (faceData [1]);
						break;
						case "TVERT":
							// *MESH_TVERT 1	0.9584	0.6362	0.0000
							var uvsData:Array = String (parsed [2]).split (/\s+/);
							uvs [uvsData [0]] = new Point (parseFloat (uvsData [1]), parseFloat (uvsData [2]));
						break;
						case "TFACE":
							// *MESH_TFACE 68	5	43	20
							var uvsMapData:Array = String (parsed [2]).split (/\s+/);
							setUVsToFace (uvs [uvsMapData [1]], uvs [uvsMapData [2]], uvs [uvsMapData [3]], uvsMapData [0]);
						break;
					}
				}
			}
	
			// make some surfaces
			for each (var faces:Array in polysInSurfaces) {
				var n:String = "s" + Math.random ();
				createSurface (faces, n);
				setMaterialToSurface(new FillMaterial (0xFFFFFF * Math.random (), 1, "normal", 1), n);
			}
		}
	}
}