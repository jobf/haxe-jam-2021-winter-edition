package;

typedef LevelStats =
{
	var maxVelocity:Float;
	var bgSpeedFactor:Float;
	var snowManVelocityIncrement:Float;
}

class SnowBalls
{
	public var head(default, null):Snowball;
	public var torso(default, null):Snowball;
	public var base(default, null):Snowball;

	var jumpCoolOff:Delay;
	var isJumpReady:Bool;
	var popCoolOff:Delay;
	var isPopReady:Bool;
	var isOnGround:Bool;
	var isHeadAttached:Bool;
	var isTorsoAttached:Bool;
	var distanceHeadToBody:Float;
	var jumpVelocity:Float = 300;
	var popVelocity:Float = 450;
	var gravity:Float = 900;

	public var accelerationFactor:Float = 5;

	public function new(x, y, maxVelocity)
	{
		base = new Snowball(x, y, "Large");
		torso = new Snowball(x, y - 48, "Mid");
		head = new Snowball(x, torso.y - 24, "Small");
		base.maxVelocity.x = maxVelocity;
		torso.maxVelocity.x = maxVelocity;
		head.maxVelocity.x = maxVelocity;
		head.immovable = false;
		base.moveMiddleX(x);
		torso.moveMiddleX(x);
		head.moveMiddleX(x);
		jumpCoolOff = BaseState.delays.Default(0.2, setJumpIsReady, true);
		isJumpReady = true;
		popCoolOff = BaseState.delays.Default(0.2, setPopIsReady, true);
		isPopReady = true;
		isHeadAttached = true;
		isOnGround = true;
		distanceHeadToBody = torso.y - head.y;
	}

	public function update(elapsed:Float)
	{
		jumpCoolOff.wait(elapsed);
		popCoolOff.wait(elapsed);
		contactGround();
		syncHead();
		syncTorso();
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
			isOnGround = true;
			base.acceleration.y = 0;
			base.velocity.y = 0;
		}
	}

	inline function syncHead()
	{
		// keep head with torso
		if (isHeadAttached)
		{
			head.velocity.y = base.velocity.y;
			separateHeadFromTorso();
		}
		else
		{
			isHeadAttached = isHeadOnTorso();
		}
	}

	inline function syncTorso()
	{
		// keep torso with base
		if (isTorsoAttached)
		{
			torso.velocity.y = base.velocity.y;
			separateTorsoFromBase();
		}
		else
		{
			isTorsoAttached = isTorsoOnBase();
		}
	}

	inline function separateHeadFromTorso()
	{
		head.y = torso.y - (head.height + 2);
	}

	inline function separateTorsoFromBase()
	{
		torso.y = base.y - (torso.height + 2);
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
		return base.y >= base.groundedPosY;
	}

	inline function isHeadOnTorso()
	{
		var headBottom = head.y + head.height;
		return headBottom >= torso.y;
	}

	inline function isTorsoOnBase()
	{
		var torsoBottom = torso.y + torso.height;
		return torsoBottom >= base.y;
	}

	public function jump(?velocityOverride:Float)
	{
		base.groundedPosY = base.y;
		isOnGround = false;
		velocityOverride = velocityOverride == null ? jumpVelocity : velocityOverride;
		// get airborne
		// trace('jump velocityOverride $velocityOverride');
		base.velocity.y = -velocityOverride;
		// prevent jumping forever
		base.maxVelocity.y = velocityOverride;
		// accelerate towards ground
		base.acceleration.y = gravity;
	}

	public function pop()
	{
		if (isPopReady)
		{
			if (isOnGround)
			{
				jump();
			}
			else if (isTorsoAttached)
			{
				separateTorsoFromBase();
				// get airborne
				torso.velocity.y = -popVelocity;
				// prevent popping forever
				torso.maxVelocity.y = popVelocity;
				// accelerate towards ground
				torso.acceleration.y = gravity;
				isTorsoAttached = false;
			}
			else if (isHeadAttached)
			{
				separateHeadFromTorso();
				// get airborne
				head.velocity.y = -popVelocity;
				// prevent popping forever
				head.maxVelocity.y = popVelocity;
				// accelerate towards ground
				head.acceleration.y = gravity;
				isHeadAttached = false;
			}
			// trace('pop');
			isPopReady = false;
			popCoolOff.start();
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
		base.velocity.x += difference;
		torso.velocity.x = base.velocity.x;
		head.velocity.x = base.velocity.x;
	}
}

class Snowball extends FlxSprite
{
	public var groundedPosY:Float;

	var style:String;

	public function new(x, y, style:String = "")
	{
		super(x, y);
		this.style = style;
		loadGraphic('assets/images/ball$style.png');
		groundedPosY = y;
		// reduce hitbox
		setSize(width, height * 0.75);
	}

	public function log()
	{
		trace('$style x,y $x,$y initY $groundedPosY center X = ${this.centerX()} vel ${velocity}');
	}
}
