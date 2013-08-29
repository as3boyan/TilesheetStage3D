package com.aliceofcrazypie.tilesheettest;
import nme.display.Sprite;
import nme.events.Event;

/**
 * ...
 * @author Paul M Pepper
 */

class ATest extends Sprite
{

	public function new() 
	{
		super();
		
		stage != null ? _init() : addEventListener(Event.ADDED_TO_STAGE, _init);
	}
	
	private function _init(e:Event=null):Void 
	{
		if ( e != null)
		{
			removeEventListener(Event.ADDED_TO_STAGE, _init);
		}
		
		init();
	}
	
	private function init():Void
	{
		//to be overridden
	}
	
	public function dispose():Void
	{
		if ( parent != null )
		{
			parent.removeChild( this );
		}
		//to be overridden
	}
}