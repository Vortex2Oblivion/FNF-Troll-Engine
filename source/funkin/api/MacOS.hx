package funkin.api;

import cpp.Pointer;

@:buildXml('<include name="../../../../source/funkin/api/build.xml" />')
@:include("macos.hpp")
extern class MacOS {
	@:native("macos::fixWindowColorSpace")
	static function fixWindowColorSpace(handle:cpp.Pointer<cpp.Void>):Void;
}