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
	public var base(get, null):Snowball;
	public var collisionGroup(default, null):FlxTypedGroup<Snowball>;
	public var accelerationFactor:Float = 5;

	function get_base():Snowball
	{
		if (balls.length < 1)
			return null;
		return balls[0];
	}

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
		var base = new Snowball(x, y, "Large", popVelocity, "base", floor);
		torso = new Snowball(x, y - 48, "Mid", popVelocity, "torso", floor);
		head = new Snowball(x, torso.y - 38, "Small", popVelocity, "head", floor);
		torso.ballUnderneath = base;
		head.ballUnderneath = torso;
		collisionGroup.add(base);
		collisionGroup.add(torso);
		collisionGroup.add(head);
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
		// base.log();
		// torso.log();
		head.log();
	}

	public function changeVelocityBy(difference:Float)
	{
		// set base velocity
		balls[0].velocity.x += difference;
		// copy to other balls
		for (i in 1...balls.length)
		{
			balls[i].velocity.x = balls[0].velocity.x;
		}
	}

	public function removeBall(toRemove:Snowball)
	{
		balls.remove(toRemove);
		for (i => b in balls)
		{
			if (b.ballUnderneath == toRemove)
			{
				// that ball is gone, do nothing should have reference to it again
				b.ballUnderneath = null;
				// it is no longer resting, thus should be treated as airborne (for falling logic to work)
				b.isAirborne = true;
			}
			// if it's the first in the stack there is only ground underneath
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

	public function cacheSpeed()
	{
		for (b in balls)
		{
			b.cacheSpeed();
		}
	}

	public function restoreCachedSpeed()
	{
		for (b in balls)
		{
			b.restoreCachedSpeed();
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

	public function log()
	{
		var logText = '$tag y:$y acceleration:$acceleration velocity:$velocity max velocity:$maxVelocity';
		if (ballUnderneath != null)
		{
			logText += 'under is ${ballUnderneath.tag}: $ballUnderneath';
		}
		trace(logText);
	}

	public function pop(?velocityOverride:Float)
	{
		isAirborne = true;
		popVelocity = velocityOverride == null ? popVelocity : velocityOverride;
		// get airborne
		velocity.y = popVelocity * -1;
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
			// fall towards floor by default
			acceleration.y = gravity;

			// if resting on a ball, track that
			if (ballUnderneath != null && !isAirborne)
			{
				velocity.y = ballUnderneath.velocity.y;
				acceleration.y = ballUnderneath.acceleration.y;
			}
		}
		else
		{
			// stop falling
			isAirborne = false;
			acceleration.y = 0;
			velocity.y = 0;
			y -= amountPastBottom;
		}
	}

	public function cacheSpeed()
	{
		velocity.copyTo(cacheVelocity);
		acceleration.copyTo(cacheAcceleration);
		trace('$tag cached v $cacheVelocity a $cacheAcceleration');
	}

	public function restoreCachedSpeed()
	{
		cacheVelocity.copyTo(velocity);
		cacheAcceleration.copyTo(acceleration);
	}

	var cacheVelocity:FlxPoint = FlxPoint.get();

	var cacheAcceleration:FlxPoint = FlxPoint.get();
}
