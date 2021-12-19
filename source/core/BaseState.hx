package core;

import HUD.Messages;

class BaseState extends FlxState
{
	var layers:Layers;
	var glyphs:Glyphs;
	var messages:Messages;

	public static var delays = new DelayFactory();

	override public function create()
	{
		super.create();
		bgColor = 0xffeef2ff;
		layers = new Layers();
		messages = new Messages();
		add(layers);
		glyphs = new Glyphs("assets/fonts/comicblue-60.png", " !#$%&'()*+,-.0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmnopqrstuvwxyz{|}£",
			60);
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

	function showText(chars:String, onfadecomplete:FlxBitmapText->Void)
	{
		var text = glyphs.getText(chars);
		text.screenCenter();
		text.y = FlxG.height - text.height * 3;
		text.fadeIn(0.3, true, oncomplete ->
		{
			onfadecomplete(text);
		});
		layers.overlay.add(text);
	}
}
