package;

class PlayState extends BaseState
{
	var snowHead:Snowball;
	var snowBody:SnowBalls;
	var bg:FlxBackdrop;
	var rocks:Rocks;
	var birds:Birds;
	var rocksDelay:Delay;
	var birdsDelay:Delay;
	var accelerationDelay:Delay;
	var level:LevelStats;
	var lowObstaclesY:Int;
	var midObstaclesY:Int;
	var highObstaclesY:Int;

	override public function create()
	{
		super.create();
		bgColor = FlxColor.WHITE;
		level = Data.level;
		bg = new FlxBackdrop("assets/images/bg.png");
		bg.screenCenter();
		layers.bg.add(bg);
		bg.maxVelocity.x = level.maxVelocity * level.bgSpeedFactor;
		snowBody = new SnowBalls(128, FlxG.height - 200, level.maxVelocity);

		layers.entities.add(snowBody.base);
		layers.entities.add(snowBody.torso);
		layers.entities.add(snowBody.head);

		lowObstaclesY = Std.int(snowBody.base.y + (snowBody.base.height - 10));
		midObstaclesY = Std.int(snowBody.torso.y - 35);

		rocks = new Rocks();
		rocksDelay = BaseState.delays.Default(2, spawnRock, true, true);
		birds = new Birds();
		birdsDelay = BaseState.delays.Default(4, spawnBird, true, true);
		accelerationDelay = BaseState.delays.Default(0.06, checkAcceleration, true, true);
	}

	function checkAcceleration()
	{
		// update direction based on key input
		var nextDirection = snowBody.shouldAccelerate();
		if (nextDirection != 0)
		{
			// only change if a direction was returned, otherwise leave at previous speed
			snowBody.changeHorizontalSpeed(level.snowManVelocityIncrement * nextDirection);
			// trace('new snowBody.velocity.x ${snowBody.velocity.x}');
		}
		// if player is moving, back drop and other entities should be
		if (snowBody.base.velocity.x > 0)
		{
			bg.velocity.x = (snowBody.base.velocity.x * level.bgSpeedFactor) * -1;
			rocks.collisionGroup.forEachAlive((r) ->
			{
				if (r.x < -25)
				{
					r.kill();
					r.visible = false;
				}
				else
				{
					r.velocity.x = bg.velocity.x;
				}
			});

			birds.collisionGroup.forEachAlive((b) ->
			{
				if (b.x < -25)
				{
					b.kill();
					b.visible = false;
				}
				else
				{
					b.velocity.x = bg.velocity.x * 1.2;
				}
			});
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		snowBody.update(elapsed);
		if (FlxG.keys.justPressed.UP)
		{
			snowBody.jump();
		}
		if (FlxG.keys.justPressed.DOWN)
		{
			snowBody.pop();
		}
		handleCollisions();
		accelerationDelay.wait(elapsed);
		rocksDelay.wait(elapsed);
		birdsDelay.wait(elapsed);

		if (FlxG.keys.justPressed.L)
		{
			trace('\n\n\nSnowBalls x y [${snowBody.base.x}, ${snowBody.base.y}] vel ${snowBody.base.velocity} acc ${snowBody.base.acceleration}\n bg velocity ${bg.velocity}\n\n\n');

			snowBody.log();
		}
	}

	function spawnRock()
	{
		var rockWeight = FlxG.random.int(0, 2);

		var rock = rocks.getRock(FlxG.width, lowObstaclesY, rockWeight);
		// trace('rock x,y ${rock.x},${rock.y}');
		// rock.velocity.x = bg.velocity.x;
		layers.bg.add(rock);
	}

	function spawnBird()
	{
		var bird = birds.get(FlxG.width, midObstaclesY);
		// trace('rock x,y ${rock.x},${rock.y}');

		layers.foreground.add(bird);
	}

	inline function handleCollisions()
	{
		FlxG.overlap(snowBody.base, rocks.collisionGroup, (snow, rock:Rock) ->
		{
			if (!rock.isHit)
			{
				var bump = switch (rock.weight)
				{
					case _: rock.weight * 100;
				};
				rock.collide();
				snowBody.jump(bump);
			}
		});

		FlxG.overlap(snowBody.collisionGroup, birds.collisionGroup, (snow:Snowball, bird:Obstacle) ->
		{
			if (!bird.isHit)
			{
				bird.collide();
				snow.collide();
			}
		});
	}
}
