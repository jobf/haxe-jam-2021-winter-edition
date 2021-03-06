package;

typedef LevelStats =
{
	var maxVelocity:Float;
	var bgSpeedFactor:Float;
	var snowManVelocityIncrement:Float;
	var levelLength:Float;
	var maxVelocityIncrement:Float;
}

typedef Dimensions =
{
	var heightV:Int;
	var widthV:Int;
	var heightC:Int;
	var widthC:Int;
};

class SnowBalls
{
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
	var isJumpReady:Bool = true;
	var popCoolOff:Delay;
	var isPopReady:Bool = true;
	var maxVelocity:Float;
	var popVelocity:Float = 350;
	var gravity:Float = 700;
	var balls:Array<Snowball> = [];
	var asset:FramesHelper;

	public function new(x, y, maxVelocity)
	{
		collisionGroup = new FlxTypedGroup<Snowball>();
		this.maxVelocity = maxVelocity;
		asset = new FramesHelper("assets/images/snow-100x100-4x4.png", 100, 4, 4);

		var ballDimensions:Array<Dimensions> = [
			{
				widthC: 20,
				heightC: 20,
				widthV: 40,
				heightV: 40
			},
			{
				widthC: 22,
				heightC: 22,
				widthV: 52,
				heightV: 52
			},
			{
				widthC: 30,
				heightC: 32,
				widthV: 74,
				heightV: 74
			}
		];

		var totalHeight = 0;
		for (d in ballDimensions)
		{
			totalHeight += d.heightV;
		}
		var floor = y + totalHeight;

		var base = new Snowball(x, floor - ballDimensions[2].heightV, popVelocity, "base", floor, asset.getFrames(), ballDimensions[2]);
		base.maxVelocity.x = maxVelocity;
		collisionGroup.add(base);
		balls.push(base);

		var torso = new Snowball(x, base.y - ballDimensions[1].heightV, popVelocity, "torso", floor, asset.getFrames(), ballDimensions[1]);
		torso.maxVelocity.x = maxVelocity;
		torso.ballUnderneath = base;
		collisionGroup.add(torso);
		balls.push(torso);

		var head = new Snowball(x, torso.y - ballDimensions[0].heightV, popVelocity, "head", floor, asset.getFrames(), ballDimensions[0]);
		head.maxVelocity.x = maxVelocity;
		head.ballUnderneath = torso;
		collisionGroup.add(head);
		balls.push(head);

		jumpCoolOff = BaseState.delays.Default(0.2, setJumpIsReady, true);
		popCoolOff = BaseState.delays.Default(0.2, setPopIsReady, true);
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

	public function jump(?jumpVelocityPercentage:Float, readyOverride:Bool = false)
	{
		if (isJumpReady || readyOverride)
		{
			if (base.alive && !base.isAirborne)
			{
				base.pop(jumpVelocityPercentage);
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

	public function changeVelocityBy(difference:Float)
	{
		// set base velocity
		base.velocity.x += difference;
		base.angularVelocity = (base.velocity.x * 3.1) * 2;
		// copy to other balls
		final torsoIndex = 1;
		for (i in torsoIndex...balls.length)
		{
			balls[i].velocity.x = base.velocity.x;
			balls[i].acceleration.x = base.acceleration.x;
		}
	}

	public function removeBall(toRemove:Snowball)
	{
		if (balls.length == 0)
		{
			return;
		}
		toRemove.remove();
		if (toRemove.tag != "head")
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

	public function addBallsTo(group:FlxSpriteGroup)
	{
		for (b in balls)
		{
			group.add(b);
		}
	}
}

class Snowball extends FlxSprite
{
	public var hitCount:Int;

	var maxHits:Int = 3;

	public var ballUnderneath:Snowball;
	public var isAirborne:Bool;

	public var tag(default, null):String;

	var popVelocity:Float;
	var gravity:Float = 700;

	public var floor(default, null):Float;

	var cacheVelocity:FlxPoint = FlxPoint.get();
	var cacheAcceleration:FlxPoint = FlxPoint.get();
	var cacheAngularVelocity:Float = 0;
	var minimumFrameIndex:Int;
	var dimensions:Dimensions;

	public function new(x, y, popVelocity:Float, tag:String, floor:Float, frames:FlxTileFrames, dimensions:Dimensions)
	{
		super(x, y);
		this.dimensions = dimensions;
		this.tag = tag;
		isAirborne = false;
		this.popVelocity = popVelocity;
		maxVelocity.y = popVelocity;
		this.floor = floor;
		this.frames = frames;
		// color = FlxColor.fromRGB(240, 514, 117, 255); #bsod
		minimumFrameIndex = switch (tag)
		{
			case "torso": 4;
			case "base": 8;
			case _: 0;
		}
		var isHead = minimumFrameIndex == 0;
		maxHits = isHead ? 3 : 2;
		syncFrameWithHealth();
		hitCount = 0;
		setSize(dimensions.heightC, dimensions.widthC);
		centerOffsets();
	}

	public function remove()
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
			var hitsRemaining = maxHits - hitCount;
			if (hitsRemaining <= 1)
			{
				this.color = FlxColor.CYAN;
			}
			if (hitsRemaining <= 0)
			{
				this.remove();
				survives = false;
			}
			else
			{
				syncFrameWithHealth();
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

	public function pop(velocityPercentage:Float = 1.0)
	{
		isAirborne = true;
		// var vpopVel = velocityOverride == null ? popVelocity : popVelocity * velocityOverride;
		// get airborne
		velocity.y = (popVelocity * velocityPercentage) * -1;
	}

	var spriteHeight = 60;

	public function currentBottomEdge():Float
	{
		return y + dimensions.heightV;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		// don't go backwards
		if (velocity.x < 0)
		{
			velocity.x = 0;
			acceleration.x = 0;
		}
		var cannotBeFurtherThan = ballUnderneath == null ? floor : ballUnderneath.y;
		var amountPastBottom = currentBottomEdge() - cannotBeFurtherThan;
		if (amountPastBottom < 0)
		{
			// fall towards floor by default
			acceleration.y = gravity;
		}
		else
		{
			// stop falling
			isAirborne = false;
			acceleration.y = 0;
			velocity.y = 0;
			y -= amountPastBottom;
			if (ballUnderneath == null)
			{
				// always rotate clockwise on the ground
				angularVelocity = Math.abs(angularVelocity);
			}
		}
		if (ballUnderneath != null && !isAirborne)
		{
			velocity.y = ballUnderneath.velocity.y;
			angularVelocity = ballUnderneath.angularVelocity * -1;
			// acceleration.y = ballUnderneath.acceleration.y;
		}
	}

	public function cacheSpeed()
	{
		velocity.copyTo(cacheVelocity);
		acceleration.copyTo(cacheAcceleration);
		cacheAngularVelocity = angularVelocity;
		trace('$tag cached v $cacheVelocity a $cacheAcceleration');
	}

	public function restoreCachedSpeed()
	{
		cacheVelocity.copyTo(velocity);
		cacheAcceleration.copyTo(acceleration);
		angularVelocity = cacheAngularVelocity;
	}

	function syncFrameWithHealth()
	{
		var frameIndex = (maxHits - hitCount);
		if (frameIndex < minimumFrameIndex)
		{
			frameIndex = minimumFrameIndex;
		}
		animation.frameIndex = frameIndex;
	}
}
