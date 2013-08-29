package com.aliceofcrazypie.tilesheettest;
import com.asliceofcrazypie.flash.TilesheetStage3D;
import net.hires.debug.Stats;
import flash.display.DisplayObject;
import openfl.display.Tilesheet;
import flash.events.KeyboardEvent;
import flash.geom.Point;
import openfl.Assets;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.events.Event;
import flash.geom.Rectangle;
import flash.Lib;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.ui.Keyboard;
import flash.utils.Timer;

/**
 * ...
 * @author Paul M Pepper
 */

class Test1 extends ATest
{
	private var tilesheet:TilesheetStage3D;
	private var cols:Int;
	private var rows:Int;
	private var tileData:Array<Float>;
	private var smooth:Bool;
	private var isRGB:Bool;
	private var isAlpha:Bool;
	private var stats:DisplayObject;
	private var instructions:TextField;
	private var totals:TextField;

	public function new() 
	{
		super();
	}
	
	override private function init():Void 
	{
		//entry point
		var bmp:BitmapData = Assets.getBitmapData( 'img/Rock.png' ).clone();
		var rect:Rectangle = bmp.rect.clone();
		#if flash11
		bmp = TilesheetStage3D.fixTextureSize( bmp, true );
		#end
		var center:Point = new Point( rect.width * 0.5, rect.height * 0.5 );
		
		tilesheet = new TilesheetStage3D( bmp );
		tilesheet.addTileRect( rect, center );
		
		cols = 138;
		rows = 118;
		
		addEventListener( Event.ENTER_FRAME, onEnterFrame );
		stage.addEventListener( Event.RESIZE, onStageResize );
		
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
		tileData = [];
		
		stats = new Stats();
		
		totals = new TextField();
		totals.width = 200;
		totals.height = 20;
		totals.autoSize = TextFieldAutoSize.LEFT;
		totals.selectable = false;
		totals.mouseEnabled = false;
		totals.wordWrap = true;
		totals.multiline = true;
		totals.defaultTextFormat = new TextFormat( '_sans', 12, 0xFFFFFF );
		
		updateTotals();
		
		instructions = new TextField();
		instructions.width = 200;
		instructions.height = 200;
		instructions.autoSize = TextFieldAutoSize.LEFT;
		instructions.selectable = false;
		instructions.mouseEnabled = false;
		instructions.wordWrap = true;
		instructions.multiline = true;
		instructions.defaultTextFormat = new TextFormat( '_sans', 12, 0xCCCCCC );
		
		instructions.text = "Spacebar toggles smoothing\nInsert toggles RGB effect\nDelete toggles Alpha Effect\nHome/End increase/decrease rows\nPage Up/Down increase/decrease columns\n\nMoving mouse rotates/scales\n\nNumpad +/- Increases/decreased Antialiasing\n\nEnter toggles between stage3D and fallback rendering\n\nEscape triggers context loss";
		
		addChild( stats );
		addChild( totals );
		addChild( instructions );
		
		onStageResize(null);
	}
	
	override public function dispose():Void 
	{
		removeEventListener( Event.ENTER_FRAME, onEnterFrame );
		stage.removeEventListener( Event.RESIZE, onStageResize );
		
		stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
		
		#if flash11
		TilesheetStage3D.clearGraphic( graphics );
		tilesheet.dispose();
		#end
		
		graphics.clear();
		
		super.dispose();
	}
	
	private inline function updateTotals():Void
	{
		totals.text = 'Sprites: ' + ( cols * rows ) + ' (' + cols + 'x' + rows + ')';
		#if flash11
		totals.text += "\nRenderer: " + ( Type.enumEq( tilesheet.fallbackMode, FallbackMode.FORCE_FALLBACK ) ? 'fallback renderer' : TilesheetStage3D.driverInfo + "\nAntialias: "+TilesheetStage3D.antiAliasing );
		#end
	}
	
	private function onStageResize(e:Event):Void 
	{
		stats.x = stage.stageWidth - stats.width;
		instructions.x = Math.floor( stage.stageWidth - instructions.width );
		totals.x = Math.floor( stage.stageWidth - totals.width );
		totals.y = Math.ceil( stats.height );
		instructions.y = Math.ceil( stats.height + totals.height );
	}
	
	private function keyPressed(e:KeyboardEvent):Void 
	{
		switch( e.keyCode )
		{
			case Keyboard.PAGE_UP:
			{
				cols++;
			}
			case Keyboard.PAGE_DOWN:
			{
				cols--;
				cols = Std.int( Math.max( cols, 2 ) );
			}
			case Keyboard.HOME:
			{
				rows++;
			}
			case Keyboard.END:
			{
				rows--;
				rows = Std.int( Math.max( rows, 2 ) );
			}
			case Keyboard.SPACE:
			{
				smooth = !smooth;
			}
			case Keyboard.INSERT:
			{
				isRGB = !isRGB;
			}
			case Keyboard.DELETE:
			{
				isAlpha = !isAlpha;
			}
			case Keyboard.NUMPAD_ADD:
			{
				#if flash11
				TilesheetStage3D.antiAliasing++;
				#end
			}
			case Keyboard.NUMPAD_SUBTRACT:
			{
				#if flash11
				TilesheetStage3D.antiAliasing--;
				#end
			}
			case Keyboard.ENTER:
			{
				#if flash11
				tilesheet.fallbackMode = Type.enumEq( tilesheet.fallbackMode, FallbackMode.ALLOW_FALLBACK ) ? FallbackMode.FORCE_FALLBACK : FallbackMode.ALLOW_FALLBACK;
				#end
			}
			case Keyboard.ESCAPE:
			{
				#if flash11
				stage.stage3Ds[0].context3D.dispose();
				#end
			}
			default:
		}
		
		
	}
	
	private function onEnterFrame(e:Event):Void 
	{
		var flags:Int = Tilesheet.TILE_SCALE | Tilesheet.TILE_ROTATION ;
		
		if ( isRGB )
		{
			flags |= Tilesheet.TILE_RGB;
		}
		
		if ( isAlpha )
		{
			flags |= Tilesheet.TILE_ALPHA;
		}
		
		var padding:Float = 10;
		
		var spacingX:Float = ( stage.stageWidth - ( padding * 2 ) ) / (cols-1);
		var spacingY:Float = ( stage.stageHeight - ( padding * 2 ) ) / (rows-1);
		var scale:Float = 0.1+(( stage.mouseY / stage.stageHeight ) * 1 );
		var rotation:Float = ( stage.mouseX / stage.stageWidth ) * Math.PI * 2;
		
		var alphaVal:Float = isAlpha ? Math.abs( Math.sin( Lib.getTimer() / 1000 ) ) : 1;
		
		for ( x in 0...cols )
		{
			for ( y in 0...rows )
			{
				tileData.push( padding + ( x * spacingX ) );
				tileData.push( padding + ( y * spacingY ) );
				tileData.push( 0 );
				tileData.push( scale );
				tileData.push( rotation );
				
				if ( isRGB )
				{
					tileData.push( x / cols );
					tileData.push( y/rows );
					tileData.push( 1 );
				}
				
				if ( isAlpha )
				{
					tileData.push( alphaVal );
				}
			}
		}
		
		#if flash11
		//TilesheetStage3D.clear();
		TilesheetStage3D.clearGraphic( graphics );
		#end
		
		graphics.clear();
		
		tilesheet.drawTiles( graphics, tileData, smooth, flags );
		
		clear( tileData );
		
		updateTotals();
	}
	
	//misc methods
	public static inline function clear<T>( array:Array<T> ):Void
	{
		#if (cpp||php)
           array.splice(0,array.length);          
        #else
           untyped array.length = 0;
        #end
	}
	
}