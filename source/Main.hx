package;

import flixel.FlxGame;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		Data.init();
		final skipSplash = true;
		addChild(new FlxGame(0, 0, TitleState, 1, 60, 60, skipSplash));
		FlxG.mouse.useSystemCursor = true;
	}
}
