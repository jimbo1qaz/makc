package 
{
    import flash.geom.Point;
    import sandy.primitive.Primitive3D;
    import sandy.core.scenegraph.Geometry3D;
    import sandy.core.scenegraph.Shape3D;   
 
    /**
    * A hexagon primitive
    * Reference formulas taken from http://www.rdwarf.com/users/wwonko/hex/
    * 
    * @author       Yaniv Pe'er
    * @version      1.0
    * @date         19.06.2008
    *
    * @example To create a hexagon with 100 radius with default values quality and alignment, use the following statement:
    * 
    *  <listing version="3.0">
    *     var hex:Hexagon = new Hexagon('My hexagon', 100);
    *  </listing>
    * 
    * To create the same hexagon aligned parallel to the zx-plane and quality division 3 use this:
    * <listing version="3.0">
    *     var hex:Hexagon = new Hexagon('My hexagon', 100, 3, Hexagon.ZX_ALIGNED);
    *  </listing>
    */
    public class Hexagon extends Shape3D implements Primitive3D
    {
        /**
        * Specifies hexagon will be parallel to the xy-plane.
        */
        public static const XY_ALIGNED:String = "xy_aligned";
 
        /**
        * Specifies hexagon will be parallel to the yz-plane.
        */
        public static const YZ_ALIGNED:String = "yz_aligned";
 
        /**
        * Specifies hexagon will be parallel to the zx-plane.
        */
        public static const ZX_ALIGNED:String = "zx_aligned";
 
        //////////////////
        ///PRIVATE VARS///
        //////////////////
        private var m_nR:Number;
        private var m_nQ:Number;
        private var m_sType:String;
        private var m_aVtxId:Array;
        private var m_aUvId:Array;
        private var m_hMin:Number;
        private var m_lMin:Number;
        private var m_hMax:Number;
        private var m_lMax:Number;
        
 
        /**
        * Creates a Hexagon primitive.
        *
        * <p>The hexagon is created with its center in the origin of the global coordinate system.
        * It will be parallel to one of the global coordinate hexagons in accordance with the alignment parameter.</p>
        *
        * @param p_sName        A string identifier for this object.
        * @param p_nRadius      Radius of the hexagon.
        * @param p_sType        Alignment of the hexagon, one of XY_ALIGNED ( default ), YZ_ALIGNED or ZX_ALIGNED.
        *
        * @see PrimitiveMode
        */
        public function Hexagon(p_sName:String=null, p_nRadius:Number = 100, p_nQuality:Number = 1, p_sType:String=Hexagon.XY_ALIGNED )
        {
            super( p_sName );
            m_nR = p_nRadius;
            m_nQ = p_nQuality;
            m_sType = p_sType;
            m_aVtxId = new Array();
            m_aUvId = new Array();
            
            m_hMin = -m_nR / 2;
            m_lMin = -m_nR / 2;
            m_hMax = m_nR / 2;
            m_lMax = m_nR / 2;
            geometry = generate();          
        }
 
        /**
        * Generates the geometry for the hexagon.
        *
        * @return The geometry object for the hexagon.
        *
        * @see sandy.core.scenegraph.Geometry3D
        */
        public function generate( ...arguments ):Geometry3D
        {
            var l_geometry:Geometry3D = new Geometry3D();
            //Creation of the points
            var a:Number, b:Number, c:Number;
            var l:Array = new Array();
            var h:Array = new Array();
            var i:Number, j:Number;
            var cpVtxId:Number, cpUvId:Number;
            var vtxId:Array = new Array()
            var uvId:Array = new Array();
            
            // contants for calculating hexa
            c = 0.5 * m_nR;
            a = 0.5 * c;
            b = 0.866 * c;
            
            // point 1
            l[0] = 0 - c;
            h[0] = 0;
            
            // point 2
            l[1] = a - c;
            h[1] = -b;
            
            // point 3
            l[2] = a;
            h[2] = -b;
            
            // point 4
            l[3] = 2 * c - c;
            h[3] = 0;
            
            // point 5
            l[4] = a;
            h[4] = 2 * b - b;
 
            // point 6
            l[5] = a - c;
            h[5] = 2 * b - b;
            
            l[6] = l[0];
            h[6] = h[0];            
            
        
            // drawing
            for ( i = 0; i < 6; i++ )
            {               
                var vtxs:Array = new Array();
                var uvs:Array = new Array();
                generateTriangle( vtxs, uvs, l_geometry, new Point(l[i], h[i]), new Point(l[i + 1], h[i + 1]), new Point(0, 0), m_nQ );
                
                // draw triangle faces
                for ( j = 0; j < vtxs.length; j += 3 )
                {
                    l_geometry.setFaceVertexIds( l_geometry.getNextFaceID(), vtxs[j], vtxs[j + 1], vtxs[j + 2] );
                    l_geometry.setFaceUVCoordsIds( l_geometry.getNextFaceUVCoordID(), uvs[j], uvs[j + 1], uvs[j + 2] );
                }
            }
            return (l_geometry);
        }
 
        /**
         * Draws a triangle vertex, UV and faces
         * Each division of the triangle divides it into four sub triangles.
         * @param   p_aVertexes  Vertexes array to write to.
         * @param   p_aUvs       UVs array to write to.
         * @param   p_geometry   Geometry object to write to.
         * @param   p_pt1        Point 1 of the triangle.
         * @param   p_pt2        Point 2 of the triangle.
         * @param   p_pt3        Point 3 of the triangle.
         * @param   p_nQuality   Quality of the triangle mesh (Number of divides for recoursion).
         * @return  Array of points to connect linearly
         */
        private function generateTriangle( p_aVertexes:Array, p_aUvs:Array, p_geometry:Geometry3D, p_pt1:Point, p_pt2:Point, p_pt3:Point, p_nQuality:Number = 1 ):void
        {
            var retVtxIds:Array = new Array();
            
            // quality == 1 is our recoursion stopper
            if (p_nQuality == 1)
            {
                // create vertexes for the triangle (according to alignment settings)
                if( m_sType == Hexagon.ZX_ALIGNED )
                {
                    createVertex( p_geometry, p_aVertexes, p_pt1.x, 0, p_pt1.y );
                    createVertex( p_geometry, p_aVertexes, p_pt2.x, 0, p_pt2.y );
                    createVertex( p_geometry, p_aVertexes, p_pt3.x, 0, p_pt3.y );           
                }
                else if( m_sType == Hexagon.YZ_ALIGNED )
                {
                    createVertex( p_geometry, p_aVertexes, 0, p_pt1.x, p_pt1.y );
                    createVertex( p_geometry, p_aVertexes, 0, p_pt2.x, p_pt2.y );
                    createVertex( p_geometry, p_aVertexes, 0, p_pt3.x, p_pt3.y );
                }
                else
                {
                    createVertex( p_geometry, p_aVertexes, p_pt1.x, p_pt1.y, 0 );
                    createVertex( p_geometry, p_aVertexes, p_pt2.x, p_pt2.y, 0 );
                    createVertex( p_geometry, p_aVertexes, p_pt3.x, p_pt3.y, 0 );
                }
                
                // create UVs for the triangle (alignment doesn't matter here)
                createUV( p_geometry, p_aUvs, p_pt1.x, p_pt1.y );
                createUV( p_geometry, p_aUvs, p_pt2.x, p_pt2.y );
                createUV( p_geometry, p_aUvs, p_pt3.x, p_pt3.y );
            }
            else
            {
                // dividing points
                var pt12:Point = new Point((p_pt1.x + p_pt2.x) / 2, (p_pt1.y + p_pt2.y) / 2);
                var pt23:Point = new Point((p_pt2.x + p_pt3.x) / 2, (p_pt2.y + p_pt3.y) / 2);
                var pt31:Point = new Point((p_pt3.x + p_pt1.x) / 2, (p_pt3.y + p_pt1.y) / 2);
 
                // dividing triangles
                generateTriangle( p_aVertexes, p_aUvs, p_geometry, p_pt1, pt12, pt31, p_nQuality - 1 );
                generateTriangle( p_aVertexes, p_aUvs, p_geometry, p_pt2, pt23, pt12, p_nQuality - 1 );
                generateTriangle( p_aVertexes, p_aUvs, p_geometry, p_pt3, pt31, pt23, p_nQuality - 1 );
                generateTriangle( p_aVertexes, p_aUvs, p_geometry, pt12, pt23, pt31, p_nQuality - 1 );
            }
        }
        
        /**
         * Creates vertex
         * @param   p_geometry Geometry to put the vertexes and UVs in.
         * @param   p_aVertexes Vertexes Ids reference to add to.
         * @param   p_nX X coordinate.
         * @param   p_nY Y coordinate.
         * @param   p_nZ z coordinate.
         */
        private function createVertex(p_geometry:Geometry3D, p_aVertexes:Array, p_nX:Number, p_nY:Number, p_nZ:Number):void
        {
            // vertex
            if (m_aVtxId[p_nX + '_' + p_nY + '_' + p_nZ] == undefined)
            {
                m_aVtxId[p_nX + '_' + p_nY + '_' + p_nZ] = p_geometry.getNextVertexID();
                p_aVertexes.push(m_aVtxId[p_nX + '_' + p_nY + '_' + p_nZ]);
                p_geometry.setVertex( m_aVtxId[p_nX + '_' + p_nY + '_' + p_nZ], p_nX, p_nY, p_nZ );
            }
            else
                p_aVertexes.push(m_aVtxId[p_nX + '_' + p_nY + '_' + p_nZ]);
        }
        
        /**
         * Creates UV
         * @param   p_geometry Geometry to put the vertexes and UVs in.
         * @param   p_aUvs UVs Ids reference to add to.
         * @param   p_nX X coordinate.
         * @param   p_nY Y coordinate.
         * @param   p_nZ z coordinate.
         */
        private function createUV(p_geometry:Geometry3D, p_aUvs:Array, p_nH:Number, p_nL:Number):void
        {
            // UV
            if (m_aUvId[p_nH + '_' + p_nL] == undefined)
            {
                m_aUvId[p_nH + '_' + p_nL] = p_geometry.getNextUVCoordID();
                p_aUvs.push(m_aUvId[p_nH + '_' + p_nL]);
                p_geometry.setUVCoords( m_aUvId[p_nH + '_' + p_nL], p_nH / (m_hMax - m_hMin) + 0.5, p_nL / (m_lMax - m_lMin) + 0.5);
            }
            else
                p_aUvs.push(m_aUvId[p_nH + '_' + p_nL]);
        }       
        
        /**
        * @private
        */
        public override function toString():String
        {
            return "Hexagon";
        }
    }
}