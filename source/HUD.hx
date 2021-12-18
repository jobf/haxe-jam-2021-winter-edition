class HUD extends FlxSpriteGroup
{
	public function new(level:LevelStats, margin:Float = 60, ?barWidth:Int, barHeight:Int = 60)
	{
		super();
		var state:PlayState = cast FlxG.state;
		barWidth = barWidth == null ? Std.int(FlxG.width) : barWidth;
		targetMeter = new DrawnBar(0, 0, LEFT_TO_RIGHT, barWidth, barHeight, () ->
		{
			return state.getTargetDistance();
		});
		add(targetMeter);
		// carrot mask
		targetMeter.mask.animation.frameIndex = 1;
		add(targetMeter.mask);

		progressMeter = new DrawnBar(0, margin + (margin * 0.25), LEFT_TO_RIGHT, barWidth, barHeight, () ->
		{
			return state.getActualDistance();
		});
		add(progressMeter);
		// snow mask
		progressMeter.mask.animation.frameIndex = 2;
		add(progressMeter.mask);

		slowMoMeter = new IceBar(() ->
		{
			return state.getSlowMoDelayLevel();
		});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		targetMeter.update(elapsed);
		progressMeter.update(elapsed);
		slowMoMeter.update(elapsed);
	}

	var targetMeter:DrawnBar;

	var progressMeter:DrawnBar;

	public var slowMoMeter(default, null):IceBar;
}

class IceBar extends CallbackFlxBar
{
	public function new(x:Float = 0, y:Float = 0, ?direction:FlxBarFillDirection, width:Int = 896, height:Int = 504, getValue:() -> Float, min:Float = 0,
			max:Float = 100, showBorder:Bool = false)
	{
		super(x, y, HORIZONTAL_OUTSIDE_IN, width, height, getValue, min, max);
		createFilledBar(0x554370cc, 0x994370cc, showBorder);
	}
}

class DrawnBar extends CallbackFlxBar
{
	public var mask(default, null):FlxSprite;

	public function new(x:Float = 0, y:Float = 0, ?direction:FlxBarFillDirection, width:Int = 896, height:Int = 60, getValue:() -> Float, min:Float = 0,
			max:Float = 100, showBorder:Bool = false)
	{
		super(x, y, LEFT_TO_RIGHT, width, height, getValue, min, max);

		// remake the bar with no color; default green is hardcoded in the constructor...
		createFilledBar(FlxColor.TRANSPARENT, FlxColor.TRANSPARENT, showBorder);

		var asset = new FramesHelper("assets/images/progress-896x60-1x3.png", 896, 1, 3, 60);
		frames = asset.getFrames();
		animation.frameIndex = 0;

		mask = new FlxSprite(x, y);
		mask.frames = asset.getFrames();
	}

	override public function draw():Void
	{
		super.draw();

		if (!FlxG.renderTile)
			return;

		if (alpha == 0)
			return;

		if (percent > 0)
		{
			mask.x = 896 * (percent / 100);
		}
	}
}
