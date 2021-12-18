package core;

import HUD.Messages;

class BaseState extends FlxState
{
	var layers:Layers;
	var glyphs:Glyphs;
	var messages:Messages;

	public static var delays = new DelayFactory();

	private function new()
	{
		super();
	}

	override public function create()
	{
		super.create();
		bgColor = 0xffeef2ff;
		layers = new Layers();
		messages = new Messages();
		add(layers);
		glyphs = new Glyphs("assets/fonts/ice-and-snow-104.png",
			" !#$%&'()*+,-.0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmnopqrstuvwxyz{|}~§¶—•∙", 104);
		layers.overlay.add(new FlxSprite("assets/images/overlay-frame-896x504.png"));
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (FlxG.keys.justPressed.R)
		{
			FlxG.resetState();
		}
		if (FlxG.keys.justPressed.PLUS)
		{
			FlxG.camera.targetOffset.y += 20;
			trace(FlxG.camera.targetOffset);
		}
		if (FlxG.keys.justPressed.MINUS)
		{
			FlxG.camera.targetOffset.y -= 20;
			trace(FlxG.camera.targetOffset);
		}
	}
}
