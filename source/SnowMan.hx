package;

class SnowMan extends FlxState
{
	override public function create()
	{
		super.create();
		bgColor = FlxColor.WHITE;
		bg = new FlxBackdrop("assets/images/bg.png");
		bg.screenCenter();
		add(bg);
		snowBody = new SnowBalls(40, FlxG.height - 300);
		add(snowBody);
		add(snowBody.head);
		FlxG.camera.follow(snowBody.torso, FlxCameraFollowStyle.TOPDOWN);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		snowBody.handleSnowBallsControls();

		if (FlxG.keys.justPressed.L)
		{
			trace('SnowBalls x y [${snowBody.x}, ${snowBody.y}]');
			snowBody.log();
		}
		if (FlxG.keys.justPressed.R)
		{
			FlxG.resetState();
		}

		bg.velocity.x = snowBody.velocity.x * -1;
	}

	var snowHead:Snowball;
	var snowBody:SnowBalls;
	var bg:FlxBackdrop;
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
	var accelerationFactor:Float = 5;

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
		var delayFactory = new DelayFactory();
		jumpCoolOff = delayFactory.Default(0.2, false, true);
		isJumpReady = true;
		popCoolOff = delayFactory.Default(0.2, false, true);
		isPopReady = true;
		isHeadAttached = true;
		distanceHeadToBody = torso.y - head.y;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		jumpCoolOff.wait(elapsed, setJumpIsReady);
		popCoolOff.wait(elapsed, setPopIsReady);
		contactGround();
		syncHead();
	}

	public inline function handleSnowBallsControls()
	{
		if (FlxG.keys.pressed.RIGHT)
		{
			velocity.x += accelerationFactor;
		}
		if (FlxG.keys.pressed.LEFT)
		{
			velocity.x -= accelerationFactor;
		}
		if (FlxG.keys.justPressed.UP)
		{
			jump();
		}
		if (FlxG.keys.justPressed.DOWN)
		{
			pop();
		}
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
		head.velocity.x = velocity.x;
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
			head.acceleration.y = 0;
		}
	}

	function separateHeadFromTorso()
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

	inline function isBaseOnGround()
	{
		return base.y >= base.initialPosY;
	}

	inline function isHeadOnBody()
	{
		var headBottom = head.y + head.height;
		return headBottom >= torso.y;
	}

	public function jump()
	{
		if (isJumpReady && isBaseOnGround())
		{
			isJumpReady = false;
			jumpCoolOff.start();
			// get airborne
			velocity.y = -jumpVelocity;
			// prevent jumping forever
			maxVelocity.y = jumpVelocity;
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
		trace('$style y now $y init $initialPosY x now $x ceter X = ${this.centerX()}');
	}
}
