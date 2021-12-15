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
		base = new Snowball(x, y, "Large", popVelocity);
		torso = new Snowball(x, y - 48, "Mid", popVelocity);
		head = new Snowball(x, torso.y - 38, "Small", popVelocity);
		collisionGroup.add(base);
		collisionGroup.add(torso);
		collisionGroup.add(head);
		base.maxVelocity.x = maxVelocity;
		head.maxVelocity.x = maxVelocity;
		torso.maxVelocity.x = maxVelocity;
		balls.push(base);
		balls.push(torso);
		balls.push(head);
		// head.immovable = false;
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
			// default to targeting ball at base of stack
			var targetVelocity = balls[0].velocity.y;
			if (i >= 1)
			{
				// if ball directly underneath is not attached, target that instead
				var target = balls[i - 1];
				if (!target.isAttached)
				{
					targetVelocity = target.velocity.y;
				}
			}
			syncVerticalVelocity(b, targetVelocity);
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

	inline function syncVerticalVelocity(ball:Snowball, targetVelocity:Float)
	{
		if (ball.isAttached)
		{
			ball.velocity.y = targetVelocity;
			ball.resetPositionY();
		}
		else
		{
			ball.resetAttachment();
		}
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
		return base.y >= base.idlePositionY;
	}

	inline function isHeadOnTorso()
	{
		var headBottom = head.y + head.graphic.height;
		var restingOnY = torso.alive ? torso.y : base.y;
		return headBottom >= restingOnY;
	}

	inline function isTorsoOnBase()
	{
		var torsoBottom = torso.y + torso.graphic.height;
		return torsoBottom >= base.y;
	}

	public function jump(?velocityOverride:Float)
	{
		if (isJumpReady)
		{
			var b = balls[0];
			if (b.alive && b.isAttached)
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
				if (b.alive && b.isAttached)
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
}

class Snowball extends FlxSprite
{
	public var idlePositionY:Float;
	public var hitCount:Int;
	public var isAttached(default, null):Bool;

	var style:String;
	var popVelocity:Float;
	var gravity:Float = 700;

	public function new(x, y, style:String = "", popVelocity:Float)
	{
		super(x, y);
		this.style = style;
		this.popVelocity = popVelocity;
		loadGraphic('assets/images/ball$style.png');
		idlePositionY = y;
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

	public function collide()
	{
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
			}
		}
	}

	public function resetPositionY()
	{
		if (y > idlePositionY)
		{
			y = idlePositionY;
		}
	}

	public function resetAttachment()
	{
		isAttached = y >= idlePositionY;
		if (isAttached)
		{
			// make sure pop or jump effect is gone
			acceleration.y = 0;
			velocity.y = 0;
		}
	}

	public function log()
	{
		trace('$style x,y $x,$y initY $idlePositionY center X = ${this.centerX()} vel ${velocity}');
	}

	public function pop(?velocityOverride:Float)
	{
		popVelocity = velocityOverride == null ? popVelocity : velocityOverride;
		// get airborne
		velocity.y = -popVelocity;
		// prevent popping forever
		maxVelocity.y = popVelocity;
		// accelerate towards ground
		acceleration.y = gravity;
		isAttached = false;
	}
}
