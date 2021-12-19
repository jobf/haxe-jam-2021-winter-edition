class Data
{
	static var inits:LevelStats = {
		maxVelocity: 30,
		bgSpeedFactor: 15,
		snowManVelocityIncrement: 1,
		levelLength: 4000,
		maxVelocityIncrement: 2,
	}

	public static function init()
	{
		level = {
			maxVelocity: inits.maxVelocity,
			bgSpeedFactor: inits.bgSpeedFactor,
			snowManVelocityIncrement: inits.snowManVelocityIncrement,
			levelLength: inits.levelLength,
			maxVelocityIncrement: inits.maxVelocityIncrement,
		}
	}

	public static var level:LevelStats;
}
