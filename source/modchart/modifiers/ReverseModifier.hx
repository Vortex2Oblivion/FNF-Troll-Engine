package modchart.modifiers;

import modchart.Modifier.ModifierOrder;
import modchart.*;
import math.*;

import flixel.FlxG;
import flixel.FlxSprite;
import playfields.NoteField;

class ReverseModifier extends NoteModifier 
{
	inline function lerp(a:Float, b:Float, c:Float) 
		return a + (b - a) * c;

	override function getOrder() 
		return REVERSE;
	override function getName() 
		return 'reverse';

	override function shouldExecute(player:Int, val:Float)
		return true;
	override function ignoreUpdateNote()
		return false;

    public function getReverseValue(dir:Int, player:Int){
        //var receptors = modMgr.receptors[player]; // TODO: rewrite for playfield system
		// but for now we can just comment it out and set kNum to 4 since rn the key count never goes > 4
        var kNum = 4;
        var val:Float = 0;
        if(dir>=kNum/2)
            val += getSubmodValue("split" ,player);

        if((dir%2)==1)
            val += getSubmodValue("alternate" ,player);

        var first = kNum/4;
        var last = kNum-1-first;

        if(dir>=first && dir<=last)
            val += getSubmodValue("cross" ,player);

        val += getValue(player) + getSubmodValue("reverse" + Std.string(dir), player);


        if(getSubmodValue("unboundedReverse",player)==0){
            val %=2;
            if(val>1)val=2-val;
        }

       	if(ClientPrefs.downScroll)
            val = 1 - val;

        return val;
    }

	private inline function getCenterValue(player:Int){
		var centerPercent = getSubmodValue("centered", player);
		#if tgt
		return (ClientPrefs.midScroll) ? 1 - centerPercent : centerPercent;
		#else
		return centerPercent;
		#end
	}

	override function getPos(visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite, field:NoteField)
	{
		var swagOffset = Note.swagWidth / 2 + 45;
		var reversePerc = getReverseValue(data, player);
		var shift = lerp(swagOffset, FlxG.height - swagOffset, reversePerc);
		
		var centerPercent = getCenterValue(player);		
		shift = lerp(shift, (FlxG.height / 2), centerPercent);
		
		pos.y = shift + lerp(visualDiff, -visualDiff, reversePerc);

		if ((obj is Note))
		{
			var n:Note = cast obj;
			pos.y += n.typeOffsetY;
		}
		if ((obj is NoteObject))
		{
			var nO:NoteObject = cast obj;
			pos.y += nO.offsetY;
		}

		return pos;
	}

    override function getSubmods(){
        var subMods:Array<String> = ["cross", "split", "alternate", "centered", "unboundedReverse"];

		for (i in 0...4){
            subMods.push('reverse${i}');
        }

        return subMods;
    }
}
