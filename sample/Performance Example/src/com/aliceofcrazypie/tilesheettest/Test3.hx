package com.aliceofcrazypie.tilesheettest;
import nme.events.Event;
import nme.system.Capabilities;

/**
 * ...
 * @author Paul M Pepper
 */

class Test3 extends ATest
{

	public function new() 
	{
		super();
	}
	
	override private function init():Void 
	{
		super.init();
		
		stage.addEventListener(Event.RESIZE, onResize );
		
		onResize();
	}
	
	private function onResize(e:Event=null):Void 
	{
		graphics.clear();
		graphics.lineStyle( 0, 0xCCCCCC, 0.8 );
		
		//draw a grid
		var cm1:Float = Capabilities.screenDPI / 2.54;
		trace( Capabilities.screenDPI );
		var xPos:Float = 0;
		
		while ( ( xPos += cm1 ) < stage.stageWidth )
		{
			graphics.moveTo( Math.floor( xPos ), 0 );
			graphics.lineTo( Math.floor( xPos ), stage.stageHeight );
		}
		
		var yPos:Float = 0;
		
		while ( ( yPos += cm1 ) < stage.stageHeight )
		{
			graphics.moveTo( 0, Math.floor( yPos ) );
			graphics.lineTo( stage.stageWidth, Math.floor( yPos ) );
		}
	}
}