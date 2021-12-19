package;

class PlayState extends BaseState
{
	var snowHead:Snowball;
	var snowBody:SnowBalls;
	var snowTarget:Carrot;
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
	var dial:Dial;
	var introAsset:FramesHelper;
	var lostLevel:Bool = false;

	override public function create()
	{
		super.create();
		layers.shutter.alpha = 1;
		FlxG.debugger.drawDebug = true;
		hasReachedDistance = false;

		// now load stats for use
		level = Data.level;
		bg = new FlxBackdrop("assets/images/snow-bg-896x504.png");
		layers.bg.add(bg);
		bg.maxVelocity.x = level.maxVelocity * level.bgSpeedFactor;

		snowBody = new SnowBalls(96, 320, level.maxVelocity);
		// if already rolling, start rollin!
		if (Data.winCount > 0)
		{
			snowBody.changeVelocityBy(Data.level.snowManVelocityIncrement);
		}
		snowTarget = new Carrot(snowBody.base.x, snowBody.base.floor - 144);
		final targetSpeedReduction = 0.7; // todo, as difficulty increases make this number go up to close the gap between carrot and snow
		snowTarget.maxVelocity.x = snowBody.base.maxVelocity.x * targetSpeedReduction;
		layers.bg.add(snowTarget);
		snowBody.addBallsTo(layers.entities);

		lowObstaclesY = Std.int(snowBody.base.y + (snowBody.base.height - 10));
		midObstaclesY = Std.int(lowObstaclesY - (FlxG.height * 0.3)); // Std.int(snowBody.torso.y - 35);

		rocks = new ObstaclesGround();
		rocksDelay = {
			stepTravelled: FlxG.random.int(1000, 1100), // new rock every x pixels
			lastTravelled: 0,
			isInProgress: true,
			isResetAuto: true,
			onReady: spawnRock
		}

		birds = new ObstaclesAir();
		birdsDelay = {
			stepTravelled: FlxG.random.int(1200, 1700), // new bird every x pixels
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
		dial = new Dial();
		layers.foreground.add(dial);
		dial.y = FlxG.height - 100;
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
		var birdHeight = FlxG.random.int(midObstaclesY - 60, midObstaclesY + 10);
		var bird = birds.get(0, birdHeight);
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
							if (Data.winCount == 0)
							{
								showText("go faster than\nthe carrot!", text ->
								{
									text.flicker(2.0, 0.3, onComplete ->
									{
										text.fadeOut(onComplete ->
										{
											text.kill();
										});
									});
								});
							}
						});
					}
				}
			}
			duration += 0.7;
		}
	}

	var endMargin:Float = 50;

	public function getTargetDistance():Float
	{
		var targetComplete = (snowTarget.x / (FlxG.width - endMargin)) * 100;
		if (targetComplete >= 100 && isPlayInProgress && !lostLevel)
		{
			loseLevel(TOOSLOW);
		}
		return targetComplete;
	}

	public function getActualDistance():Float
	{
		var snowManComplete:Float = (snowBody.base.x / (FlxG.width - endMargin)) * 100;
		if (isPlayInProgress)
		{
			if (snowManComplete >= 100)
			{
				progressToNextLevel();
			}
		}
		return snowManComplete;
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
		if (!isPlayInProgress || snowBody.base == null) // todo ? set isPlayInProgress false if last remaining ball is chucked away
		{
			isPlayInProgress = false;
			return;
		}
		// update direction based on key input
		var nextDirection = shouldAccelerate();

		snowTarget.velocity.x = level.maxVelocity;

		if (!isSlowMotion && nextDirection > 0)
		{
			snowBody.base.acceleration.x = 0;
			var changeVelocityBy = level.snowManVelocityIncrement * nextDirection;
			snowBody.changeVelocityBy(changeVelocityBy);
		}
		else
		{
			if (snowBody.base.x > 0)
			{
				final slowDown = -10;
				snowBody.base.acceleration.x = slowDown;
				snowBody.changeVelocityBy(0);
			}
		}

		if (snowBody.base.velocity.x > 0)
		{
			bg.velocity.x = (snowBody.base.velocity.x * level.bgSpeedFactor) * -1;
			rocks.collisionGroup.forEachAlive((r) ->
			{
				r.velocity.x = bg.velocity.x;
			});
			final minimumBirdVelocity = -60;
			birds.collisionGroup.forEachAlive((b) ->
			{
				b.velocity.x = bg.velocity.x * 1.7;
				if (b.velocity.x > minimumBirdVelocity)
				{
					b.velocity.x = minimumBirdVelocity;
				}
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
			loseLevel(TRYAGAIN);
		}
	}

	function showRestartOptions(message:Message)
	{
		var t = message == TOOSLOW ? "carrot won!\npress enter to restart" : "owch!!\npress enter to restart";
		final overrideY = -30;
		final fadeInTime = 6;
		showText(t, text ->
		{
			text.flicker(0, 0.5);
		}, overrideY, fadeInTime);
	}

	function loseLevel(message:Message)
	{
		isPlayInProgress = false;
		final whiteOutFadeIn = 3;
		final persistMessage = true;
		final onComplete = () ->
		{
			showRestartOptions(message);
		}
		if (!lostLevel)
		{
			lostLevel = true;
			messages.show(message, layers.overlay, persistMessage, onComplete);
			layers.bgShutter.fadeIn(whiteOutFadeIn);
			layers.shutter.fadeIn(whiteOutFadeIn);
		}
	}

	function progressToNextLevel()
	{
		if (isPlayInProgress && !lostLevel)
		{
			isPlayInProgress = false;
			layers.shutter.fadeIn(0.3);
			Data.level.levelLength += 1000; // todo this isn't used anymore?
			Data.level.maxVelocity += level.maxVelocityIncrement;
			Data.level.bgSpeedFactor += 0.7;
			Data.winCount++;
			final onComplete = () ->
			{
				final yOverride = FlxG.height;
				showText('you are on a roll!\n score is ${Data.score}\nprepare for round ${Data.winCount + 1}', text ->
				{
					FlxTween.tween(text, {y: -300}, 5, {
						onComplete: tween ->
						{
							FlxG.resetState();
						}
					});
				}, yOverride);
			}
			messages.show(WIN, layers.overlay, onComplete);
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (isPlayInProgress)
		{
			// because it's not in a group that is being updated
			snowBody.update(elapsed);
			dial.updateVelocity(snowBody.base.velocity.x, snowBody.base.maxVelocity.x);
			hasReachedDistance = ((snowBody.base.x / (FlxG.width - endMargin)) * 100) >= 100;
			if (hasReachedDistance)
			{
				progressToNextLevel();
			}
			// if (FlxG.keys.justPressed.LEFT && !isSlowMotion)
			// {
			// 	// enter slow motion
			// 	snowBody.cacheSpeed();
			// 	isSlowMotion = true;
			// 	slowMoDelay.start();
			// 	var reduceVelBy = snowBody.base.velocity.x * slowMoFactor;
			// 	snowBody.changeVelocityBy(reduceVelBy * -1);
			// 	bg.velocity.x = (snowBody.base.velocity.x * level.bgSpeedFactor) * -1;
			// 	layers.overOverlay.fadeIn(0.2);
			// 	messages.show(FROZENTIME, layers.overlay);

			// 	// trace('slow mo start');
			// }
			if (FlxG.keys.justReleased.LEFT && isSlowMotion)
			{
				resetSlowMo();
			}

			if (FlxG.keys.justPressed.UP)
			{
				snowBody.jump();
			}
			if (FlxG.keys.justPressed.S)
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
		#if debug
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
		#end
	}

	inline function handleCollisions()
	{
		// collide rocks

		FlxG.overlap(snowBody.base, rocks.collisionGroup, (snow, rock:Rock) ->
		{
			if (!rock.isHit)
			{
				rock.collide();
				var jumpVelocityPercentage = switch (rock.key)
				{
					case 3: -1; // ice block, stop
					case 2: 1.5; // ramp, jump (higher percentage)
					case _: 0.3 * (rock.key + 1); // bump (small percentage)
				};
				if (jumpVelocityPercentage < 0)
				{
					// hit the ice block, remove the colliding ball
					removeBall(snowBody.base);
				}
				else
				{
					final overrideJumpReady = true;

					snowBody.jump(jumpVelocityPercentage, overrideJumpReady);
					final collisionVelocityPenalty = -30;
					var decreaseVelocityBy = collisionVelocityPenalty + snowBody.base.velocity.x;
					if (decreaseVelocityBy > 0)
					{
						snowBody.changeVelocityBy(decreaseVelocityBy * -1);
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
				var height = FlxG.height - points.y;
				var reductionFactor = height / FlxG.height;
				var score = Std.int((2 * height * reductionFactor));
				Data.score += score;
				var text = glyphs.getText('+$score');
				text.color = FlxColor.fromRGB(100, 255, 255, 30);
				final textScale = 0.9;
				text.scale.x = textScale;
				text.scale.y = textScale;
				text.x = points.centerX - (text.width * 0.5);
				text.y = points.y - (text.height); // * 0.5);
				layers.bg.add(text);
				FlxTween.tween(text, {y: -60}, 2, {
					onComplete: tween ->
					{
						text.kill();
					}
				});
				text.fadeOut(2.3);
				points.collide();
			}
		});
	}
}
