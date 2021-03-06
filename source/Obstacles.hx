class Rock extends Obstacle
{
	public function new(x, y, key = 1, frames:FlxTileFrames, dimensions:Dimensions, isPermanent:Bool = true)
	{
		super(x, y, key, frames, [], dimensions, isPermanent);
	}
}

class Bird extends Obstacle
{
	public function new(x, y, key = 0, frames:FlxTileFrames, dimensions:Dimensions)
	{
		var oscAmount = FlxG.random.int(2, 10);
		var oscTime = FlxG.random.float(0.1, 0.4);
		var tweenLength = oscTime + 0.1;
		if (key > 0)
		{
			oscAmount *= 3;
			oscTime *= 2;
			tweenLength *= 2;
		}

		var behaviours:Array<Delay> = [
			BaseState.delays.DefaultAuto(tweenLength, () ->
			{
				FlxTween.tween(this, {y: y + oscAmount}, oscTime);
			}),
			BaseState.delays.DefaultAuto(tweenLength, () ->
			{
				FlxTween.tween(this, {y: y + oscAmount * -1}, oscTime);
			})
		];
		// if it's a big bird (key 1), add glide behaviour
		if (key == 1)
		{
			behaviours.push(BaseState.delays.DefaultAuto(tweenLength * 2, () -> {
				// glide (do nothing for a bit before starting again)
			}));
		}

		super(x, y, key, frames, behaviours, dimensions);
	}
}

class Collectible extends Obstacle
{
	public function new(x, y, key = 1, frames:FlxTileFrames, dimensions:Dimensions)
	{
		var oscAmount = FlxG.random.int(2, 10);
		var oscTime = FlxG.random.float(0.1, 0.4);
		var tweenLength = oscTime + 0.1;

		var behaviours:Array<Delay> = [
			BaseState.delays.DefaultAuto(tweenLength, () ->
			{
				FlxTween.tween(this, {y: y + oscAmount * -1}, oscTime);
			}),
			BaseState.delays.DefaultAuto(tweenLength, () ->
			{
				FlxTween.tween(this, {y: y + oscAmount}, oscTime);
			}),
			BaseState.delays.DefaultAuto(tweenLength, () ->
			{
				FlxTween.tween(this, {y: y + oscAmount}, oscTime);
			}),
			BaseState.delays.DefaultAuto(tweenLength, () ->
			{
				FlxTween.tween(this, {y: y + oscAmount * -1}, oscTime);
			}),
		];

		super(x, y, key, frames, behaviours, dimensions);
	}

	override function remove()
	{
		// send sprite skyward
		this.acceleration.y = -500;
		// fade out and remove from play
		this.fadeOut(1.5, tween ->
		{
			this.kill();
		});
		FlxTween.tween(this.scale, {x: 7, y: 7}, 0.75);
	}
}

class Carrot extends FlxSprite
{
	var blinkFrameIndex:Int = 1;
	var blinkedFor:Float = 0;
	var blinkDuration:Float = 1.05;

	public function new(x, y)
	{
		super(x, y);
		var asset = new FramesHelper("assets/images/carrot-110x124-2x1.png", 110, 2, 1, 124);
		frames = asset.getFrames();
		animation.frameIndex = 0;
		// oscillate carrot
		FlxTween.tween(this, {y: y - 15}, 1.1, {type: PINGPONG});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// blink
		if (animation.frameIndex != blinkFrameIndex && blinkedFor == 0)
		{
			var blinkChance = FlxG.random.int(0, 100);
			if (blinkChance > 80)
			{
				blinkedFor += elapsed;
				animation.frameIndex = blinkFrameIndex;
			}
		}
		else if (animation.frameIndex == blinkFrameIndex)
		{
			blinkedFor += elapsed;
			if (blinkedFor >= blinkDuration)
			{
				blinkedFor = 0;
				animation.frameIndex = 0;
			}
		}
	}
}

class Obstacle extends FlxSprite
{
	public var isHit(default, null):Bool;
	public var key(default, null):Int;
	public var warning:Warning;
	public var centerX(get, default):Float;
	public var centerY(get, default):Float;
	public var maxDistance(default, null):Int;

	public function get_centerX():Float
	{
		return x + dimensions.widthV * 0.5;
	}

	public function get_centerY():Float
	{
		return y + dimensions.heightV * 0.5;
	}

	var isPermanent:Bool;
	var blinkFrameIndex:Int;
	var blinkedFor:Float = 0;
	var blinkDuration:Float = 1.05;
	var behaviours:Array<Delay>;
	var behaviorIndex = 0;
	var dimensions:Dimensions;
	var showWarning:Bool = true;

	public var oscillationFactor:Float = 0;

	public function new(x, y, key:Int, frames:FlxTileFrames, behaviours:Array<Delay>, dimensions:Dimensions, isPermanent:Bool = false)
	{
		maxDistance = FlxG.width + 300;
		super(maxDistance, y);
		this.key = key;
		this.frames = frames;
		animation.frameIndex = key;
		blinkFrameIndex = key + frames.numCols;
		this.isPermanent = isPermanent;
		this.behaviours = behaviours;
		this.dimensions = dimensions;
		isHit = false;
		setSize(this.dimensions.widthC, this.dimensions.heightC);
		centerOffsets();
		#if debug
		this.debugBoundingBoxColorNotSolid = FlxColor.MAGENTA;
		this.debugBoundingBoxColor = FlxColor.MAGENTA;
		this.debugBoundingBoxColorSolid = FlxColor.MAGENTA;
		this.ignoreDrawDebug = false;
		#end
	}

	public function collide()
	{
		if (!isHit && !isPermanent)
		{
			this.remove();
		}
		isHit = true;
	}

	function remove()
	{
		FlxTween.tween(this, {x: x + FlxG.random.int(1000, 2000), y: y - FlxG.random.int(-1000, 2000)}, 0.7, {
			onComplete: tween ->
			{
				this.kill();
			}
		});
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		warning.y = y;

		final scaleOffset = 0.3;
		if (x < FlxG.width && showWarning)
		{
			showWarning = false;
			this.warning.fadeOut(0.15, tween -> this.warning.kill());
		}
		else
		{
			var distanceTraveledFromSpawnToEdge = maxDistance - x;
			var percentTraveled = distanceTraveledFromSpawnToEdge / maxDistance;
			warning.scale.x = percentTraveled + scaleOffset;
			warning.scale.y = percentTraveled + scaleOffset;
		}
		#if debug
		drawDebug();
		#end
		var disposeThreshold = (width * 2) * -1;
		if (x < disposeThreshold)
		{
			visible = false;
			kill();
		}

		// blink
		if (animation.frameIndex != blinkFrameIndex && blinkedFor == 0)
		{
			var blinkChance = FlxG.random.int(0, 1000);
			if (blinkChance > 990)
			{
				blinkedFor += elapsed;
				animation.frameIndex = blinkFrameIndex;
			}
		}
		else if (animation.frameIndex == blinkFrameIndex)
		{
			blinkedFor += elapsed;
			if (blinkedFor >= blinkDuration)
			{
				blinkedFor = 0;
				animation.frameIndex = key;
			}
		}

		// behaviours
		if (behaviours.length > 0)
		{
			if (behaviours[behaviorIndex].wait(elapsed))
			{
				behaviorIndex++;
				if (behaviorIndex > behaviours.length - 1)
				{
					behaviorIndex = 0;
				}
			}
		}
	}
}

class ObstaclesGround extends ObstacleGenerator<Rock>
{
	public function new()
	{
		var dimensionsMap:Map<Int, Dimensions> = [
			0 => {
				heightV: 13,
				widthV: 30,
				heightC: 7,
				widthC: 7
			},
			1 => {
				heightV: 28,
				widthV: 110,
				heightC: 10,
				widthC: 60
			},
			2 => {
				heightV: 72,
				widthV: 196,
				heightC: 20,
				widthC: 100
			},
			3 => {
				heightV: 95,
				widthV: 135,
				heightC: 40,
				widthC: 70
			}
		];
		super(new FramesHelper("assets/images/ground-200x100-4x2.png", 200, 4, 2, 100), dimensionsMap, (x, y, key) ->
		{
			if (key < 0)
			{
				key = FlxG.random.int(0, 3);
			}
			var obstacle = new Rock(x, y, key, asset.getFrames(), dimensions[key]);
			collisionGroup.add(obstacle);
			obstacle.animation.frameIndex = key;

			return obstacle;
		});
	}
}

class ObstaclesAir extends ObstacleGenerator<Obstacle>
{
	public function new()
	{
		var dimensionsMap:Map<Int, Dimensions> = [
			0 => {
				heightV: 30,
				widthV: 56,
				heightC: 15,
				widthC: 25
			},
			1 => {
				heightV: 68,
				widthV: 180,
				heightC: 4,
				widthC: 120
			}
		];
		super(new FramesHelper("assets/images/air-200x100-2x1.png", 200, 2, 1, 100), dimensionsMap, (x, y, key) ->
		{
			if (key < 0)
			{
				key = FlxG.random.int(0, 1);
			}

			var obstacle = new Bird(x, y, key, asset.getFrames(), dimensions[key]);
			collisionGroup.add(obstacle);

			return obstacle;
		});
	}
}

class Collectibles extends ObstacleGenerator<Collectible>
{
	public function new()
	{
		var dimensionsMap:Map<Int, Dimensions> = [
			0 => {
				heightV: 40,
				widthV: 40,
				heightC: 26,
				widthC: 26
			},
			1 => {
				heightV: 40,
				widthV: 40,
				heightC: 26,
				widthC: 26
			},
			2 => {
				heightV: 40,
				widthV: 40,
				heightC: 26,
				widthC: 26
			}
		];
		super(new FramesHelper("assets/images/points-50x50-3x2.png", 50, 3, 2), dimensionsMap, (x, y, key) ->
		{
			if (key < 0)
			{
				key = FlxG.random.int(0, 2);
			}
			var obstacle = new Collectible(x, y, key, asset.getFrames(), dimensionsMap[key]);
			collisionGroup.add(obstacle);
			var oscMin = key * 3;
			var oscMax = oscMin * key;
			obstacle.oscillationFactor = FlxG.random.float(oscMin, oscMax);
			return obstacle;
		});
	}
}

class ObstacleGenerator<T:Obstacle>
{
	public var collisionGroup(default, null):FlxTypedGroup<T>;
	public var dimensions(default, null):Map<Int, Dimensions>;

	var asset:FramesHelper;
	var alertKey:Int = 1;
	var alertAsset:FramesHelper;
	var generate:(Int, Int, Int) -> T;

	public function new(asset:FramesHelper, dimensions:Map<Int, Dimensions>, generate:(Int, Int, Int) -> T)
	{
		collisionGroup = new FlxTypedGroup<T>();
		this.asset = asset;
		this.alertAsset = new FramesHelper("assets/images/alerts-60x60-3x1.png", 60, 3, 1);
		this.dimensions = dimensions;
		this.generate = generate;
	}

	public function get(x:Int, y:Int, key:Int = -1):T
	{
		var obstacle = generate(x, y, key);
		collisionGroup.add(obstacle);
		final warningX = 838;
		obstacle.warning = new Warning(warningX, y, alertKey, alertAsset.getFrames(), obstacle);
		return obstacle;
	}

	public function getTests(x, y):Array<Obstacle>
	{
		var tests:Array<Obstacle> = [];
		for (key in 0...asset.numCols)
		{
			tests.push(get(x + key * asset.frameSizeW, y, key));
		}
		return tests;
	}
}

class Warning extends FlxSprite
{
	var approaching:FlxSprite;

	public function new(x, y, key:Int, frames:FlxTileFrames, approaching:FlxSprite)
	{
		super(x, y);
		this.frames = frames;
		this.approaching = approaching;
		this.animation.frameIndex = key;
	}
}
