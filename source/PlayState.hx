package;

class PlayState extends BaseState
{
	var snowHead:Snowball;
	var snowBody:SnowBalls;
	var bg:FlxBackdrop;
	var rocks:Rocks;
	var rocksDelay:Delay;
	var accelerationDelay:Delay;
	var level:LevelStats;

	override public function create()
	{
		super.create();
		bgColor = FlxColor.WHITE;
		level = Data.level;
		bg = new FlxBackdrop("assets/images/bg.png");
		bg.screenCenter();
		layers.bg.add(bg);
		bg.maxVelocity.x = level.maxVelocity * level.bgSpeedFactor;
		snowBody = new SnowBalls(128, FlxG.height - 150, level.maxVelocity);

		layers.entities.add(snowBody.base);
		layers.entities.add(snowBody.torso);
		layers.entities.add(snowBody.head);

		layers.entities.add(snowBody.head);
		rocks = new Rocks();
		rocksDelay = BaseState.delays.Default(2, spawnRock, true, true);
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
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		snowBody.update(elapsed);
		if (FlxG.keys.justPressed.UP)
		{
			snowBody.pop();
		}
		handleCollisions();
		accelerationDelay.wait(elapsed);
		rocksDelay.wait(elapsed);

		if (FlxG.keys.justPressed.L)
		{
			trace('\n\n\nSnowBalls x y [${snowBody.base.x}, ${snowBody.base.y}] vel ${snowBody.base.velocity} acc ${snowBody.base.acceleration}\n bg velocity ${bg.velocity}\n\n\n');

			snowBody.log();
		}
	}

	function spawnRock()
	{
		var rock = rocks.getRock(FlxG.width, Std.int(FlxG.height * 0.80), 0);
		// trace('rock x,y ${rock.x},${rock.y}');
		rock.velocity.x = bg.velocity.x;
		layers.foreground.add(rock);
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
	}
}
