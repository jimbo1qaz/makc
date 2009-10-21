package  {
	import sandy.core.data.BSPNode;
	import sandy.core.data.Plane;
	import sandy.core.data.Point3D;
	import sandy.core.data.Polygon;
	import sandy.core.data.UVCoord;
	import sandy.core.data.Vertex;
	import sandy.core.scenegraph.Geometry3D;
	import sandy.core.scenegraph.Shape3D;
	import sandy.materials.Appearance;
	import sandy.math.PlaneMath;
	import sandy.view.Frustum;
	
	/**
	 * BSP-sorted shape with automatic polygons cutting.
	 * This is PoC hack, do not use in production.
	 * @author makc
	 */
	public class BSPShapeHack extends Shape3D {
		
		public function BSPShapeHack (shape:Shape3D) {
			// find all the planes upfront
			var threshold:Number = shape.boundingSphere.radius * 0.01;
			var planes:Array = getGeometryPlanes (shape.aPolygons, threshold, 1 - threshold);

			// build the tree (invalid faces)
			bsp = buildBSPTree (planes, shape.geometry);

			// build new geometry
			var g:Geometry3D = new Geometry3D;
			buildBSPGeometry (bsp, g, threshold)

			// create dummy polygon to get last polygon id
			var dummy:Polygon = makeSemivalidPoly (shape.geometry, [new Vertex, new Vertex], null, null);

			// set new geometry
			super (shape.name + "_bsp", g, shape.appearance); super.sortingMode = SORT_CUSTOM_BSP;

			// build valid faces
			buildValidFaces (bsp, dummy.id + 1);
		}

		override public function set sortingMode (ignore:int):void { }

		private function getGeometryPlanes (polygons:Array, planeDistanceThreshold:Number, planeDotThreshold:Number):Array {
			// sort polys into planes in order of appearance
			var i:int, j:int, k:int, planes:Array = [], usedPolys:Array = [];
			for (i = 0; i < polygons.length; i++) {
				var polyId:uint = Polygon (polygons [i]).id;

				// is this poly a part of other plane already?
				if (usedPolys.indexOf (polyId) > -1) continue;

				// no it is not
				usedPolys.push (polyId);

				// make new plane
				var poly:Polygon = Polygon (polygons [i]);
				var p:BSPNode = new BSPNode; p.faces = []; p.faces.push (poly);
				p.plane = PlaneMath.createFromNormalAndPoint (poly.normal.getPoint3D (),
					new Point3D (
						(poly.a.x + poly.b.x + poly.c.x) / 3,
						(poly.a.y + poly.b.y + poly.c.y) / 3,
						(poly.a.z + poly.b.z + poly.c.z) / 3
					));
	
				// loop through the rest of polys to find if they are in this plane
				for (j = i + 1; j < polygons.length; j++) {
					var poly2:Polygon = Polygon (polygons [j]);
					var poly2Center:Vertex = new Vertex (
						(poly2.a.x + poly2.b.x + poly2.c.x) / 3,
						(poly2.a.y + poly2.b.y + poly2.c.y) / 3,
						(poly2.a.z + poly2.b.z + poly2.c.z) / 3
					);
					var poly2d:Number = poly2Center.dot (poly.normal);
					if ((Math.abs (poly2d + p.plane.d) < planeDistanceThreshold)
							&& (Math.abs (poly2.normal.dot (poly.normal)) > planeDotThreshold)) {
						// this is coplanar poly - add it to the plane
						usedPolys.push (poly2.id);
						p.faces.push (poly2);
					}
				}

				// remember the plane
				planes.push (p);
			}

			return planes;
		}

		private function buildBSPTree (planes:Array, g:Geometry3D):BSPNode {
			// sort planes by area
			var i:int, j:int, k:int;
			var planesAreaSorter:Function = function (a:BSPNode, b:BSPNode):Number {
				var f:Polygon;
				var a_area:Number = 0; for each (f in a.faces) a_area += f.area;
				var b_area:Number = 0; for each (f in b.faces) b_area += f.area;
				if (a_area > b_area) return -1; else if (a_area < b_area) return +1;
				return 0;
			}

			planes.sort (planesAreaSorter);

			// pick one
			var cutter:BSPNode = planes.shift ();
			var cutterPlaneA:Plane = cutter.plane;
			var cutterPlaneB:Plane = new Plane (-cutter.plane.a, -cutter.plane.b, -cutter.plane.c, -cutter.plane.d);

			// split all the rest in two sets
			var planesA:Array = [];
			var planesB:Array = [];

			// cut the planes
			var f:Frustum = new Frustum;
			while (planes.length > 0) {
				var p:BSPNode = planes.shift ();
				var aPolys:Array = [];
				var bPolys:Array = [];
				for (j = 0; j < p.faces.length; j++) {
					var poly:Polygon = Polygon (p.faces [j]);
					var polyUVs:Array = (poly.aUVCoord == null) ? generateUVs (poly.vertices.length) : poly.aUVCoord;
					var aVertices:Array = poly.vertices.slice ();
					var aUVCoords:Array = polyUVs.slice ();
					var bVertices:Array = poly.vertices.slice ();
					var bUVCoords:Array = polyUVs.slice ();
					var aClipped:Boolean =
						f.clipPolygon (cutterPlaneA, aVertices, aUVCoords);
					if (aClipped) {
						var bClipped:Boolean =
							f.clipPolygon (cutterPlaneB, bVertices, bUVCoords);
						if (bClipped) {
							// clipping sets w* coords
							var z:int, w:Vertex;
							for (z = 0; z < aVertices.length; z++) {
								w = aVertices [z];
								w.x = w.wx; w.y = w.wy; w.z = w.wz;
							}
							for (z = 0; z < bVertices.length; z++) {
								w = bVertices [z];
								w.x = w.wx; w.y = w.wy; w.z = w.wz;
							}
							// make two temporary polys - these polys are not really valid
							var tmpPolyA:Polygon = makeSemivalidPoly (g, aVertices, aUVCoords, poly.normal);
							var tmpPolyB:Polygon = makeSemivalidPoly (g, bVertices, bUVCoords, poly.normal);

							if (aVertices.length < 5) {
								aPolys.push (tmpPolyA);
							} else {
								// sandy cant handle 5+ vertices, so we have to make even more polys
								var aTris:Array = triangulateVertexList (aVertices, aUVCoords);
								for (z = 0; z < aTris.length; z += 2) {
									aPolys.push (makeSemivalidPoly (g, aTris [z], aTris [z + 1], poly.normal));
								}
							}

							// same for Bs
							if (bVertices.length < 5) {
								bPolys.push (tmpPolyB);
							} else {
								var bTris:Array = triangulateVertexList (bVertices, bUVCoords);
								for (z = 0; z < bTris.length; z += 2) {
									bPolys.push (makeSemivalidPoly (g, bTris [z], bTris [z + 1], poly.normal));
								}
							}
						} else {
							bPolys.push (poly);
						}
					} else {
						aPolys.push (poly);
					}
				}

				// sort the plane to A/B sets according to results
				if (aPolys.length == 0) {
					planesB.push (p);
				} else if (bPolys.length == 0) {
					planesA.push (p);
				} else {
					var pA:BSPNode = new BSPNode;
					pA.faces = aPolys;
					pA.plane = p.plane;
					planesA.push (pA);

					var pB:BSPNode = new BSPNode;
					pB.faces = bPolys;
					pB.plane = p.plane;
					planesB.push (pB);
				}
			}

			// at this point, we have two sets of planes
			// we need to build bsp nodes for these sets
			if (planesA.length > 0)
				cutter.positive = buildBSPTree (planesA, g);
			if (planesB.length > 0)
				cutter.negative = buildBSPTree (planesB, g);

			return cutter;
		}

		private function generateUVs (n:int):Array {
			// workaround: sandy frustrum can't operate on non-uv polys
			var uvs:Array = [];	for (var i:int = 0; i < n; i++) uvs [i] = new UVCoord (
				Math.random (), Math.random ());
			return uvs;
		}

		private function makeSemivalidPoly (g:Geometry3D, vs:Array, us:Array, n:Vertex):Polygon {
			var p:Polygon = new Polygon (null, g, [0, 1, 2]);
			p.vertices = vs; p.aUVCoord = us; p.normal = n;
			p.a = vs [0]; p.b = vs [1]; p.c = vs [2];
			return p;
		}

		private function triangulateVertexList (vs:Array, us:Array):Array {
			var tris:Array = [];
			// triangulate
			for (var i:int = 1; i < vs.length - 1; i++) {
				var vsi:Array = [];
				vsi.push (vs [0]); vsi.push (vs [i]); vsi.push (vs [i+1]);
				var usi:Array = [];
				usi.push (us [0]); usi.push (us [i]); usi.push (us [i+1]);
				tris.push (vsi, usi);
			}
			return tris;
		}

		private function buildBSPGeometry (node:BSPNode, g:Geometry3D, t:Number):void {
			// re-add all the polys
			var i:int, j:int, k:int;
			for (i = 0; i < node.faces.length; i++) {
				var poly:Polygon = Polygon (node.faces [i]);
				var face:int = g.getNextFaceID ();
				// collect vertices and UVs
				var vertexIds:Array = [], UVIds:Array = [];
				for (j = 0; j < poly.vertices.length; j++) {
					// vertices
					var v:Vertex = poly.vertices [j];
					var vid:int = getVertexInRange (g, v, t);
					if (vid < 0) {
						vid = g.getNextVertexID ();
						g.setVertex (vid, v.x, v.y, v.z);
					}
					vertexIds.push (vid);
					// UVs... just create them
					var uid:int = g.getNextUVCoordID ();
					if (poly.aUVCoord != null)
						g.setUVCoords (uid, poly.aUVCoord [j].u, poly.aUVCoord [j].v);
					else
						g.setUVCoords (uid, Math.random (), Math.random ());
					UVIds.push (uid);
				}
				vertexIds.unshift (face); UVIds.unshift (face);
				g.setFaceVertexIds.apply (g, vertexIds);
				g.setFaceUVCoordsIds.apply (g, UVIds);

				// actual polygons will be created later, in geometry setter
				node.faces [i] = face;
			}

			// proceed with sub-nodes
			if (node.positive != null)
				buildBSPGeometry (node.positive, g, t);
			if (node.negative != null)
				buildBSPGeometry (node.negative, g, t);
		}

		private function getVertexInRange (g:Geometry3D, v:Vertex, range:Number):int {
			var i:int = g.aVertex.indexOf (v);
			if ((i < 0) && (range > 0)) {
				// find near vertex
				var r2:Number = range * range;
				for (var j:int = 0; j < g.aVertex.length; j++) {
					var vj:Vertex = g.aVertex [j];
					if ((v.x - vj.x) * (v.x - vj.x) +
						(v.y - vj.y) * (v.y - vj.y) +
						(v.z - vj.z) * (v.z - vj.z) < r2) {
						// bingo!
						i = j; j = g.aVertex.length;
					}
				}
			}
			return i;
		}

		private function buildValidFaces (node:BSPNode, base:uint):void {
			for (var i:int = 0; i < node.faces.length; i++) {
				node.faces [i] = Polygon.POLYGON_MAP [base + node.faces [i]];
			}

			if (node.negative) buildValidFaces (node.negative, base);
			if (node.positive) buildValidFaces (node.positive, base);
		}
	}

}