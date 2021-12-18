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
	var slowMoDelay:Delay;
	var level:LevelStats;
	var lowObstaclesY:Int;
	var midObstaclesY:Int;
	var highObstaclesY:Int;
	var hasReachedDistance:Bool;
	var isPlayInProgress:Bool = false;
	var isSlowMotion:Bool = false;
	var slowMoFactor:Float = 0.9;

	override public function create()
	{
		super.create();
		FlxG.debugger.drawDebug = true;
		hasReachedDistance = false;
		bgColor = FlxColor.WHITE;
		level = Data.level;
		bg = new FlxBackdrop("assets/images/snow-bg-896x504.png");
		layers.bg.add(bg);
		bg.maxVelocity.x = level.maxVelocity * level.bgSpeedFactor;

		snowBody = new SnowBalls(96, 320, level.maxVelocity);
		snowTarget = new FlxObject(snowBody.base.x, FlxG.height + 100);
		snowTarget.maxVelocity.x = bg.maxVelocity.x;
		add(snowTarget);
		snowBody.addBallsTo(layers.entities);

		lowObstaclesY = Std.int(snowBody.base.y + (snowBody.base.height - 10));
		midObstaclesY = Std.int(lowObstaclesY - (FlxG.height * 0.3)); // Std.int(snowBody.torso.y - 35);

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
			stepTravelled: 500, // new gift every x pixels
			lastTravelled: 0,
			isInProgress: true,
			isResetAuto: true,
			onReady: spawnPoints
		}

		accelerationDelay = BaseState.delays.Default(0.06, handleMovement, true, true);
		slowMoDelay = BaseState.delays.Default(1.0, resetSlowMo, false, false);
		layers.overlay.add(new HUD(level));

		startIntro();
	}

	var humanize = 1.4;

	function startIntro()
	{
		var texts = [for (s in ["GET", "READY", "GO !!",]) glyphs.getText(s)];
		var duration = 1;
		for (i => t in texts)
		{
			t.screenCenter();
			var endX = t.x;
			t.x = -1000;
			layers.overlay.add(t);
			var tween = FlxTween.tween(t, {x: endX}, duration);
			tween.onComplete = (_) ->
			{
				FlxTween.tween(t, {y: 1000}, 1, {
					onComplete: (c) ->
					{
						t.kill();
						if (i == texts.length - 1)
						{
							isPlayInProgress = true;
						}
					}
				});
			}
			duration += 1;
		}
	}

	public function getTargetDistance():Float
	{
		return (snowTarget.x / (level.levelLength * humanize)) * 100;
	}

	public function getActualDistance():Float
	{
		return ((bg.x * -1) / level.levelLength) * 100;
	}

	public function getSlowMoDelayLevel():Float
	{
		return (slowMoDelay.currentTime / slowMoDelay.duration) * 100;
	}

	inline function shouldAccelerate():Int
	{
		var accelerationChanged = 0;

		if (FlxG.keys.pressed.RIGHT)
		{
			accelerationChanged = 1;
		}
		if (FlxG.keys.pressed.LEFT)
		{
			accelerationChanged = -1;
		}

		return accelerationChanged;
	}

	function handleMovement()
	{
		// update direction based on key input
		var nextDirection = shouldAccelerate();

		// always speed up target, we are racing it
		snowTarget.velocity.x += (level.snowManVelocityIncrement);

		if (!isSlowMotion && nextDirection > 0)
		{
			var changeVelocityBy = level.snowManVelocityIncrement * nextDirection;
			snowBody.changeVelocityBy(changeVelocityBy);
		}

		// if player is moving, back drop and other entities should be
		if (snowBody.base.velocity.x > 0)
		{
			bg.velocity.x = (snowBody.base.velocity.x * level.bgSpeedFactor) * -1;
			rocks.collisionGroup.forEachAlive((r) ->
			{
				r.velocity.x = bg.velocity.x;
			});
			birds.collisionGroup.forEachAlive((b) ->
			{
				b.velocity.x = bg.velocity.x * 1.2;
			});

			points.collisionGroup.forEachAlive((p) ->
			{
				p.velocity.x = bg.velocity.x * 1.2;
			});
		}
	}

	function resetSlowMo()
	{
		isSlowMotion = false;
		snowBody.restoreCachedSpeed();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (isPlayInProgress)
		{
			if (FlxG.keys.justPressed.LEFT && !isSlowMotion)
			{
				snowBody.cacheSpeed();
				isSlowMotion = true;
				slowMoDelay.start();
				var currentVel = snowBody.base.velocity.x;
				var reduceVelBy = snowBody.base.velocity.x * slowMoFactor;
				snowBody.changeVelocityBy(reduceVelBy * -1);
				bg.velocity.x = (snowBody.base.velocity.x * level.bgSpeedFactor) * -1;
				trace('slow mo start');
			}
			if (FlxG.keys.justReleased.LEFT && isSlowMotion)
			{
				trace('slow mo stop');
				snowBody.restoreCachedSpeed();
				isSlowMotion = false;
				slowMoDelay.stop();
				// snowBody.changeVelocityBy(snowBody.base.velocity.x - snowBody.base.velocity.x * slowMoFactor);
			}
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
			slowMoDelay.wait(elapsed);
			rocksDelay.wait(bg.x * -1);
			birdsDelay.wait(bg.x * -1);
			pointsDelay.wait(bg.x * -1);
		}

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
		final waveAmp:Float = 100;
		var waveCenter:Float = 200;
		// determine y pos of points on a wave
		var y = Std.int(waveCenter -= (waveAmp * (FlxMath.fastSin(bg.x))));
		var points = points.get(FlxG.width, y);

		layers.foreground.add(points);
	}

	inline function handleCollisions()
	{
		FlxG.overlap(snowBody.base, rocks.collisionGroup, (snow, rock:Rock) ->
		{
			if (!rock.isHit)
			{
				var velocityOverride = switch (rock.key)
				{
					case 3: -1; // ice block, stop
					case 2: null; // ramp, jump
					case _: (rock.key + 1) * 150; // bump
				};
				if (velocityOverride < 0)
				{
					// hit the ice block, remove the colliding ball
					snowBody.base.remove();
					snowBody.removeBall(snowBody.base);
				}
				else
				{
					final overrideJumpReady = true;
					snowBody.jump(velocityOverride, overrideJumpReady);
				}
				rock.collide();
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
