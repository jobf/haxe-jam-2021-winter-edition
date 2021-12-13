package;

class SnowMan extends FlxState
{
	var accelerationFactor:Float = 5;

	override public function create()
	{
		super.create();
		bgColor = FlxColor.WHITE;
		bg = new FlxBackdrop("assets/images/bg.png");
		bg.screenCenter();
		add(bg);
		snowman = new Snowman(40, FlxG.height - 300);
		add(snowman);
		FlxG.camera.follow(snowman.body, FlxCameraFollowStyle.TOPDOWN);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		handleSnowmanControls();

		if (FlxG.keys.justPressed.L)
		{
			trace('snowman x y [${snowman.x}, ${snowman.y}]');
			snowman.log();
		}
		if (FlxG.keys.justPressed.R)
		{
			FlxG.resetState();
		}

		bg.velocity.x = snowman.velocity.x * -1;
	}

	inline function handleSnowmanControls()
	{
		if (FlxG.keys.pressed.RIGHT)
		{
			snowman.velocity.x += accelerationFactor;
		}
		if (FlxG.keys.pressed.LEFT)
		{
			snowman.velocity.x -= accelerationFactor;
		}
		if (FlxG.keys.justPressed.UP)
		{
			snowman.jump();
		}
		if (FlxG.keys.justPressed.DOWN)
		{
			snowman.pop();
		}
	}

	var snowman:Snowman;
	var bg:FlxBackdrop;
}

class Snowman extends FlxSpriteGroup
{
	var base:Snowball;

	public var body(default, null):Snowball;

	var head:Snowball;
	var jumpCoolOff:Delay;
	var isJumpReady:Bool;
	var popCoolOff:Delay;
	var isPopReady:Bool;
	var isHeadAttached:Bool;
	var distanceHeadToBody:Float;
	var jumpVelocity:Float = 300;
	var popVelocity:Float = 450;
	var gravity:Float = 900;

	public function new(x, y)
	{
		super();
		base = new Snowball(x, y, "Large");
		body = new Snowball(x, y - 48, "Mid");
		head = new Snowball(x, body.y - 24, "Small");
		add(base);
		add(body);
		add(head);
		base.moveMiddleX(50);
		body.moveMiddleX(50);
		head.moveMiddleX(50);
		var delayFactory = new DelayFactory();
		jumpCoolOff = delayFactory.Default(0.2, false, true);
		isJumpReady = true;
		popCoolOff = delayFactory.Default(0.2, false, true);
		isPopReady = true;
		isHeadAttached = true;
		distanceHeadToBody = body.y - head.y;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		jumpCoolOff.wait(elapsed, setJumpIsReady);
		popCoolOff.wait(elapsed, setPopIsReady);
		contactGround();
		contactBody();
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

	inline function contactBody()
	{
		// do not pass head through body
		if (isHeadOnBody())
		{
			isHeadAttached = true;
			head.acceleration.y = 0;
			head.velocity.y = 0;
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

	inline function isBaseOnGround()
	{
		return base.y >= base.initialPosY;
	}

	inline function isHeadOnBody()
	{
		// return head.y >= head.initialPosY;
		return body.y - head.y <= distanceHeadToBody;
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
		body.log();
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
		// prevent separation on collides
		immovable = true;
	}

	public function log()
	{
		trace('$style y now $y init $initialPosY');
	}
}
