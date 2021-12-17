package core;

class FramesHelper
{
	public var numCols(default, null):Int;
	public var numRows(default, null):Int;
	public var frameSizeW(default, null):Int;
	public var frameSizeH(default, null):Int;

	public function new(assetPath:String, frameSize:Int, numCols:Int, numRows:Int, ?frameSizeH:Int = null)
	{
		this.numCols = numCols;
		this.numRows = numRows;
		this.frameSizeW = frameSize;

		if (frameSizeH == null)
		{
			this.frameSizeH = frameSize;
		}
		else
		{
			this.frameSizeH = frameSizeH;
		}
		var region = new FlxRect(0, 0, numCols * this.frameSizeW, numRows * this.frameSizeH);
		_frames = FlxTileFrames.fromRectangle(assetPath, new FlxPoint(this.frameSizeW, this.frameSizeH), region);
	}

	var _frames:FlxTileFrames;

	public function getFrames():FlxTileFrames
	{
		return _frames;
	}
}
