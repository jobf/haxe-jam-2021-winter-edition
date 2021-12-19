class TitleState extends BaseState
{
	var snowHead:Snowball;
	var snowBody:SnowBalls;
	var snowTarget:FlxObject;
	var bg:FlxBackdrop;
	var rocks:ObstaclesGround;
	var birds:ObstaclesAir;
	var points:Collectibles;
	var lowObstaclesY:Int;
	var midObstaclesY:Int;
	var highObstaclesY:Int;
	var isPlayInProgress:Bool = true;
	var fakeVelocity:Float = 10;

	override public function create()
	{
		super.create();
		FlxG.debugger.drawDebug = true;
		layers.bgShutter.alpha = 1;
		bg = new FlxBackdrop("assets/images/snow-bg-896x504.png");
		bg.alpha = 0;

		layers.bg.add(bg);
		var title = new FlxSprite("assets/images/title-500x242.png");
		title.screenCenter();
		title.y -= 100;
		title.fadeIn(1.2, true, oncomplete ->
		{
			bg.fadeIn(0.8, oncomplete ->
			{
				var help = glyphs.getText("press enter to start");
				help.screenCenter();
				help.y = FlxG.height - help.height * 3;
				help.fadeIn(0.3, true, oncomplete ->
				{
					help.flicker(0, 0.2);
				});
				layers.overlay.add(help);
			});
			layers.bgShutter.fadeOut();
		});
		layers.overlay.add(title);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (FlxG.keys.justPressed.ENTER)
		{
			FlxG.switchState(new PlayState());
		}
	}
}
