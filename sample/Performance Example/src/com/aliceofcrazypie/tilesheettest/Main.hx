package com.aliceofcrazypie.tilesheettest;

import com.asliceofcrazypie.flash.TilesheetStage3D;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.Lib;
import flash.ui.Keyboard;

#if flash11
import flash.display3D.Context3DRenderMode;
#end

/**
 * ...
 * @author Paul M Pepper
 */

class Main extends Sprite 
{
	private var curTest:ATest;
	
	public function new() 
	{
		super();
		#if iphone
		Lib.current.stage.addEventListener(Event.RESIZE, init);
		#else
		addEventListener(Event.ADDED_TO_STAGE, init);
		#end
	}

	private function init(e) 
	{
		// entry point
		#if flash11
		TilesheetStage3D.init( stage, 0, 5, engineReady, Context3DRenderMode.AUTO );
		#else
		engineReady();
		#end
	}
	
	private function engineReady( result:String = '' ):Void
	{
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
		setTest( 1 );
	}
	
	private function keyPressed(e:KeyboardEvent):Void 
	{
		switch( e.keyCode )
		{
			case Keyboard.NUMBER_1:
			{
				setTest( 1 );
			}
			case Keyboard.NUMBER_2:
			{
				setTest( 2 );
			}
			case Keyboard.NUMBER_3:
			{
				setTest( 3 );
			}
			case Keyboard.NUMBER_4:
			{
				setTest( 4 );
			}
			default:
			{
				//ignore
			}
		}
	}
	
	private function setTest( testNum:Int ):Void
	{
		if ( curTest != null )
		{
			curTest.dispose();
			curTest = null;
		}
		
		var newTest:ATest = null;
		
		switch( testNum )
		{
			case 1:
			{
				newTest = new Test1();
			}
			case 2:
			{
				newTest = new Test2();
			}
			case 3:
			{
				newTest = new Test3();
			}
			case 4:
			{
				newTest = new Test4();
			}
			default:
			{
				trace( 'unknown test: '+testNum );
			}
		}
		
		if ( newTest != null )
		{
			curTest = newTest;
			addChild( newTest );
		}
	}
	
	static public function main() 
	{
		var stage = Lib.current.stage;
		stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		stage.align = flash.display.StageAlign.TOP_LEFT;
		
		Lib.current.addChild(new Main());
	}
	
}
