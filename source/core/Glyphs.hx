package core;

class Glyphs
{
	public function new(assetPath, characterSet, sizeP)
	{
		var graphic = FlxGraphic.fromAssetKey(assetPath);
		font = FlxBitmapFont.fromMonospace(graphic, characterSet, new FlxPoint(sizeP, sizeP));
	}

	public function getText(text:String, x:Int = 0, y:Int = 0)
	{
		var t = new FlxBitmapText(font);
		t.letterSpacing -= 20;
		t.lineSpacing = 15;
		t.alignment = CENTER;
		// t.autoSize = false;
		// t.multiLine = true;
		// t.fieldWidth = 180;
		// t.wordWrap = true;
		t.x = x;
		t.y = y;
		t.text = text;
		return t;
	}

	var font:FlxBitmapFont;
}
