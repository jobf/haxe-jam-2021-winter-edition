package core;

class SpriteExtensions
{
	public static function moveMiddleX(sprite:FlxSprite, x:Float)
	{
		sprite.x += x - (sprite.width * 0.5);
	}
}
