package;

typedef LevelStats =
{
	var maxVelocity:Float;
	var bgSpeedFactor:Float;
	var snowManVelocityIncrement:Float;
	var levelLength:Float;
}

class SnowBalls
{
	public var head(default, null):Snowball;
	public var torso(default, null):Snowball;
	public var base(default, null):Snowball;
	public var collisionGroup(default, null):FlxTypedGroup<Snowball>;
	public var accelerationFactor:Float = 5;

	var jumpCoolOff:Delay;
	var isJumpReady:Bool;
	var popCoolOff:Delay;
	var isPopReady:Bool;
	var popVelocity:Float = 350;
	var gravity:Float = 700;
	var balls:Array<Snowball> = [];

	public function new(x, y, maxVelocity)
	{
		collisionGroup = new FlxTypedGroup<Snowball>();
		var floor = y + 192;
		base = new Snowball(x, y, "Large", popVelocity, "base", floor);
		torso = new Snowball(x, y - 48, "Mid", popVelocity, "torso", floor);
		head = new Snowball(x, torso.y - 38, "Small", popVelocity, "head", floor);
		torso.ballUnderneath = base;
		head.ballUnderneath = torso;
		collisionGroup.add(base);
		collisionGroup.add(torso);
		collisionGroup.add(head);
		base.maxVelocity.x = maxVelocity;
		head.maxVelocity.x = maxVelocity;
		torso.maxVelocity.x = maxVelocity;
		balls.push(base);
		balls.push(torso);
		balls.push(head);
		base.moveMiddleX(x);
		torso.moveMiddleX(x);
		head.moveMiddleX(x);
		jumpCoolOff = BaseState.delays.Default(0.2, setJumpIsReady, true);
		isJumpReady = true;
		popCoolOff = BaseState.delays.Default(0.2, setPopIsReady, true);
		isPopReady = true;
	}

	public function update(elapsed:Float)
	{
		jumpCoolOff.wait(elapsed);
		popCoolOff.wait(elapsed);
		for (i => b in balls)
		{
			// is resting ? set same velocity as target
			if (!b.isAirborne)
			{
				// default to targeting ball at base of stack
				var targetVelocity = balls[0].velocity.y;
				if (i >= 1)
				{
					// if ball directly underneath is not attached, target that instead
					var target = balls[i - 1];
					if (target.isAirborne)
					{
						targetVelocity = target.velocity.y;
					}
				}
				b.velocity.y = targetVelocity;
			}
		}
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

	public function jump(?velocityOverride:Float)
	{
		if (isJumpReady)
		{
			var b = balls[0];
			if (b.alive && !b.isAirborne)
			{
				b.pop();
				isJumpReady = false;
				jumpCoolOff.start();
			}
		}
	}

	public function pop()
	{
		if (isPopReady)
		{
			for (b in balls.slice(1))
			{
				if (b.alive && !b.isAirborne)
				{
					b.pop();
					isPopReady = false;
					popCoolOff.start();

					break;
				}
			}
		}
	}

	public function log()
	{
		base.log();
		torso.log();
		head.log();
	}

	public function increaseVelocity(difference:Float)
	{
		base.velocity.x += difference;
		torso.velocity.x = base.velocity.x;
		head.velocity.x = base.velocity.x;
	}

	public function removeBall(toRemove:Snowball)
	{
		balls.remove(toRemove);
		for (i => b in balls)
		{
			if (i == 0)
			{
				b.ballUnderneath = null;
			}
			else
			{
				b.ballUnderneath = balls[i - 1];
			}
		}
	}
}

class Snowball extends FlxSprite
{
	public var hitCount:Int;
	public var ballUnderneath:Snowball;
	public var isAirborne:Bool;

	var tag:String;

	var style:String;
	var popVelocity:Float;
	var gravity:Float = 700;
	var floor:Float;

	public function new(x, y, style:String = "", popVelocity:Float, tag:String, floor:Float)
	{
		super(x, y);
		this.tag = tag;
		isAirborne = false;
		this.style = style;
		this.popVelocity = popVelocity;
		maxVelocity.y = popVelocity;
		this.floor = floor;
		loadGraphic('assets/images/ball$style.png');
		hitCount = 0;
		setSize(width * 0.3, height * 0.3);
		centerOffsets();
	}

	function remove()
	{
		FlxTween.tween(this, {x: x - 1000}, 0.5, {
			onComplete: tween ->
			{
				this.kill();
			}
		});
	}

	public function surviveCollision():Bool
	{
		var survives = true;
		if (!this.isFlickering())
		{
			this.flicker();
			hitCount++;
			if (hitCount == 1)
			{
				this.color = FlxColor.CYAN;
			}
			if (hitCount == 2)
			{
				this.remove();
				survives = false;
			}
		}
		return survives;
	}

	public function log() {}

	public function pop(?velocityOverride:Float)
	{
		isAirborne = true;
		popVelocity = velocityOverride == null ? popVelocity : velocityOverride;
		// get airborne
		velocity.y = -popVelocity;
		// fall towards ground
		acceleration.y = gravity;
	}

	public function currentBottomEdge():Float
	{
		return y + graphic.height;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		var cannotBeFurtherThan = ballUnderneath == null ? floor : ballUnderneath.y;
		var amountPastBottom = currentBottomEdge() - cannotBeFurtherThan;
		if (amountPastBottom < 0)
		{
			// fall towards floor
			acceleration.y = gravity;
		}
		else
		{
			// stop falling
			isAirborne = false;
			y -= amountPastBottom;
			acceleration.y = 0;
			velocity.y = 0;
		}
	}
}
