package funkin.objects;

import openfl.geom.ColorTransform;
import flixel.math.FlxMatrix;
import openfl.display.BlendMode;
import openfl.geom.Rectangle;
import openfl.display.BitmapData;
import flixel.util.FlxColor;
import flixel.system.FlxAssets;

class AFT extends FlxSprite {
	public var framerate:Float;
	public var aftBlend:BlendMode = NORMAL;
	public var aftMatrix:FlxMatrix = new FlxMatrix();
	public var aftClipRect:Rectangle;
	public var aftColorTransform:ColorTransform;
	public var recursive:Bool = false;

	var aftShader:AFTShader = new AFTShader();
	var bitmapData:BitmapData;
	var targetCamera:FlxCamera;

	override public function new(targetCamera:FlxCamera, x:Float, y:Float) {
		super(x, y);
		//shader = aftShader;
		makeGraphic(targetCamera.width, targetCamera.height, FlxColor.TRANSPARENT);
		bitmapData = new BitmapData(Std.int(width), Std.int(height), true, FlxColor.TRANSPARENT);
		bitmapData.disposeImage();
		aftClipRect = new Rectangle(0, 0, width, height);
		aftColorTransform = new ColorTransform();

		this.targetCamera = targetCamera;

		framerate = ClientPrefs.framerate;
		aftMatrix.identity();
	}

	public function clear() {
		bitmapData.fillRect(aftClipRect, FlxColor.TRANSPARENT);
	}

	var updateTimer:Float = 0;


	override function update(elapsed:Float) {
		super.update(elapsed);
		updateTimer += elapsed;
		if (framerate != 0 && updateTimer >= 1 / framerate) {
			if(!recursive){
				inline clear();
			}
			bitmapData.draw(targetCamera.canvas, aftMatrix, aftColorTransform, aftBlend, aftClipRect, antialiasing);
			pixels = bitmapData;
			updateTimer = 0;
		}
		//aftShader.sourceBitmap.input = bitmapData;
	}
}

private class AFTShader extends FlxShader {
	@:glFragmentSource('
        #pragma header

        uniform sampler2D sourceBitmap;

        void main()
        {
            gl_FragColor = flixel_texture2D(sourceBitmap, openfl_TextureCoordv.xy);
        }
    ')
	public function new() {
		super();
	}
}
