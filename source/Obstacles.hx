typedef CollisionBox =
{
	var w:Int;
	var h:Int;
	var x:Int;
	var y:Int;
};

class Rock extends Obstacle
{
	public function new(x, y, key = 1, frames:FlxTileFrames, isPermanent:Bool = true)
	{
		super(x, y, key, frames, isPermanent);
	}
}

class Collectible extends Obstacle
{
	override function remove()
	{
		// send sprite skyward
		this.acceleration.y = -2500;
		// fade out and remove from play
		this.fadeOut(0.5, tween ->
		{
			this.kill();
		});
	}
}

class Obstacle extends FlxSprite
{
	public var isHit(default, null):Bool;
	public var key(default, null):Int;

	var isPermanent:Bool;

	public function new(x, y, key:Int, frames:FlxTileFrames, isPermanent:Bool = false)
	{
		super(x, y);
		this.key = key;
		this.frames = frames;
		animation.frameIndex = key;
		this.isPermanent = isPermanent;
		isHit = false;
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
		#if debug
		drawDebug();
		#end
		if (x < (width * 2) * -1)
		{
			kill();
			visible = false;
		}
	}
}

class ObstaclesGround extends ObstacleGenerator<Rock>
{
	public function new()
	{
		super(new FramesHelper("assets/images/obstacles-ground-192x4.png", 192, 4, 1), (x, y) ->
		{
			var key = FlxG.random.int(0, 3);
			var obstacle = new Rock(x, y, key, asset.getFrames());
			collisionGroup.add(obstacle);
			obstacle.animation.frameIndex = key;
			obstacle.setSize(15, 15);
			obstacle.centerOffsets();
			return obstacle;
		});
	}
}

class ObstaclesAir extends ObstacleGenerator<Obstacle>
{
	public function new()
	{
		super(new FramesHelper("assets/images/obstacles-air-256x2.png", 256, 2, 1), (x, y) ->
		{
			var key = FlxG.random.int(0, 1);
			var obstacle = new Obstacle(x, y, key, asset.getFrames());
			collisionGroup.add(obstacle);
			obstacle.setSize(35, 25);
			obstacle.centerOffsets();
			return obstacle;
		});
	}
}

class Collectibles extends ObstacleGenerator<Collectible>
{
	public function new()
	{
		super(new FramesHelper("assets/images/obstacles-collectible-128x1.png", 128, 1, 3), (x, y) ->
		{
			var key = FlxG.random.int(0, 2);
			var obstacle = new Collectible(x, y, key, asset.getFrames());
			collisionGroup.add(obstacle);
			obstacle.setSize(35, 25);
			obstacle.centerOffsets();
			return obstacle;
		});
	}
}

class ObstacleGenerator<T:Obstacle>
{
	public var collisionGroup(default, null):FlxTypedGroup<T>;

	var asset:FramesHelper;
	var generate:(Int, Int) -> T;

	public function new(asset:FramesHelper, generate:(Int, Int) -> T)
	{
		collisionGroup = new FlxTypedGroup<T>();
		this.asset = asset;
		this.generate = generate;
	}

	public function get(x:Int, y:Int):T
	{
		var obstacle = generate(x, y);
		collisionGroup.add(obstacle);
		return obstacle;
	}
}
