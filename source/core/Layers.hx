package core;

class Layers extends FlxGroup
{
	public var bg:FlxSpriteGroup;
	public var entities:FlxSpriteGroup;
	public var foreground:FlxSpriteGroup;
	public var overlay:FlxSpriteGroup;

	public function new()
	{
		super();

		bg = new FlxSpriteGroup();
		add(bg);

		entities = new FlxSpriteGroup();
		add(entities);

		foreground = new FlxSpriteGroup();
		foreground.scrollFactor.x = 0;
		// foreground.scrollFactor.y = 0;

		add(foreground);

		overlay = new FlxSpriteGroup();
		add(overlay);
	}
}
