package core;

class BaseState extends FlxState
{
	var layers:Layers;

	public static var delays = new DelayFactory();

	private function new()
	{
		super();
	}

	override public function create()
	{
		super.create();
		layers = new Layers();
		add(layers);
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
