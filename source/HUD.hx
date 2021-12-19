class HUD extends FlxSpriteGroup
{
	public function new(level:LevelStats, margin:Float = 45, ?barWidth:Int, barHeight:Int = 45)
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
		// slowMoMeter.update(elapsed);
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

	public function new(x:Float = 0, y:Float = 0, ?direction:FlxBarFillDirection, width:Int = 896, height:Int = 45, getValue:() -> Float, min:Float = 0,
			max:Float = 100, showBorder:Bool = false)
	{
		super(x, y, LEFT_TO_RIGHT, width, height, getValue, min, max);

		// remake the bar with no color; default green is hardcoded in the constructor...
		createFilledBar(FlxColor.TRANSPARENT, FlxColor.TRANSPARENT, showBorder);

		var asset = new FramesHelper("assets/images/progress-896x45-1x3.png", 896, 1, 3, 45);
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
			mask.x = (896 * (percent / 100)) - 100;
		}
	}
}

@:enum abstract Message(Int) from Int to Int
{
	var GOFASTER;
	var SLOWDOWN;
	var TOOSLOW;
	var FROZENTIME;
	var HIGHSCORE;
	var TRYAGAIN;
	var RESTART;
	var GAMEOVER;
	var QUIT;
	var WIN;
}

class Messages
{
	var asset:FramesHelper;

	public function new()
	{
		asset = new FramesHelper("assets/images/messages-420x70-1x10.png", 420, 1, 10, 70);
	}

	public function get(x:Int, y:Int, message:Message):FlxSprite
	{
		var s = new FlxSprite(x, y);
		s.frames = asset.getFrames();
		s.animation.frameIndex = message;
		return s;
	}

	public function show(m:Message, group:FlxSpriteGroup, persistMessage:Bool = false, onComplete:Void->Void = null)
	{
		final tweenDuration = 0.25;
		var x = Std.int((FlxG.width * 0.5) - (asset.frameSizeW * 0.5));
		var y = Std.int((FlxG.height * 0.5) - (asset.frameSizeH * 0.5));
		var s = get(x, 1000, m);
		group.add(s);
		FlxTween.tween(s, {y: y}, tweenDuration, {
			ease: FlxEase.sineIn,
			onComplete: tween ->
			{
				if (!persistMessage)
				{
					FlxTween.tween(s, {y: -1000}, tweenDuration, {
						startDelay: 1.0,
						ease: FlxEase.sineOut,
						onComplete: tween ->
						{
							if (onComplete != null)
							{
								onComplete();
							}
							s.kill();
						}
					});
				}
				else
				{
					if (onComplete != null)
					{
						onComplete();
					}
				}
			}
		});
	}
}

class Dial extends FlxSpriteGroup
{
	var asset:FramesHelper;
	var meter:FlxSprite;
	var casing:FlxSprite;

	public function new()
	{
		super();
		asset = new FramesHelper("assets/images/dial-100x100-2x1.png", 100, 2, 1);
		meter = new FlxSprite();
		meter.frames = asset.getFrames();
		meter.animation.frameIndex = 0;
		add(meter);
		casing = new FlxSprite();
		casing.frames = asset.getFrames();
		casing.animation.frameIndex = 1;
		add(casing);
	}

	public function updateVelocity(velocity:Float, maxVelocity:Float)
	{
		final maxRotation = 180;
		var percentage = velocity / maxVelocity;
		var rotation = maxRotation * percentage;
		meter.angle = rotation;
	}
}
