package lime.app;


import lime.app.Event;
import lime.Assets;

#if (js && html5)
import js.html.Image;
import js.html.SpanElement;
import js.Browser;
import lime.net.HTTPRequest;
#elseif flash
import flash.display.LoaderInfo;
import flash.display.Sprite;
import flash.events.ProgressEvent;
import flash.Lib;
#end


class Preloader #if flash extends Sprite #end {
	
	
	public var complete:Bool;
	public var onComplete = new Event<Void->Void> ();
	public var onProgress = new Event<Int->Int->Void> ();
	
	#if (js && html5)
	public static var images = new Map<String, Image> ();
	public static var loaders = new Map<String, HTTPRequest> ();
	private var loaded = 0;
	private var total = 0;
	#end
	
	
	public function new () {
		
		#if flash
		super ();
		#end
		onProgress.add (update);
		
	}
	
	
	public function create (config:Config):Void {
		
		#if flash
		Lib.current.addChild (this);
		
		Lib.current.loaderInfo.addEventListener (flash.events.Event.COMPLETE, loaderInfo_onComplete);
		Lib.current.loaderInfo.addEventListener (flash.events.Event.INIT, loaderInfo_onInit);
		Lib.current.loaderInfo.addEventListener (ProgressEvent.PROGRESS, loaderInfo_onProgress);
		Lib.current.addEventListener (flash.events.Event.ENTER_FRAME, current_onEnter);
		#end
		
		#if (!flash && !html5)
		start ();
		#end
		
	}
	
	
	public function load (urls:Array<String>, types:Array<AssetType>):Void {
		
		#if (js && html5)
		
		var url = null;
		var cacheVersion = Assets.cache.version;
		
		for (i in 0...urls.length) {
			
			url = urls[i];
			
			switch (types[i]) {
				
				case IMAGE:
					
					if (!images.exists (url)) {
						
						var image = new Image ();
						images.set (url, image);
						image.onload = image_onLoad;
						image.src = url + "?" + cacheVersion;
						total++;
						
					}
				
				case BINARY:
					
					if (!loaders.exists (url)) {
						
						var loader = new HTTPRequest ();
						loaders.set (url, loader);
						total++;
						
					}
				
				case TEXT:
					
					if (!loaders.exists (url)) {
						
						var loader = new HTTPRequest ();
						loaders.set (url, loader);
						total++;
						
					}
				
				case FONT:
					
					total++;
					loadFont (url);
				
				default:
				
			}
			
		}
		
		for (url in loaders.keys ()) {
			
			var loader = loaders.get (url);
			var future = loader.load (url + "?" + cacheVersion);
			future.onComplete (loader_onComplete);
			
		}
		
		if (total == 0) {
			
			start ();
			
		}
		
		#end
		
	}
	
	#if (js && html5)
	private static function __measureFontNode (fontFamily:String):SpanElement {
		
		var node:SpanElement = cast Browser.document.createElement ("span");
		node.setAttribute ("aria-hidden", "true");
		var text = Browser.document.createTextNode ("BESbswy");
		node.appendChild (text);
		var style = node.style;
		style.display = "block";
		style.position = "absolute";
		style.top = "-9999px";
		style.left = "-9999px";
		style.fontSize = "300px";
		style.width = "auto";
		style.height = "auto";
		style.lineHeight = "normal";
		style.margin = "0";
		style.padding = "0";
		style.fontVariant = "normal";
		style.whiteSpace = "nowrap";
		style.fontFamily = fontFamily;
		Browser.document.body.appendChild (node);
		return node;
		
	}
	#end


	#if (js && html5)
	private function loadFont (font:String):Void {

		var node1 = __measureFontNode ("'" + font + "', sans-serif");
		var node2 = __measureFontNode ("'" + font + "', serif");
		
		var width1 = node1.offsetWidth;
		var width2 = node2.offsetWidth;
		
		var interval = -1;
		var timeout = 3000;
		var intervalLength = 50;
		var intervalCount = 0;
		var fontLoaded, timeExpired;
		
		var checkFont = function () {
			
			intervalCount++;
			
			fontLoaded = (node1.offsetWidth != width1 || node2.offsetWidth != width2);
			timeExpired = (intervalCount * intervalLength >= timeout);
			
			if (fontLoaded || timeExpired) {
				
				Browser.window.clearInterval (interval);
				node1.parentNode.removeChild (node1);
				node2.parentNode.removeChild (node2);
				node1 = null;
				node2 = null;
				
				
				loaded ++;
				
				onProgress.dispatch (loaded, total);
				
				if (loaded == total) {
					start ();
				}
				
			}
			
		}
		
		interval = Browser.window.setInterval (checkFont, intervalLength);
		
		
	}
	#end
	
	
	private function start ():Void {
		
		complete = true;
		
		#if flash
		if (Lib.current.contains (this)) {
			
			Lib.current.removeChild (this);
			
		}
		#end
		
		onComplete.dispatch ();
		
	}
	
	
	private function update (loaded:Int, total:Int):Void {
		
		
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	#if (js && html5)
	private function image_onLoad (_):Void {
		
		loaded++;
		
		onProgress.dispatch (loaded, total);
		
		if (loaded == total) {
			
			start ();
			
		}
		
	}
	
	
	private function loader_onComplete (_):Void {
		
		loaded++;
		
		onProgress.dispatch (loaded, total);
		
		if (loaded == total) {
			
			start ();
			
		}
		
	}
	#end
	
	
	#if flash
	private function current_onEnter (event:flash.events.Event):Void {
		
		if (!complete && Lib.current.loaderInfo.bytesLoaded == Lib.current.loaderInfo.bytesTotal) {
			
			complete = true;
			onProgress.dispatch (Lib.current.loaderInfo.bytesLoaded, Lib.current.loaderInfo.bytesTotal);
			
		}
		
		if (complete) {
			
			Lib.current.removeEventListener (flash.events.Event.ENTER_FRAME, current_onEnter);
			Lib.current.loaderInfo.removeEventListener (flash.events.Event.COMPLETE, loaderInfo_onComplete);
			Lib.current.loaderInfo.removeEventListener (flash.events.Event.INIT, loaderInfo_onInit);
			Lib.current.loaderInfo.removeEventListener (ProgressEvent.PROGRESS, loaderInfo_onProgress);
			
			start ();
			
		}
		
	}
	
	
	private function loaderInfo_onComplete (event:flash.events.Event):Void {
		
		complete = true;
		onProgress.dispatch (Lib.current.loaderInfo.bytesLoaded, Lib.current.loaderInfo.bytesTotal);
		
	}
	
	
	private function loaderInfo_onInit (event:flash.events.Event):Void {
		
		onProgress.dispatch (Lib.current.loaderInfo.bytesLoaded, Lib.current.loaderInfo.bytesTotal);
		
	}
	
	
	private function loaderInfo_onProgress (event:flash.events.ProgressEvent):Void {
		
		onProgress.dispatch (Lib.current.loaderInfo.bytesLoaded, Lib.current.loaderInfo.bytesTotal);
		
	}
	#end
	
	
}
