package;

import TestState.Test;
import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		#if debug
		addChild(new FlxGame(0, 0, Test));
		#else
		addChild(new FlxGame(0, 0, PlayState));
		#end
	}
}
