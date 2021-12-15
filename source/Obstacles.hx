class Rock extends Obstacle
{
	public var weight(default, null):Int;

	public function new(x, y, rockWeight)
	{
		super(x, y, true);
		weight = rockWeight + 1;
	}
}

class Obstacle extends FlxSprite
{
	public var isHit(default, null):Bool;

	var isPermanent:Bool;

	public function new(x, y, isPermanent:Bool = false)
	{
		super(x, y);
		isHit = false;
		this.isPermanent = isPermanent;
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

class Rocks
{
	public var collisionGroup(default, null):FlxTypedGroup<Rock>;

	var framesHelper:FramesHelper;

	public function new()
	{
		collisionGroup = new FlxTypedGroup<Rock>();
		framesHelper = new FramesHelper("assets/images/rocks.png", 40, 3, 1);
	}

	public function getRock(x:Int, y:Int, weight:Int = 0):Rock
	{
		var rock = new Rock(x, y, weight);
		collisionGroup.add(rock);
		rock.frames = framesHelper.getFrames();
		rock.animation.frameIndex = weight;
		return rock;
	}
}

class Birds
{
	public var collisionGroup(default, null):FlxTypedGroup<Obstacle>;

	var framesHelper:FramesHelper;

	public function new()
	{
		collisionGroup = new FlxTypedGroup<Obstacle>();
		framesHelper = new FramesHelper("assets/images/bird.png", 106, 1, 1, 81);
	}

	public function get(x:Int, y:Int):Obstacle
	{
		var bird = new Obstacle(x, y);
		collisionGroup.add(bird);
		bird.frames = framesHelper.getFrames();
		bird.setSize(35, 25);
		bird.centerOffsets();
		return bird;
	}
}
