package  {
	import sandy.primitive.Primitive3D;
	import sandy.core.scenegraph.Geometry3D;
	import sandy.core.scenegraph.Shape3D;

	public class Crystal extends Shape3D implements Primitive3D {
		private var l:Geometry3D;

		private function f(v1:Number,v2:Number,v3:Number,uv00:Number,uv01:Number,uv10:Number,uv11:Number,uv20:Number,uv21:Number,normX:Number,normY:Number,normZ:Number):void {
			var uv1:Number = l.getNextUVCoordID();
			var uv2:Number = uv1 + 1;
			var uv3:Number = uv2 + 1;

			l.setUVCoords(uv1,uv00,1-uv01);
			l.setUVCoords(uv2,uv10,1-uv11);
			l.setUVCoords(uv3,uv20,1-uv21);

			l.setFaceVertexIds(l.getNextFaceID(), v1,v2,v3);
			l.setFaceUVCoordsIds(l.getNextFaceUVCoordID(), uv1,uv2,uv3);
			l.setFaceNormal(l.getNextFaceNormalID(), normX,normZ,normY);
		}

		private function f4(v1:Number,v2:Number,v3:Number,v4:Number,uv00:Number,uv01:Number,uv10:Number,uv11:Number,uv20:Number,uv21:Number,uv30:Number,uv31:Number,normX:Number,normY:Number,normZ:Number):void {
			var uv1:Number = l.getNextUVCoordID();
			var uv2:Number = uv1 + 1;
			var uv3:Number = uv2 + 1;
			var uv4:Number = uv3 + 1;

			l.setUVCoords(uv1,uv00,1-uv01);
			l.setUVCoords(uv2,uv10,1-uv11);
			l.setUVCoords(uv3,uv20,1-uv21);
			l.setUVCoords(uv4,uv30,1-uv31);

			l.setFaceVertexIds(l.getNextFaceID(),v1,v2,v3,v4);
			l.setFaceUVCoordsIds(l.getNextFaceUVCoordID(),uv1,uv2,uv3,uv4);
			l.setFaceNormal(l.getNextFaceNormalID(),normX,normZ,normY);
		}

		private function f2(v1:Number,v2:Number,v3:Number):void {
			l.setFaceVertexIds(l.getNextFaceID(), v1,v2,v3);
		}

		private function f24(v1:Number,v2:Number,v3:Number,v4:Number):void {
			l.setFaceVertexIds(l.getNextFaceID(), v1,v2,v3,v4);
		}

		private function v(vx:Number,vy:Number,vz:Number):void {
			l.setVertex(l.getNextVertexID(),vx,vz,vy);
		}

		public function Crystal( p_Name:String=null ) {
			super( p_Name );
			geometry = generate();
		}

		public function generate(... arguments):Geometry3D {
			l = new Geometry3D();
			v(-0.379842,-1.000000,-1.291163);
			v(-0.379842,-1.000001,0.708837);
			v(1.000000,-1.000000,-1.000000);
			v(0.584520,-1.000000,-1.291163);
			v(0.584520,-1.000000,-1.291163);
			v(1.607924,1.991489,-1.291163);
			v(2.131421,-1.174694,-0.590232);
			v(-0.553417,-0.141779,0.721677);
			v(-0.553417,-0.141779,0.721677);
			v(0.317091,1.448889,2.003078);
			v(-0.714008,0.763977,0.432177);
			v(1.961558,1.829587,1.125890);
			v(1.284095,1.465842,1.594887);
			v(1.945588,3.016560,1.580573);

			f2(0,5,4);
			f2(0,1,5);
			f2(0,3,1);
			f2(1,4,5);
			f2(9,7,6);
			f2(10,8,9);
			f2(10,9,6);
			f2(10,6,7);
			f2(2,11,12);
			f2(11,13,12);
			f2(2,12,13);
			f2(2,13,11);

			this.x = 0.000000;
			this.y = 0.000000;
			this.z = 0.000000;

			this.rotateX = 0.000000;
			this.rotateY = 0.000000;
			this.rotateZ = -0.000000;

			this.scaleX = 1.000000;
			this.scaleY = 1.000000;
			this.scaleZ = 1.000000;
			return (l);
		}
	}
}