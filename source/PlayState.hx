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
	var hud:HUD;
	var introAsset:FramesHelper;
	var lostLevel:Bool = false;

	override public function create()
	{
		super.create();
		layers.shutter.alpha = 1;
		FlxG.debugger.drawDebug = true;
		hasReachedDistance = false;
		// before loading new level, if length is lower than data then it needs to catch up so is already in play
		var isSnowRollin = level != null && level.levelLength < Data.level.levelLength;
		// now load stats for use
		level = Data.level;
		bg = new FlxBackdrop("assets/images/snow-bg-896x504.png");
		layers.bg.add(bg);
		bg.maxVelocity.x = level.maxVelocity * level.bgSpeedFactor;

		snowBody = new SnowBalls(96, 320, level.maxVelocity);
		// if alreadt rolling, start rollin!
		if (isSnowRollin)
		{
			snowBody.changeVelocityBy(Data.level.snowManVelocityIncrement);
		}
		snowTarget = new FlxObject(snowBody.base.x, FlxG.height + 100);
		snowTarget.maxVelocity.x = bg.maxVelocity.x;
		add(snowTarget);
		snowBody.addBallsTo(layers.entities);

		lowObstaclesY = Std.int(snowBody.base.y + (snowBody.base.height - 10));
		midObstaclesY = Std.int(lowObstaclesY - (FlxG.height * 0.3)); // Std.int(snowBody.torso.y - 35);

		rocks = new ObstaclesGround();
		rocksDelay = {
			stepTravelled: 1000, // new rock every x pixels
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
		hud = new HUD(level);
		layers.bg.add(hud);
		layers.overOverlay.add(hud.slowMoMeter);
		layers.overOverlay.fadeOut(0.1);
		introAsset = new FramesHelper("assets/images/start-826x200-1x2.png", 826, 1, 2, 200);

		startIntro();
	}

	function spawnRock()
	{
		var rock = rocks.get(0, lowObstaclesY);
		layers.bg.add(rock);
		layers.overlay.add(rock.warning);
	}

	function spawnBird()
	{
		var bird = birds.get(0, midObstaclesY);
		layers.overlay.add(bird.warning);
		layers.foreground.add(bird);
	}

	function spawnPoints()
	{
		final waveAmp:Float = 100;
		var waveCenter:Float = 200;
		// determine y pos of points on a wave
		var y = Std.int(waveCenter -= (waveAmp * (FlxMath.fastSin(bg.x))));
		var points = points.get(0, y);

		layers.overlay.add(points.warning);
		layers.foreground.add(points);
	}

	var humanize = 1.4;

	function startIntro()
	{
		var screenMidX = FlxG.width * 0.5;
		var screenMidY = FlxG.height * 0.5;
		final textWidth = 826;
		final textHeight = 200;
		var endX = screenMidX - (textWidth * 0.5);
		var endY = screenMidY - (textHeight * 0.5);
		var ready = new FlxSprite(endX, 1000);
		ready.frames = introAsset.getFrames();
		ready.animation.frameIndex = 0;
		layers.overlay.add(ready);

		var go = new FlxSprite(endX, 1000);
		go.frames = introAsset.getFrames();
		go.animation.frameIndex = 1;
		layers.overlay.add(go);

		var duration = 0.7;
		var texts = [ready, go];
		for (i => t in texts)
		{
			var tween = FlxTween.tween(t, {x: endX, y: endY}, duration, {ease: FlxEase.bounceIn});
			tween.onComplete = (_) ->
			{
				if (i == texts.length - 1)
				{
					final fadeOut = 0.3;
					layers.bgShutter.alpha = 0;
					layers.shutter.fadeOut(fadeOut);
					isPlayInProgress = true;
					for (et in texts)
					{
						FlxTween.tween(et, {y: -200}, 0.5, {ease: FlxEase.bounceOut});
						et.fadeOut(fadeOut, onComplete ->
						{
							et.kill();
						});
					}
				}
			}
			duration += 0.7;
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
		if (!isPlayInProgress || snowBody.base == null) // todo set isPlayInProgress flase if last remaining ball is chucked away
		{
			isPlayInProgress = false;
			return;
		}
		// update direction based on key input
		var nextDirection = shouldAccelerate();

		// always speed up target, we are racing it
		snowTarget.velocity.x += (level.snowManVelocityIncrement);

		if (!isSlowMotion && nextDirection > 0)
		{
			var changeVelocityBy = level.snowManVelocityIncrement * nextDirection;
			snowBody.changeVelocityBy(changeVelocityBy);
		}

		// if (snowBody.base == null)
		// {
		// 	return; // todo set isPlayInProgress flase if last remaining ball is chucked away
		// }
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
		trace('slow mo stop');
		isSlowMotion = false;
		snowBody.restoreCachedSpeed();
		snowBody.base.velocity.y -= 20; // todo add more accessible var for this
		slowMoDelay.stop();
		layers.overOverlay.fadeOut(0.2);
	}

	function removeBall(b:Snowball)
	{
		snowBody.removeBall(b);
		if (b.tag == "head")
		{
			loseLevel();
		}
	}

	function showRestartOptions()
	{
		trace('restart?');
	}

	function loseLevel()
	{
		lostLevel = true;
		isPlayInProgress = false;
		final persistMessage = true;
		final onComplete = () ->
		{
			showRestartOptions();
		}
		messages.show(TRYAGAIN, layers.overlay, persistMessage, onComplete);
		layers.bgShutter.fadeIn(5);
		layers.shutter.fadeIn(5);
		// hud.fadeOut(3.0);
	}

	function progressToNextLevel()
	{
		layers.shutter.fadeIn(0.3);
		isPlayInProgress = false;
		Data.level.levelLength += 1000;
		Data.level.maxVelocity += level.maxVelocityIncrement;
		Data.level.bgSpeedFactor += 0.7;
		Data.level.snowManVelocityIncrement = Data.level.bgSpeedFactor;
		final onComplete = () ->
		{
			FlxG.resetState();
		}
		messages.show(WIN, layers.overlay, onComplete);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (snowTarget.x > level.levelLength && !lostLevel)
		{
			loseLevel();
		}
		if (isPlayInProgress)
		{
			snowBody.update(elapsed);
			hasReachedDistance = bg.x * -1 > level.levelLength;
			if (hasReachedDistance)
			{
				progressToNextLevel();
			}
			if (FlxG.keys.justPressed.LEFT && !isSlowMotion)
			{
				// enter slow motion
				snowBody.cacheSpeed();
				isSlowMotion = true;
				slowMoDelay.start();
				var reduceVelBy = snowBody.base.velocity.x * slowMoFactor;
				snowBody.changeVelocityBy(reduceVelBy * -1);
				bg.velocity.x = (snowBody.base.velocity.x * level.bgSpeedFactor) * -1;
				layers.overOverlay.fadeIn(0.2);
				messages.show(FROZENTIME, layers.overlay);

				// trace('slow mo start');
			}
			if (FlxG.keys.justReleased.LEFT && isSlowMotion)
			{
				resetSlowMo();
			}

			if (FlxG.keys.justPressed.Z)
			{
				snowBody.jump();
			}
			if (FlxG.keys.justPressed.X)
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
			removeBall(snowBody.base);
		}
		if (FlxG.keys.justReleased.T)
		{
			@:privateAccess
			var b = snowBody.balls[1];
			removeBall(b);
		}
		if (FlxG.keys.justPressed.L)
		{
			// trace('\n\n\nSnowBalls x y [${snowBody.base.x}, ${snowBody.base.y}] vel ${snowBody.base.velocity} acc ${snowBody.base.acceleration}\n bg velocity ${bg.velocity} bg pos ${bg.x}, ${bg.y}\n\n\n');

			snowBody.log();
		}
		if (lostLevel)
		{
			if (FlxG.keys.justPressed.ENTER)
			{
				// reset data
				Data.init();
				// begin again
				FlxG.resetState();
			}
		}
	}

	inline function handleCollisions()
	{
		// collide rocks

		FlxG.overlap(snowBody.base, rocks.collisionGroup, (snow, rock:Rock) ->
		{
			if (!rock.isHit)
			{
				rock.collide();
				var velocityOverride = switch (rock.key)
				{
					case 3: -1; // ice block, stop
					case 2: null; // ramp, jump
					case _: (rock.key + 1) * 150; // bump
				};
				if (velocityOverride < 0)
				{
					// hit the ice block, remove the colliding ball
					removeBall(snowBody.base);
				}
				else
				{
					final overrideJumpReady = true;

					snowBody.jump(velocityOverride, overrideJumpReady);
					final collisionVelocityForfeit = -30;
					var forfeitDifference = collisionVelocityForfeit + snowBody.base.velocity.x;
					if (forfeitDifference > 0)
					{
						snowBody.changeVelocityBy(forfeitDifference * -1);
					}
				}
			}
		});

		// collide birds

		FlxG.overlap(snowBody.collisionGroup, birds.collisionGroup, (snow:Snowball, bird:Obstacle) ->
		{
			if (!bird.isHit)
			{
				bird.collide();
				if (!snow.surviveCollision())
				{
					removeBall(snow);
				};
			}
		});

		// collide points

		FlxG.overlap(snowBody.collisionGroup, points.collisionGroup, (snow:Snowball, points:Collectible) ->
		{
			if (!points.isHit)
			{
				points.collide();
			}
		});
	}
}
