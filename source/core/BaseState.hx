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
		#if debug
		if (FlxG.keys.justPressed.R)
		{
			FlxG.resetState();
		}
		#end
	}

	function showText(chars:String, onfadecomplete:FlxBitmapText->Void, overrideY:Float = 0, textFadeIn:Float = 0.3)
	{
		var text = glyphs.getText(chars);
		text.screenCenter();
		text.y = (FlxG.height - text.height * 3) + overrideY;
		text.fadeIn(textFadeIn, true, oncomplete ->
		{
			onfadecomplete(text);
		});
		layers.overlay.add(text);
	}
}
