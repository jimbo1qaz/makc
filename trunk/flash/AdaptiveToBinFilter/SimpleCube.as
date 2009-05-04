/* 
 * AdaptiveToBinFilter test
 *
 * This work is based on the Saqoosha pv3d starter kit
 * http://saqoosha.net/lab/FLARToolKit/FLARToolKit-starter-kit.zip
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this framework; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */
package {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.media.Camera;
	import flash.media.Video;

	import org.papervision3d.lights.PointLight3D;
	import org.papervision3d.materials.WireframeMaterial;
	import org.papervision3d.materials.shadematerials.FlatShadeMaterial;
	import org.papervision3d.materials.utils.MaterialsList;
	import org.papervision3d.objects.primitives.Cube;
	import org.papervision3d.objects.primitives.Plane;

	import org.libspark.flartoolkit.pv3d.FLARBaseNode;
	import org.libspark.flartoolkit.pv3d.FLARCamera3D;
	import org.papervision3d.render.LazyRenderEngine;
	import org.papervision3d.scenes.Scene3D;
	import org.papervision3d.view.Viewport3D;
	import org.papervision3d.view.stats.StatsView;

	import org.libspark.flartoolkit.core.FLARCode;
	import org.libspark.flartoolkit.core.FLARMat;
	import org.libspark.flartoolkit.core.param.FLARParam;
	import org.libspark.flartoolkit.core.raster.rgb.FLARRgbRaster_BitmapData;
	import org.libspark.flartoolkit.core.transmat.FLARTransMatResult;
	import org.libspark.flartoolkit.core.types.FLARIntSize;
	import org.libspark.flartoolkit.detector.FLARSingleMarkerDetector;

	import rgb2bin.AdaptiveToBinFilter;

	public class SimpleCube extends Sprite {

		protected var video:Video;
		protected var videoSnapshot:BitmapData;
		protected var webcam:Camera;

		protected var _viewport:Viewport3D;
		protected var _camera3d:FLARCamera3D;
		protected var _scene:Scene3D;
		protected var _renderer:LazyRenderEngine;
		protected var _baseNode:FLARBaseNode;
		
		private var _plane:Plane;
		private var _cube:Cube;
		
		[Embed(source='../data/camera_para.dat', mimeType='application/octet-stream')]
		protected var CameraData:Class;
		[Embed(source='../data/test.pat', mimeType='application/octet-stream')]
		protected var MarkerData:Class;

		protected const MarkerSize:Number = 100;

		protected var param:FLARParam;
		protected var code:FLARCode;
		protected var raster:FLARRgbRaster_BitmapData;
		protected var detector:FLARSingleMarkerDetector;
		protected var result:FLARTransMatResult;

		[SWF(width=640, height=480)]
		public function SimpleCube () {
			scaleX = scaleY = 2;

			webcam = Camera.getCamera ();
			if (!webcam) throw new Error ('No webcam :(');

			webcam.setMode(320, 240, stage.frameRate);
			video = new Video (320, 240); video.attachCamera (webcam); addChild (video);
			videoSnapshot = new BitmapData (320, 240, false, 0);

			param = new FLARParam ();
			param.loadARParam (new CameraData);
			param.changeScreenSize (320, 240);

			code = new FLARCode (16, 16);
			code.loadARPatt (new MarkerData);

			raster = new FLARRgbRaster_BitmapData (videoSnapshot);
			detector = new FLARSingleMarkerDetector (param, code, MarkerSize);

			detector.setContinueMode (false);
			detector.filter = new AdaptiveToBinFilter (80);

			result = new FLARTransMatResult ();

			// code borrowed from Saqoosha pv3d starter kit
			this._viewport = addChild(new Viewport3D(320, 240)) as Viewport3D;
			this._camera3d = new FLARCamera3D(param);
			this._scene = new Scene3D();
			this._baseNode = this._scene.addChild(new FLARBaseNode()) as FLARBaseNode;
			this._renderer = new LazyRenderEngine(this._scene, this._camera3d, this._viewport);
			this.addEventListener(Event.ENTER_FRAME, this._onEnterFrame);

			var wmat:WireframeMaterial = new WireframeMaterial(0xff0000, 1, 2);
			this._plane = new Plane(wmat, MarkerSize, MarkerSize);
			this._plane.rotationX = 180;
			this._baseNode.addChild(this._plane);

			var light:PointLight3D = new PointLight3D();
			light.x = 0; light.y = 1000; light.z = -1000;

			var fmat:FlatShadeMaterial = new FlatShadeMaterial(light, 0xff22aa, 0x75104e);
			this._cube = new Cube(new MaterialsList({all: fmat}), MarkerSize/2, MarkerSize/2, MarkerSize/2);
			this._cube.z = MarkerSize/4;
			this._baseNode.addChild(this._cube);
		}

		private function _onEnterFrame(e:Event = null):void {
			videoSnapshot.draw (video);

			var a:Number = 0, af:AdaptiveToBinFilter = detector.filter as AdaptiveToBinFilter;
			if (detector.detectMarkerLite (raster, 80)) {
				a = detector.getConfidence ();

				if (a > 0.5) {
					detector.getTransformMatrix(result);
					_baseNode.setTransformMatrix(result);
					_baseNode.visible = true;
				} else {
					_baseNode.visible = false;
				}

				// shrink search area
				if (af != null) af.adjustSearchArea (videoSnapshot.rect, detector.getSquare (), a);

			} else {
				_baseNode.visible = false;

				// reset search area
				if (af != null) af.adjustSearchArea (videoSnapshot.rect, null, 0);
			}

			this._renderer.render();
		}
	}
}