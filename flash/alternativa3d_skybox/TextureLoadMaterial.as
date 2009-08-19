package  {
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.engine3d.materials.TextureMaterialPrecision;
	import alternativa.types.Texture;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	
	/**
	* Material that loads its texture from URL.
	* @author makc
	*/
	public class TextureLoadMaterial extends TextureMaterial {

		private var loader:Loader;
		private var texturePlaceholder:Texture;

		public function TextureLoadMaterial (texture:String,
			// the rest are TextureMaterial arguments
			alpha:Number = 1, repeat:Boolean = true, smooth:Boolean = false, blendMode:String = BlendMode.NORMAL, wireThickness:Number = -1, wireColor:uint = 0, precision:Number = TextureMaterialPrecision.MEDIUM) {

			// 1st, create texture placeholder
			texturePlaceholder = new Texture (new BitmapData (1, 1, false, 0));

			// create material ready to be used
			super (texturePlaceholder, alpha, repeat, smooth, blendMode, wireThickness, wireColor, precision);

			// load texture
			loader = new Loader;
			addListeners (loader.contentLoaderInfo);
			loader.load (new URLRequest (texture));
		}

		private function onLoadComplete (e:Event):void {
			var inf:LoaderInfo = LoaderInfo (e.target);
			removeListeners (inf);

			var bmp:Bitmap = inf.content as Bitmap;
			if (bmp != null) {
				// replace the texture
				texturePlaceholder.bitmapData.dispose ();
				texturePlaceholder = new Texture (bmp.bitmapData);
				texture = texturePlaceholder;
			}
		}

		private function onLoadError (e:IOErrorEvent):void {
			removeListeners (LoaderInfo (e.target));
		}

		private function addListeners (inf:LoaderInfo):void {
			inf.addEventListener(Event.COMPLETE, onLoadComplete);
			inf.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			inf.addEventListener(IOErrorEvent.NETWORK_ERROR, onLoadError);
			inf.addEventListener(IOErrorEvent.VERIFY_ERROR, onLoadError);
		}

		private function removeListeners (inf:LoaderInfo):void {
			inf.removeEventListener(Event.COMPLETE, onLoadComplete);
			inf.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
			inf.removeEventListener(IOErrorEvent.NETWORK_ERROR, onLoadError);
			inf.removeEventListener(IOErrorEvent.VERIFY_ERROR, onLoadError);
		}
	}

}