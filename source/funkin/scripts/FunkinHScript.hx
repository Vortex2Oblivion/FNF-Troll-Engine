package funkin.scripts;

import openfl.events.DataEvent;
import funkin.scripts.*;
import funkin.scripts.Globals.*;

import funkin.states.PlayState;
import funkin.states.PlayState.RatingSprite;
import funkin.states.MusicBeatState;
import funkin.states.MusicBeatSubstate;

import funkin.input.PlayerSettings;
import funkin.api.Windows;

import flixel.FlxG;
import flixel.math.FlxPoint;

import lime.app.Application;
import haxe.ds.StringMap;

import hscript.*;

using StringTools;

class FunkinHScript extends FunkinScript
{
	public static final parser:Parser = new Parser();
	public static final defaultVars:Map<String, Dynamic> = new Map<String, Dynamic>();

	public static function init() // BRITISH
	{
		parser.allowMetadata = true;
		parser.allowJSON = true;
		parser.allowTypes = true;

		final definitions:Map<String, String> = funkin.macros.Sowy.getDefines();
		for (k => v in definitions)
			parser.preprocesorValues.set(k, v);

		parser.preprocesorValues.set("TROLL_ENGINE", Main.semanticVersion);
	}

	inline public static function parseString(script:String, ?name:String = "Script")
	{
		parser.line = 1;
		return parser.parseString(script, name);
	}

	inline public static function parseFile(file:String, ?name:String)
		return parseString(Paths.getContent(file), (name == null ? file : name));

	public static function blankScript(?name, ?additionalVars)
	{
		return new FunkinHScript(null, name, additionalVars, false);
	}

	/** No exception catching or display */
	public static function _fromString(script:String, ?name:String = "Script", ?additionalVars:Map<String, Any>, ?doCreateCall:Bool = true)
		return new FunkinHScript(parseString(script, name), name, additionalVars, doCreateCall);

	// safe ver
	public static function fromString(script:String, ?name:String = "Script", ?additionalVars:Map<String, Any>, ?doCreateCall:Bool = true):FunkinHScript
	{
		try {
			return _fromString(script, name, additionalVars, doCreateCall);
		}
		catch (e:haxe.Exception) {
			var errMsg = 'Error parsing hscript! ' #if hscriptPos + '$name:' + parser.line + ', ' #end + e.message;
			trace(errMsg);

			#if desktop
			Application.current.window.alert(errMsg, "Error on haxe script!");
			#end
		}

		return new FunkinHScript(null, name, additionalVars, doCreateCall);
	}

	public static function fromFile(file:String, ?name:String, ?additionalVars:Map<String, Any>, ?doCreateCall:Bool = true):FunkinHScript
	{
		name = (name == null ? file : name);

		try {
			return _fromString(Paths.getContent(file), name, additionalVars, doCreateCall);
		}
		catch(e:haxe.Exception) {
			var msg = "Error parsing hscript! " + e.message;
			trace(msg);

			#if desktop
			var title = "Error on haxe script!";

			#if (cpp && windows)
			if (Windows.msgBox(msg, title, RETRYCANCEL | ERROR) == RETRY)
				return fromFile(file, name, additionalVars, doCreateCall);
			#else
			Application.current.Windows.alert(msg, title);
			#end
			#end
		}

		return new FunkinHScript(null, name, additionalVars, doCreateCall);
	}

	public function executeCode(source:String):Dynamic
		return run(parseString(source, scriptName));

	////
	var interpreter:Interp = new Interp();

	public function new(?parsed:Expr, ?name:String = "Script", ?additionalVars:Map<String, Any>, ?doCreateCall:Bool = true)
	{
		scriptType = 'hscript';
		scriptName = name;

		set("Std", Std);
		set("Type", Type);
		set("Reflect", Reflect);
		set("Math", Math);
		set("StringTools", StringTools);

		set("StringMap", haxe.ds.StringMap);
		set("ObjectMap", haxe.ds.ObjectMap);
		set("IntMap", haxe.ds.IntMap);
		set("EnumValueMap", haxe.ds.EnumValueMap);

		set("Date", Date);
		set("DateTools", DateTools);
		
		set("getClass", Type.resolveClass);
		set("getEnum", Type.resolveEnum);
		
		set("importClass", importClass);
		set("importEnum", importEnum);
		
		set("script", this);
		set("global", Globals.variables);
		set("FunkinHScript", FunkinHScript);

		setDefaultVars();
		setFlixelVars();
		setVideoVars();
		setFNFVars();

		for (variable => arg in defaultVars)
			set(variable, arg);

		if (additionalVars != null)
		{
			for (key => value in additionalVars)
				set(key, value);
		}

		if (parsed != null){
			run(parsed);
			
			if (doCreateCall)
				call('onCreate');
		}
	}

	private static inline function sowy_trim_redundant_repeated_message_error_pos_shit(message:String, posInfo:haxe.PosInfos):String
	{
		if (message.startsWith(posInfo.fileName)) {
			var sowy = posInfo.fileName + ":" + posInfo.lineNumber + ": ";
			message = message.substr(sowy.length); 
		}

		return message;
	}
	
	public function run(parsed:Expr){
		var returnValue:Dynamic = null;
        try {
			trace('Running haxe script: $scriptName');
			returnValue = interpreter.execute(parsed);
		}
		catch (e:haxe.Exception)
		{
			var posInfo = interpreter.posInfos();
			var message = sowy_trim_redundant_repeated_message_error_pos_shit(e.message, posInfo);
			
			haxe.Log.trace(message, posInfo);
			
			#if (windows && cpp)
			if (YES == Windows.msgBox(haxe.Log.formatOutput(message, posInfo) + '\nStop script?', e.message, ERROR | YESNO))
				stop();
			#end
		}
        return returnValue;
    }

	/**
		Helper function
		Sets a bunch of basic variables for the script depending on the state
	**/
	override function setDefaultVars() {
		super.setDefaultVars();

		var currentState = flixel.FlxG.state;
		
		set("state", currentState);
		set("game", currentState);
		
		if (currentState is PlayState){
			set("getInstance", getInstance);
		}else{
			set("getInstance", @:privateAccess FlxG.get_state);
		}
	}

	private function setFlixelVars() 
	{
		set("FlxG", FlxG);
		set("FlxSprite", FlxSprite);
		set("FlxCamera", FlxCamera);
		set("FlxSound", FlxSound);
		set("FlxMath", flixel.math.FlxMath);
		set("FlxTimer", flixel.util.FlxTimer);
		set("FlxTween", flixel.tweens.FlxTween);
		set("FlxEase", flixel.tweens.FlxEase);
		set("FlxGroup", flixel.group.FlxGroup);
		set("FlxSave", flixel.util.FlxSave); // should probably give it 1 save instead of giving it FlxSave
		set("FlxBar", flixel.ui.FlxBar);

		set("FlxText", flixel.text.FlxText);
		set("FlxTextBorderStyle", flixel.text.FlxText.FlxTextBorderStyle);

		set("FlxRuntimeShader", flixel.addons.display.FlxRuntimeShader);

		set("FlxParticle", flixel.effects.particles.FlxParticle);
		set("FlxTypedEmitter", flixel.effects.particles.FlxEmitter.FlxTypedEmitter);
		set("FlxSkewedSprite", flixel.addons.effects.FlxSkewedSprite);

		// Abstracts
		set("BlendMode", Wrappers.BlendMode);

		set("FlxColor", Wrappers.SowyColor);
		set("FlxPoint", {
			get: FlxPoint.get,
			weak: FlxPoint.weak
		});
		set("FlxTextAlign", Wrappers.FlxTextAlign);
		set("FlxTweenType", Wrappers.FlxTweenType); 
	}

	private function setVideoVars() {
		// TODO: create a compatibility wrapper for the various versions
		// (so you can use any version of hxcodec and use the same versions)

		#if !VIDEOS_ALLOWED
		set("hxcodec", "0");
		set("MP4Handler", null);
		set("MP4Sprite", null);
		#else
		#if (hxCodec >= "3.0.0")
		set("hxcodec", "3.0.0");
		set("MP4Handler", hxcodec.flixel.FlxVideo);
		set("MP4Sprite", hxcodec.flixel.FlxVideoSprite); // idk how hxcodec 3.0.0 works :clueless:
		#elseif (hxCodec >= "2.6.1")
		set("hxcodec", "2.6.1");
		set("MP4Handler", hxcodec.VideoHandler);
		set("MP4Sprite", hxcodec.VideoSprite);
		#elseif (hxCodec == "2.6.0")
		set("hxcodec", "2.6.0");
		set("MP4Handler", VideoHandler);
		set("MP4Sprite", VideoSprite);
		#elseif (hxCodec)
		set("hxcodec", "1.0.0");
		set("MP4Handler", vlc.MP4Handler);
		set("MP4Sprite", vlc.MP4Sprite);
		#else
		set("hxcodec", "0");
		#end
		#if (hxvlc)
		set("hxvlc", "1.0.0");
		set("MP4Handler", hxvlc.flixel.FlxVideo);
		set("MP4Sprite", hxvlc.flixel.FlxVideoSprite);
		#else
		set("hxvlc", "0");
		#end
		#end	
	}

	private function setFNFVars() {
		// FNF-specific things
		set("controls", PlayerSettings.player1.controls);
		set("get_controls", () -> return PlayerSettings.player1.controls);
		
		set("Paths", funkin.Paths);
		set("Conductor", funkin.Conductor);
		set("ClientPrefs", funkin.ClientPrefs);
		set("CoolUtil", funkin.CoolUtil);

		set("newShader", Paths.getShader);

		set("PlayState", PlayState);
		set("MusicBeatState", MusicBeatState);
		set("MusicBeatSubstate", MusicBeatSubstate);
		set("GameOverSubstate", funkin.states.GameOverSubstate);
		set("Song", funkin.data.Song);
		set("BGSprite", funkin.objects.BGSprite);
		set("RatingSprite", RatingSprite);

		set("Note", funkin.objects.Note);
		set("NoteObject", funkin.objects.NoteObject);
		set("NoteSplash", funkin.objects.NoteSplash);
		set("StrumNote", funkin.objects.StrumNote);
		set("PlayField", funkin.objects.playfields.PlayField);
		set("NoteField", funkin.objects.playfields.NoteField);

		set("ProxyField", funkin.objects.proxies.ProxyField);
		set("ProxySprite", funkin.objects.proxies.ProxySprite);

		set("FlxSprite3D", funkin.objects.FlxSprite3D);

		set("AttachedSprite", funkin.objects.AttachedSprite);
		set("AttachedText", funkin.objects.AttachedText);

		set("Character", funkin.objects.Character);
		set("HealthIcon", funkin.objects.hud.HealthIcon);

		set("Wife3", funkin.data.JudgmentManager.Wife3);
		set("JudgmentManager", funkin.data.JudgmentManager);
		set("Judgement", Wrappers.Judgment);

		set("ModManager", funkin.modchart.ModManager);
		set("Modifier", funkin.modchart.Modifier);
		set("SubModifier", funkin.modchart.SubModifier);
		set("NoteModifier", funkin.modchart.NoteModifier);
		set("EventTimeline", funkin.modchart.EventTimeline);
		set("StepCallbackEvent", funkin.modchart.events.StepCallbackEvent);
		set("CallbackEvent", funkin.modchart.events.CallbackEvent);
		set("ModEvent", funkin.modchart.events.ModEvent);
		set("EaseEvent", funkin.modchart.events.EaseEvent);
		set("SetEvent", funkin.modchart.events.SetEvent);

		set("HScriptedHUD", funkin.objects.hud.HScriptedHUD);
		set("HScriptModifier", funkin.modchart.HScriptModifier);

		set("HScriptedState", funkin.states.scripting.HScriptedState);
		set("HScriptedSubstate", funkin.states.scripting.HScriptedSubstate);
	} 

	function importClass(className:String)
	{
		// importClass("flixel.util.FlxSort") should give you FlxSort.byValues, etc
		// whereas importClass("scripts.Globals.*") should give you Function_Stop, Function_Continue, etc
		// i would LIKE to do like.. flixel.util.* but idk if I can get everything in a namespace
		var classSplit:Array<String> = className.split(".");
		var daClassName = classSplit[classSplit.length - 1]; // last one

		if (daClassName == '*')
		{
			var daClass = Type.resolveClass(className);

			while (classSplit.length > 0 && daClass == null)
			{
				daClassName = classSplit.pop();
				daClass = Type.resolveClass(classSplit.join("."));
				if (daClass != null)
					break;
			}
			if (daClass != null)
			{
				for (field in Reflect.fields(daClass))
					set(field, Reflect.field(daClass, field));
			}
			else
			{
				FlxG.log.error('Could not import class $className');
			}
		}
		else
		{
			set(daClassName, Type.resolveClass(className));
		}
	}

	function importEnum(enumName:String)
	{
		// same as importClass, but for enums
		// and it cant have enum.*;
		var splitted:Array<String> = enumName.split(".");
		var daEnum = Type.resolveEnum(enumName);
		if (daEnum != null)
			set(splitted.pop(), daEnum);
	}	

	override public function stop()
	{
		//trace('stopping $scriptName');

		// idk if there's really a stop function or anythin for hscript so
		if (interpreter != null && interpreter.variables != null)
			interpreter.variables.clear();

		interpreter = null;
	}

	override public function get(varName:String):Dynamic
	{
		return (interpreter == null) ? null : interpreter.variables.get(varName);
	}

	override public function set(varName:String, value:Dynamic):Void
	{
		if (interpreter != null)
			interpreter.variables.set(varName, value);
	}

	public function exists(varName:String):Bool
	{
		return (interpreter == null) ? false : interpreter.variables.exists(varName);
	}

	override public function call(func:String, ?parameters:Array<Dynamic>, ?extraVars:Map<String, Dynamic>):Dynamic
	{
        var returnValue:Dynamic = null;
        
        try{
		    returnValue = executeFunc(func, parameters, null, extraVars); // I AM SICK OF THIS CASUING CRASHES
        }catch(e:haxe.Exception){
			trace('HScript error (${scriptName}): ${e.message}');
        }
		return returnValue == null ? Function_Continue : returnValue;
	}

	/**
	 * Calls a function within the script
	**/
	public function executeFunc(func:String, ?parameters:Array<Dynamic>, ?parentObject:Any, ?extraVars:Map<String, Dynamic>):Dynamic
	{
		var daFunc = get(func);

		if (!Reflect.isFunction(daFunc))
			return null;

		if (parameters == null)
			parameters = [];

		if (parentObject != null){
			if (extraVars == null) extraVars = [];
			extraVars.set("this", parentObject);
		}

		var prevVals:Map<String, Dynamic> = null;

		if (extraVars != null) {
			prevVals = [];

			for (key in extraVars.keys()) {
				prevVals.set(key, get(key)); // Store original values of variables that are being overwritten
				set(key, extraVars.get(key));
			}
		}

		var returnVal:Dynamic = null;
		try {
			returnVal = Reflect.callMethod(parentObject, daFunc, parameters);
		}
		catch (e:haxe.Exception)
		{
			var posInfo = interpreter.posInfos();
			var message = sowy_trim_redundant_repeated_message_error_pos_shit(e.message, posInfo);

			Main.print('$scriptName: Error executing $func(${parameters.join(', ')}): ' + haxe.Log.formatOutput(message, posInfo));
		}

		if (prevVals != null){
			for (key => val in prevVals)
				set(key, val);		
		}

		return returnVal;
	}
}