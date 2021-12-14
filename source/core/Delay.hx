package core;

typedef Delay =
{
	duration:Float,
	currentTime:Float,
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
}

class DelayExtensions
{
	static public function wait(d:Delay, elapsed:Float)
	{
		if (!d.isInProgress)
			return;

		d.currentTime += elapsed;
		if (d.currentTime >= d.duration)
		{
			d.isInProgress = d.isResetAuto;
			d.currentTime = 0;
			d.onReady();
		}
	}

	static public function start(d:Delay)
	{
		d.isInProgress = true;
	}
}
