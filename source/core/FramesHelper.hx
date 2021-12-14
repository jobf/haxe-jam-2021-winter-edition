package core;

class FramesHelper
{
	public function new(assetPath:String, frameSize:Int, numCols:Int, numRows:Int, ?frameSizeH:Int = null)
	{
		if (frameSizeH == null)
		{
			frameSizeH = frameSize;
		}
		var region = new FlxRect(0, 0, numCols * frameSize, numRows * frameSizeH);
		_frames = FlxTileFrames.fromRectangle(assetPath, new FlxPoint(frameSize, frameSizeH), region);
	}

	var _frames:FlxTileFrames;

	public function getFrames():FlxTileFrames
	{
		return _frames;
	}
}
