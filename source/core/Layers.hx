package core;

class Layers extends FlxGroup
{
	public var bg:FlxSpriteGroup;
	public var bgShutter(default, null):FlxSprite;
	public var entities:FlxSpriteGroup;
	public var foreground:FlxSpriteGroup;
	public var foregroundDial:FlxSpriteGroup;
	public var shutter(default, null):FlxSprite;
	public var overlay:FlxSpriteGroup;
	public var overOverlay:FlxSpriteGroup;

	public function new()
	{
		super();

		bg = new FlxSpriteGroup();
		add(bg);
		bgShutter = new FlxSprite();
		bgShutter.makeGraphic(FlxG.width, FlxG.height);
		bgShutter.alpha = 0;

		entities = new FlxSpriteGroup();
		add(entities);

		foreground = new FlxSpriteGroup();
		foreground.scrollFactor.x = 0;

		add(foreground);

		foregroundDial = new FlxSpriteGroup();
		foregroundDial.scrollFactor.x = 0;
		add(foregroundDial);

		shutter = new FlxSprite();
		shutter.makeGraphic(FlxG.width, FlxG.height);
		shutter.alpha = 0;
		add(shutter);

		overlay = new FlxSpriteGroup();
		add(overlay);

		overOverlay = new FlxSpriteGroup();
		add(overOverlay);
	}
}
