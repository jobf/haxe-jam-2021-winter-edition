class Rock extends FlxSprite
{
	public var weight(default, null):Int;

	public var isHit(default, null):Bool;

	public function new(x, y, rockWeight)
	{
		super(x, y);
		weight = rockWeight + 1;
		isHit = false;
	}

	public function collide()
	{
		// trace('explode');
		isHit = true;
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
