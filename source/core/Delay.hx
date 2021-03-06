package core;

typedef Delay =
{
	duration:Float,
	currentTime:Float,
	isInProgress:Bool,
	isResetAuto:Bool,
	?onReady:() -> Void
}

typedef DelayDistance =
{
	stepTravelled:Float,
	lastTravelled:Float,
	isInProgress:Bool,
	isResetAuto:Bool,
	?onReady:() -> Void
}

class DelayFactory
{
	var framesPerSecond:Float;

	public function new(framesPerSecond:Float = 60)
	{
		this.framesPerSecond = framesPerSecond;
	}

	public function Default(durationSeconds:Float, onReady:() -> Void, isStarted:Bool = false, isResetAuto:Bool = false):Delay
	{
		return {
			duration: (durationSeconds * framesPerSecond) * (1 / framesPerSecond),
			isInProgress: isStarted,
			currentTime: 0.0,
			isResetAuto: isResetAuto,
			onReady: onReady
		};
	}

	public function DefaultAuto(durationSeconds:Float, onReady:() -> Void, isStarted:Bool = true, isResetAuto:Bool = true):Delay
	{
		return {
			duration: (durationSeconds * framesPerSecond) * (1 / framesPerSecond),
			isInProgress: isStarted,
			currentTime: 0.0,
			isResetAuto: isResetAuto,
			onReady: onReady
		};
	}
}

class DelayExtensions
{
	static public function wait(d:Delay, elapsed:Float):Bool
	{
		if (!d.isInProgress)
			return false;

		d.currentTime += elapsed;
		if (d.currentTime >= d.duration)
		{
			d.isInProgress = d.isResetAuto;
			d.currentTime = 0;
			d.onReady();
			return true;
		}

		return false;
	}

	static public function stop(d:Delay)
	{
		d.isInProgress = false;
		d.currentTime = 0;
	}

	static public function start(d:Delay)
	{
		d.isInProgress = true;
	}
}

class DelayDistanceExtensions
{
	static public function start(d:DelayDistance, initialTravelled:Float)
	{
		d.isInProgress = true;
		d.lastTravelled = initialTravelled;
	}

	static public function wait(d:DelayDistance, travelled:Float)
	{
		if (!d.isInProgress)
			return;

		if (travelled - d.lastTravelled > d.stepTravelled)
		{
			d.lastTravelled = travelled;
			// trace('d.currentTime ${d.currentTime} total $total d.duration ${d.duration}');
			d.isInProgress = d.isResetAuto;
			// d.currentTime = 0;
			d.onReady();
		}
	}
}
