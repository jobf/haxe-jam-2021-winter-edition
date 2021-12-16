class Rock extends Obstacle
{
	public function new(x, y, key = 1, isPermanent:Bool = true)
	{
		super(x, y, key, isPermanent);
	}
}

class Obstacle extends FlxSprite
{
	public var isHit(default, null):Bool;
	public var key(default, null):Int;

	var isPermanent:Bool;

	public function new(x, y, key:Int, isPermanent:Bool = false)
	{
		super(x, y);
		this.key = key;
		animation.frameIndex = key;
		this.isPermanent = isPermanent;
		isHit = false;
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
}

class ObstaclesGround extends ObstacleGenerator<Rock>
{
	public function new()
	{
		super(new FramesHelper("assets/images/obstacles-ground-192x4.png", 192, 4, 1), (x, y) ->
		{
			var key = FlxG.random.int(0, 3);
			var obstacle = new Rock(x, y, key);
			collisionGroup.add(obstacle);
			obstacle.frames = asset.getFrames();
			obstacle.animation.frameIndex = key;
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
			var obstacle = new Obstacle(x, y, key);
			collisionGroup.add(obstacle);
			obstacle.frames = asset.getFrames();
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
