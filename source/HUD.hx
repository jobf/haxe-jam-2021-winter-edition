class HUD extends FlxSpriteGroup
{
	public function new(level:LevelStats, margin:Float = 20, ?barWidth:Int, barHeight:Int = 10)
	{
		super();
		var state:PlayState = cast FlxG.state;
		barWidth = barWidth == null ? Std.int(FlxG.width - (margin * 2)) : barWidth;
		targetMeter = new CallbackFlxBar(margin, margin, LEFT_TO_RIGHT, barWidth, barHeight, () ->
		{
			return state.getTargetDistance();
		});
		add(targetMeter);

		progressMeter = new CallbackFlxBar(margin, margin * 3, LEFT_TO_RIGHT, barWidth, barHeight, () ->
		{
			return state.getActualDistance();
		});
		add(progressMeter);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		targetMeter.update(elapsed);
		progressMeter.update(elapsed);
	}

	var targetMeter:FlxBar;

	var progressMeter:FlxBar;
}
