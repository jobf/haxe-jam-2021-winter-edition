package;

import core.BaseState;
import flixel.group.FlxGroup;

typedef LevelStats =
{
	var maxVelocity:Float;
	var bgSpeedFactor:Float;
	var snowManVelocityIncrement:Float;
}

class Data
{
	public static var level:LevelStats = {
		maxVelocity: 30,
		bgSpeedFactor: 8,
		snowManVelocityIncrement: 8
	}
}

class SnowMan extends BaseState
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
		snowBody = new SnowBalls(128, FlxG.height - 150);
		snowBody.maxVelocity.x = level.maxVelocity;
		snowBody.head.maxVelocity.x = level.maxVelocity;
		layers.entities.add(snowBody);
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
		if (snowBody.velocity.x > 0)
		{
			bg.velocity.x = (snowBody.velocity.x * level.bgSpeedFactor) * -1;
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

		if (FlxG.keys.justPressed.L)
		{
			trace('\n\n\nSnowBalls x y [${snowBody.x}, ${snowBody.y}] vel ${snowBody.velocity} acc ${snowBody.acceleration}\n bg velocity ${bg.velocity}\n\n\n');

			snowBody.log();
		}
	}

	function spawnRock()
	{
		var rock = rocks.getRock(FlxG.width, Std.int(FlxG.height * 0.80), 0);
		trace('rock x,y ${rock.x},${rock.y}');
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

class SnowBalls extends FlxSpriteGroup
{
	public var head(default, null):Snowball;
	public var torso(default, null):Snowball;
	public var base(default, null):Snowball;

	var shoulders:FlxSprite;
	var jumpCoolOff:Delay;
	var isJumpReady:Bool;
	var popCoolOff:Delay;
	var isPopReady:Bool;
	var isHeadAttached:Bool;
	var distanceHeadToBody:Float;
	var jumpVelocity:Float = 300;
	var popVelocity:Float = 450;
	var gravity:Float = 900;

	public var accelerationFactor:Float = 5;

	public function new(x, y)
	{
		super();
		base = new Snowball(x, y, "Large");
		torso = new Snowball(x, y - 48, "Mid");
		torso.setSize(torso.width, torso.height * 4);
		head = new Snowball(x, torso.y - 24, "Small");
		head.immovable = false;
		add(base);
		add(torso);
		shoulders = new FlxSprite(x, torso.y);
		shoulders.makeGraphic(Std.int(torso.width * 2), Std.int(torso.height), FlxColor.TRANSPARENT); // 0x6600FFFF
		shoulders.immovable = true;
		add(shoulders);
		base.moveMiddleX(x);
		torso.moveMiddleX(x);
		shoulders.moveMiddleX(x);
		head.moveMiddleX(x);
		jumpCoolOff = BaseState.delays.Default(0.2, setJumpIsReady, true);
		isJumpReady = true;
		popCoolOff = BaseState.delays.Default(0.2, setPopIsReady, true);
		isPopReady = true;
		isHeadAttached = true;
		distanceHeadToBody = torso.y - head.y;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		jumpCoolOff.wait(elapsed);
		popCoolOff.wait(elapsed);
		contactGround();
		syncHead();
	}

	public inline function shouldAccelerate():Int
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

	inline function contactGround()
	{
		// do not pass base through ground
		if (isBaseOnGround())
		{
			acceleration.y = 0;
			velocity.y = 0;
		}
	}

	inline function syncHead()
	{
		// keep head with body
		if (isHeadAttached)
		{
			head.velocity.y = velocity.y;
			separateHeadFromTorso();
		}
		else
		{
			connectHeadToTorso();
		}
	}

	inline function connectHeadToTorso()
	{
		if (isHeadOnBody())
		{
			isHeadAttached = true;
		}
	}

	inline function separateHeadFromTorso()
	{
		head.y = torso.y - (head.height + 2);
	}

	function setJumpIsReady()
	{
		isJumpReady = true;
	}

	function setPopIsReady()
	{
		isPopReady = true;
	}

	function gen()
	{
		isPopReady = true;
	}

	inline function isBaseOnGround()
	{
		return base.y >= base.initialPosY;
	}

	inline function isHeadOnBody()
	{
		var headBottom = head.y + head.height;
		return headBottom >= torso.y;
	}

	public function jump(?velocityOverride:Float)
	{
		if (isJumpReady && isBaseOnGround())
		{
			isJumpReady = false;
			jumpCoolOff.start();
			velocityOverride = velocityOverride == null ? jumpVelocity : velocityOverride;
			// get airborne
			trace('jump velocityOverride $velocityOverride');
			velocity.y = -velocityOverride;
			// prevent jumping forever
			maxVelocity.y = velocityOverride;
			// accelerate towards ground
			acceleration.y = gravity;
		}
	}

	public function pop()
	{
		if (isPopReady && isHeadAttached)
		{
			trace('pop head');
			separateHeadFromTorso();
			isPopReady = false;
			popCoolOff.start();
			// get airborne
			head.velocity.y = -popVelocity;
			// prevent popping forever
			head.maxVelocity.y = popVelocity;
			// accelerate towards ground
			head.acceleration.y = gravity;
			isHeadAttached = false;
		}
	}

	public function log()
	{
		base.log();
		torso.log();
		head.log();
	}

	public function changeHorizontalSpeed(difference:Float)
	{
		velocity.x += difference;
		head.velocity.x = velocity.x;
	}
}

class Snowball extends FlxSprite
{
	public var initialPosY(default, null):Float;

	var style:String;

	public function new(x, y, style:String = "")
	{
		super(x, y);
		this.style = style;
		loadGraphic('assets/images/ball$style.png');
		initialPosY = y;
		// reduce hitbox
		setSize(width, height * 0.75);
	}

	public function log()
	{
		trace('$style x,y $x,$y initY $initialPosY center X = ${this.centerX()} vel ${velocity}');
	}
}

class Rock extends FlxSprite
{
	public var weight(default, null):Int;

	public var isHit(default, null):Bool;

	public function new(x, y, rockWeight)
	{
		super(x, y);
		weight = rockWeight + 1;
		isHit = false;
	}

	public function collide()
	{
		trace('explode');
		isHit = true;
	}
}

class Rocks
{
	public var collisionGroup(default, null):FlxTypedGroup<Rock>;

	var framesHelper:FramesHelper;

	public function new()
	{
		collisionGroup = new FlxTypedGroup<Rock>();
		framesHelper = new FramesHelper("assets/images/rocks.png", 40, 3, 1);
	}

	public function getRock(x:Int, y:Int, weight:Int = 0):Rock
	{
		var rock = new Rock(x, y, weight);
		collisionGroup.add(rock);
		rock.frames = framesHelper.getFrames();
		rock.animation.frameIndex = weight;
		return rock;
	}
}
