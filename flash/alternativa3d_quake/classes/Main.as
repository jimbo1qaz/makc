﻿package {
	import alternativa.engine3d.controllers.CameraController;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Face;
	import alternativa.engine3d.core.Mesh;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Scene3D;
	import alternativa.engine3d.core.Surface;
	import alternativa.engine3d.display.View;
	import alternativa.engine3d.materials.*//TextureMaterial;
	import alternativa.types.Point3D;
	import alternativa.types.Texture;
	import alternativa.utils.FPS;
	import alternativa.utils.MeshUtils;
	
	import flash.display.*; 
	import flash.events.*;
	import flash.geom.*;
	import flash.net.*
	import flash.utils.*

	import com.suite75.quake1.io.*;

	/**
	 * Main (document) class.
	 * Large portions of its code were emm borrowed from QuakeEngine by Tim Knip.
	 */
	[SWF(backgroundColor="#000000", frameRate="100")]
	public class Main extends Sprite {

		private var logo:Logo;
		private var scene:Scene3D;
		private var view:View;
		private var camera:Camera3D;
		private var wasd:CameraController;

		private var reader:BspReader;
		private var curLeaf:int;
		private var normal:Point3D = new Point3D;

		private var linearNodeMap:Array = [];
		private var faceMeshesMap:Array = [];
		private var faceTexturesMap:Array = [];
		private var lavaFaceMeshes:Array = [];

		/**
		 * Constructor.
		 */
		public function Main() {
			addEventListener (Event.ADDED_TO_STAGE, onStage);
		}

		/**
		 * Fired when stage reference is accessible.
		 */
		private function onStage (event:Event):void {
			removeEventListener (Event.ADDED_TO_STAGE, onStage);

			// show something while stuff loads
			logo = new Logo; addChild (logo);

			// set up movie stage
			stage.quality = StageQuality.LOW;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;

			// set up scene, camera and all the boring stuff
			scene = new Scene3D(); scene.root = new Object3D();
			camera = new Camera3D(); camera.x = 150; camera.y = 150; camera.z = 150; scene.root.addChild(camera);
			view = new View(); addChild(view); view.camera = camera;

			wasd = new CameraController(stage); wasd.camera = camera; wasd.speed = 300;
			wasd.setDefaultBindings(); wasd.controlsEnabled = true;
			wasd.checkCollisions = true; wasd.collisionRadius = 20;
			
			FPS.init(stage);

			stage.addEventListener(Event.RESIZE, onResize);
			stage.addEventListener(Event.ENTER_FRAME, onRenderTick);
			onResize(null);

			// load level
			reader = new BspReader();
			reader.addEventListener(Event.COMPLETE, onBspComplete);
			//reader.addEventListener(ProgressEvent.PROGRESS, onBspProgress);
			reader.load("openquartz.sf.net/am1.bsp");
		}

		/**
		 * Fired when the BSP map is loaded.
		 */
		private function onBspComplete (event:Event):void
		{
			// we have all map info in reader
			if (reader.header.version != BspLump.BSPVERSION)
				throw new Error ("Supplied bsp file is not Quake1 map");

			// build linear map of BSP nodes for tree reconstruction
			var idx:int = BspModel (reader.models [0]).headnode [0];
			buildLinearNodeMap (reader.nodes [idx] as BspNode, 0);
	
			// reconstruct BSP tree
			stage.addEventListener (Event.ENTER_FRAME, buildBSPNodes);
		}

		/**
		 * Builds auxiliary linear map of nodes.
		 */
		private function buildLinearNodeMap (node:BspNode, depth:int):void {
			if (linearNodeMap.length -1 < depth)
				linearNodeMap [depth] = [];

			(linearNodeMap [depth] as Array).push (node);

			for (var i:int = 0; i < 2; i++) {
				if (node.children [i] > -1) {
					buildLinearNodeMap (reader.nodes [node.children [i]], depth + 1);
				}
			}
		}

		/**
		 * Fired when there are BSP nodes to add.
		 */
		private function buildBSPNodes(e:Event):void {
			var t:int = getTimer ();
			while (getTimer () - t < 0.5 * 1000 / stage.frameRate) {

				// find next node
				var depth:int = 0;
				while (linearNodeMap [depth].length < 1) {
					depth ++;
					if (depth == linearNodeMap.length) {
						// no more nodes left in the tree - we're done
						logo.visible = false; removeEventListener (Event.ENTER_FRAME, buildBSPNodes); return;
					}
				}

				// un-queue the node
				var node:BspNode = (linearNodeMap [depth] as Array).pop ();

				if (node.numfaces < 1)
					throw new Error ("BSP node has no faces defined - this can not be handled :(");

				// add it
				var mesh:Mesh, face:BspFace;
				for (var i:int = 0; i < node.numfaces; i++) {

					face = reader.faces [BspModel(reader.models [0]).firstface + node.firstface + i];

					mesh = createNodeFace (face, node);

					faceMeshesMap [node.firstface + i] = mesh;
					faceTexturesMap [node.firstface + i] = Surface (mesh.surfaces.peek ()).material;

					mesh.mobility = depth; scene.root.addChild (mesh);
				}
			}
		}

		/**
		 * Creates geometry for single face in a node.
		 */
		private function createNodeFace (face:BspFace, node:BspNode):Mesh {
			var i:int, j:int, k:int, m:int, p:Array, q:Array;
			var u:Point3D, v:Point3D, w:Point3D = new Point3D;

			// fetch texture information
			var texInfo:BspTexInfo = this.reader.tex_info[face.texture_info];
			var texture:BspTexture = BspTexture(reader.textures [texInfo.miptex]);

			u = new Point3D (texInfo.u_axis[0], texInfo.u_axis[1], texInfo.u_axis[2]);
			v = new Point3D (texInfo.v_axis[0], texInfo.v_axis[1], texInfo.v_axis[2]);

			// reconstruct a polygon
			var poly:Array = [], vertex:Array;
			for (i = 0; i < face.num_edges; i++) {
				
				var idx:int = reader.surfedges [face.first_edge + i];
				var edge:BspEdge = reader.edges [(idx < 0) ? -idx : idx];

				idx = (idx < 0) ? edge.endvertex : edge.startvertex;
				vertex = (reader.vertices [idx] as Array).slice();

				w.x = vertex[0]; w.y = vertex[1]; w.z = vertex[2];
				vertex[3] =  ( Point3D.dot(w, u) + texInfo.u_offset ) / texture.width;
				vertex[4] = -( Point3D.dot(w, v) + texInfo.v_offset ) / texture.height;

				poly.push (vertex);
			}

			// triangulate it (our poly should be convex, in theory)
			var tris:Array = triangulate (poly);

			// add each triangle
			var mesh:Mesh = new Mesh, mFaces:Array = [], mVertices:Array;
			for (i = 0, m = 0; i < tris.length; i++) {

				// filter very thin triangles out
				// these may come from bad map or bad parser - it's hard to tell
				p = tris [i][0];
				q = tris [i][1]; v.x = p[0] - q[0]; v.y = p[1] - q[1]; v.z = p[2] - q[2];
				q = tris [i][2]; w.x = p[0] - q[0]; w.y = p[1] - q[1]; w.z = p[2] - q[2];

				if (Point3D.cross(v, w).lengthSqr > 1.0) {

					mVertices = [];
					for (j = 2; j > -1; j--) {
						p = tris [i][j]; k = 100 *i +j;
						mesh.createVertex (p[0], p[1], p[2], k); mVertices.push (k);
					}

					mFaces.push (mesh.createFace (mVertices, m));
					mesh.setUVsToFace (
						new Point (tris[i][2][3], tris[i][2][4]),
						new Point (tris[i][1][3], tris[i][1][4]),
						new Point (tris[i][0][3], tris[i][0][4]), m);

					m++;
				}
			}
			mesh.createSurface (mFaces);

			// create and apply material
			var bmp:BitmapData = texture.bitmap;
			// does not work
			//if (face.lightmap_offset >= 0) bmp = reader.buildLightMap(face, bmp);
			mesh.setMaterialToAllSurfaces (new TextureMaterial (new Texture (bmp), 1, true));

			// collect lava meshes for animation
			if (texture.name.charAt(0) == "*") lavaFaceMeshes.push (mesh);

			return mesh;
		}

		/**
		 * Triangulates convex polygon.
		 */
		private function triangulate(points:Array):Array
		{
			var result:Array = new Array();
			result.push([points[0], points[1], points[2]]);
			for( var i:int = 2; i < points.length; i++ )
				result.push( [points[0], points[i], points[(i+1) % points.length]] );
			return result;			
		}

		/**
		 * "Animates" lava surfaces.
		 */
		private function animateLavaFaces ():void {
			var du:Number = 0.01, dv:Number = 0.005;
			var a:Point, b:Point, c:Point;
			for each (var mesh:Mesh in lavaFaceMeshes) {
				//for each (var face:Face in mesh.faces) {
				for (var i:int = 0; i < mesh.faces.length; i++) {
					var face:Face = mesh.getFaceById (i);
					a = face.aUV; b = face.bUV; c = face.cUV;
					// du
					a.x += du; b.x += du; c.x += du;
					if (Math.min (a.x, Math.min (b.x, c.x)) > 1) {
						a.x -= 1; b.x -= 1; c.x -= 1;
					}
					// dv
					a.y += dv; b.y += dv; c.y += dv;
					if (Math.min (a.y, Math.min (b.y, c.y)) > 1) {
						a.y -= 1; b.y -= 1; c.y -= 1;
					}
					// set new coordinates
					face.aUV = a; face.bUV = b; face.cUV = c;
				}
			}
			// fluctuate camera position to work around engine bug
			camera.z += 1; camera.z -= 1;
		}

		/**
		 * Binds view dimensions to stage.
		 */
		private function onResize(e:Event):void {
			view.width = stage.stageWidth;
			view.height = stage.stageHeight;
		}

		/**
		 * Processes user input and renders the scene.
		 */
		private function onRenderTick(e:Event):void {
			// move
			wasd.processInput ();
			// animate lava
			animateLavaFaces ();
			// show visible leaves only - does not work at the moment
/*
			var idx:int = findLeaf (camera.coords);
			if (idx != curLeaf && idx) {
				curLeaf = idx; showVisibleLeaves (curLeaf);
			}
*/
			// render
			scene.calculate ();
		}

		/**
		 * Finds the leaf containing the the player.
		 * 
		 * @param	playerPosition
		 * 
		 * @return	Index into the leaves array.
		 */
		private function findLeaf(playerPosition:Point3D):int
		{
			var idx:int = BspModel (reader.models[0]).headnode[0];
			while (idx >= 0) {
				var node:BspNode = reader.nodes[idx] as BspNode;
				var plane:BspPlane = reader.planes[node.planenum];	
				normal.x = plane.a; normal.y = plane.b; normal.z = plane.c;
				var dot:Number = Point3D.dot (normal, playerPosition) - plane.d;
				idx = (dot >= 0) ? node.children[0] : node.children[1];
			}
			return -(idx+1);
		}

		/**
		 * Renders a leaf, and all leaves that are visible 
		 * from that leaf. Uses Quake's Possible Visible Set (PVS).
		 * @see com.suite75.quake1.io.BspReader#visibility
		 * 
		 * @param	leafIndex
		 */
		private function showVisibleLeaves(leafIndex:int):void
		{
			var leaf:BspLeaf = reader.leaves[leafIndex];
			var numleafs:int = reader.leaves.length;
			var visisz:Array = reader.visibility;
			var v:int = leaf.visofs;
			var i:int, j:int, bit:int, faceIndex:int;
			var mesh:Mesh;

			// 1st, hide everything
			for each (mesh in faceMeshesMap)
				mesh.setMaterialToAllSurfaces (null);

			// adjust player z (probably to match PVS)
			var playerZ:Number = leaf.mins[2] + 60; camera.z = playerZ;
			
			for(i = 1; i < numleafs; v++)
			{
				if(visisz[v] == 0)
				{
					// value 0, leaves invisible: skip some leaves
					i += 8 * visisz[v + 1];    	
					v++;
				}
				else
				{
					// tag 8 leaves if needed, examine bits right to left
					for(bit = 1; bit < 0xff && i < numleafs; bit = bit * 2, i++)
					{
						if(visisz[v] & bit)
						{
							// unhide all faces in i-th leaf
							leaf = BspLeaf (reader.leaves[i]);
							for (j = 0; j < leaf.nummarksurfaces; j++ ) {
								faceIndex = reader.marksurfaces[leaf.firstmarksurface + i];
								mesh = faceMeshesMap [faceIndex];
								if (mesh)
									mesh.setMaterialToAllSurfaces (faceTexturesMap [faceIndex]);
							}
						}
					}
				}
			}
		}
	}
}