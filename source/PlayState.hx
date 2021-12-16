package;

class PlayState extends BaseState
{
	var snowHead:Snowball;
	var snowBody:SnowBalls;
	var snowTarget:FlxObject;
	var bg:FlxBackdrop;
	var rocks:ObstaclesGround;
	var birds:ObstaclesAir;
	var points:Collectibles;
	var rocksDelay:DelayDistance;
	var birdsDelay:DelayDistance;
	var pointsDelay:DelayDistance;
	var accelerationDelay:Delay;
	var level:LevelStats;
	var lowObstaclesY:Int;
	var midObstaclesY:Int;
	var highObstaclesY:Int;
	var hasReachedDistance:Bool;

	override public function create()
	{
		super.create();
		FlxG.debugger.drawDebug = true;
		// FlxG.debugger.visible = true;
		// FlxG.debugger.
		hasReachedDistance = false;
		bgColor = FlxColor.WHITE;
		level = Data.level;
		bg = new FlxBackdrop("assets/images/bg.png");
		bg.screenCenter();
		layers.bg.add(bg);
		bg.maxVelocity.x = level.maxVelocity * level.bgSpeedFactor;

		snowBody = new SnowBalls(128, FlxG.height - 200, level.maxVelocity);
		snowTarget = new FlxObject(snowBody.torso.x, FlxG.height + 100);
		snowTarget.maxVelocity.x = bg.maxVelocity.x;
		add(snowTarget);

		layers.entities.add(snowBody.base);
		layers.entities.add(snowBody.torso);
		layers.entities.add(snowBody.head);

		lowObstaclesY = Std.int(snowBody.base.y + (snowBody.base.height - 10));
		midObstaclesY = Std.int(snowBody.torso.y - 35);

		rocks = new ObstaclesGround();
		rocksDelay = {
			stepTravelled: 500, // new rock every x pixels
			lastTravelled: 0,
			isInProgress: true,
			isResetAuto: true,
			onReady: spawnRock
		}

		birds = new ObstaclesAir();
		birdsDelay = {
			stepTravelled: 1000, // new bird every x pixels
			lastTravelled: 0,
			isInProgress: true,
			isResetAuto: true,
			onReady: spawnBird
		}

		points = new Collectibles();
		pointsDelay = {
			stepTravelled: 400, // new bird every x pixels
			lastTravelled: 0,
			isInProgress: true,
			isResetAuto: true,
			onReady: spawnPoints
		}

		accelerationDelay = BaseState.delays.Default(0.06, checkAcceleration, true, true);

		layers.overlay.add(new HUD(level));
	}

	var humanize = 1.4;

	public function getTargetDistance():Float
	{
		return (snowTarget.x / (level.levelLength * humanize)) * 100;
	}

	public function getActualDistance():Float
	{
		return ((bg.x * -1) / level.levelLength) * 100;
	}

	function checkAcceleration()
	{
		// update direction based on key input
		var nextDirection = snowBody.shouldAccelerate();
		snowTarget.velocity.x += (level.snowManVelocityIncrement);
		if (nextDirection != 0)
		{
			var changeVelocityBy = level.snowManVelocityIncrement * nextDirection;
			// only change if a direction was returned, otherwise leave at previous speed
			snowBody.increaseVelocity(changeVelocityBy);
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

			points.collisionGroup.forEachAlive((p) ->
			{
				if (p.x < -25)
				{
					p.kill();
					p.visible = false;
				}
				else
				{
					p.velocity.x = bg.velocity.x * 1.2;
				}
			});
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		snowBody.update(elapsed);
		hasReachedDistance = bg.x * -1 > level.levelLength;
		if (hasReachedDistance)
		{
			progressToNextLevel();
		}
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

		rocksDelay.wait(bg.x * -1);
		birdsDelay.wait(bg.x * -1);
		pointsDelay.wait(bg.x * -1);

		if (FlxG.keys.justReleased.B)
		{
			@:privateAccess
			var b = snowBody.balls[0];
			@:privateAccess
			b.remove();
			snowBody.removeBall(b);
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
	}

	function progressToNextLevel()
	{
		Data.level.levelLength += 1000;
		Data.level.maxVelocity += 10;
		Data.level.bgSpeedFactor += 0.7;
		Data.level.snowManVelocityIncrement = Data.level.bgSpeedFactor;
		FlxG.resetState();
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

	inline function handleCollisions()
	{
		FlxG.overlap(snowBody.base, rocks.collisionGroup, (snow, rock:Rock) ->
		{
			if (!rock.isHit)
			{
				var bump = switch (rock.key)
				{
					case 0: -1;
					case _: rock.key * 100;
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
				if (!snow.surviveCollision())
				{
					snowBody.removeBall(snow);
				};
			}
		});

		FlxG.overlap(snowBody.collisionGroup, points.collisionGroup, (snow:Snowball, points:Collectible) ->
		{
			if (!points.isHit)
			{
				points.collide();
			}
		});
	}
}
