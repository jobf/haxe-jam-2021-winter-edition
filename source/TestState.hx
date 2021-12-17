package;

class Test extends BaseState
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
		bgColor = FlxColor.WHITE;
		bg = new FlxBackdrop("assets/images/bg.png");
		bg.screenCenter();
		layers.bg.add(bg);

		snowBody = new SnowBalls(24, FlxG.height - 86 * 3, Data.level.maxVelocity);
		snowTarget = new FlxObject(snowBody.base.x, FlxG.height + 100);
		snowTarget.maxVelocity.x = bg.maxVelocity.x;
		add(snowTarget);
		snowBody.addBallsTo(layers.entities);

		lowObstaclesY = Std.int(snowBody.base.y + (snowBody.base.height - 10));
		midObstaclesY = lowObstaclesY - 100; // Std.int(snowBody.torso.y - 35);

		rocks = new ObstaclesGround();
		for (r in rocks.getTests(140, 390))
		{
			layers.entities.add(r);
		}
		birds = new ObstaclesAir();
		for (b in birds.getTests(140, 50))
		{
			layers.entities.add(b);
		}

		points = new Collectibles();
		for (p in points.getTests(140, 140))
		{
			layers.entities.add(p);
		}

		// layers.overlay.add(new HUD(Data.level));
	}

	var humanize = 1.4;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		snowBody.update(elapsed);
		if (isPlayInProgress) {}

		if (FlxG.keys.justReleased.B)
		{
			@:privateAccess
			var b = snowBody.balls[0];
			@:privateAccess
			b.remove();
			snowBody.removeBall(b);
		}
		if (FlxG.keys.justPressed.UP)
		{
			snowBody.jump();
		}
		if (FlxG.keys.justPressed.DOWN)
		{
			snowBody.pop();
		}
		if (FlxG.keys.justReleased.T)
		{
			@:privateAccess
			var b = snowBody.balls[1];
			@:privateAccess
			b.remove();
			snowBody.removeBall(b);
		}
		if (FlxG.keys.justPressed.L)
		{
			// trace('\n\n\nSnowBalls x y [${snowBody.base.x}, ${snowBody.base.y}] vel ${snowBody.base.velocity} acc ${snowBody.base.acceleration}\n bg velocity ${bg.velocity} bg pos ${bg.x}, ${bg.y}\n\n\n');

			snowBody.log();
		}
		if (FlxG.keys.justReleased.RIGHT)
		{
			fakeVelocity += 10;
			snowBody.base.angularVelocity = fakeVelocity * 3.1;
		}
		if (FlxG.keys.justReleased.LEFT)
		{
			fakeVelocity -= 10;
			snowBody.base.angularVelocity = fakeVelocity * 3.1;
		}
	}

	function spawnRock()
	{
		var rock = rocks.get(FlxG.width, lowObstaclesY);
		layers.bg.add(rock);
	}

	function spawnBird()
	{
		var bird = birds.get(FlxG.width, midObstaclesY);
		layers.foreground.add(bird);
	}

	function spawnPoints()
	{
		var points = points.get(FlxG.width, midObstaclesY);
		layers.foreground.add(points);
	}
}
