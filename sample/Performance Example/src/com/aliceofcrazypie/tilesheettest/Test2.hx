package com.aliceofcrazypie.tilesheettest;

import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.Graphics;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.Event;
import flash.Lib;




#if flash9
import flash.Vector;
#end

/**
 * ...
 * @author Paul M Pepper
 */

#if flash9
class SpriteSortItem
{

	public var sprite(default, null):Sprite;
	public var depths(default,null):Vector<Int>;
	
	public function new( sprite:Sprite )
	{
		this.sprite = sprite;
		this.depths = new Vector<Int>();
	}
	
	public inline function update():Void
	{
		
		this.depths.length = 0;
		
		var parent:DisplayObjectContainer = this.sprite.parent;
		var current:DisplayObjectContainer = sprite;
		
		while ( parent != null )
		{
			depths.push( parent.getChildIndex( current ) );
			
			//work up the tree
			parent = parent.parent;
			current = current.parent;
		}
	}
	
	public function toString():String
	{
		return '[SpriteSortItem depths="'+depths+'"]';
	}
	
	/**
	 * In-place sort of SpriteSortItems
	 * 
	 * @param	items
	 */
	public static inline function sortItems( items:Vector<SpriteSortItem> ):Void
	{
		for ( item in items )
		{
			item.update();
		}
		
		items.sort( sortFunction );
	}
	
	static private function sortFunction( a:SpriteSortItem, b:SpriteSortItem ):Int
	{
		if ( a.sprite == b.sprite )
		{
			return 0;
		}
		
		var currentDepthA:Int;
		var currentDepthB:Int;
		var currentDepthIndA:Int = a.depths.length - 1;
		var currentDepthIndB:Int = b.depths.length - 1;
		
		do
		{
			currentDepthA = a.depths[currentDepthIndA--];
			currentDepthB = b.depths[currentDepthIndB--];
			
			if ( currentDepthA > currentDepthB )
			{
				return -1;
			}
			else if ( currentDepthA < currentDepthB )
			{
				return 1;
			}
		}while ( currentDepthIndA > 0 && currentDepthIndB > 0 );
		
		return b.depths.length - a.depths.length;//this catches situations where one item is the child of another
	}
	

}
#end

class Test2 extends ATest
{

	public function new() 
	{
		super();
	}
	
	override private function init():Void 
	{
		var result:Sprite;
		var sprite:Sprite;
		super.init();
		
		//entry point
		//-create loads of stuff in the display list
		//-and randomly assemble it
		var displayItems:Array<Sprite> = [this];
		var displayListSize:Int = 10000;
		
		for ( i in 0...displayListSize )
		{
			sprite = new Sprite();
			
			displayItems[Math.floor( Math.random() * displayItems.length )].addChild( sprite );
			
			displayItems.push( sprite );
		}
		
		//randomly pick an item somewhere in the list and find it by it's graphic
		var numLookups:Int = 100;
		
		var startTime:Int = Lib.getTimer();
		
		for ( i in 0...numLookups )
		{
			sprite = displayItems[Math.floor( Math.random() * displayItems.length )];
			result = findSpriteByGraphicCached( this, sprite.graphics );
		}
		var endTime:Int = Lib.getTimer();
		var totalTime:Float = (endTime-startTime ) - ( 0.0002 * numLookups );//work out how long the lookup took, taking into account the test overhead
		
		trace( (totalTime / numLookups) + 'ms per lookup, ' + ( totalTime ) + 'ms total' );
		
		#if flash9
		//now try comparing depths
		//-get random items in the display list
		var numDepthItems:Int = 1000;
		var depthItems:Vector<SpriteSortItem> = new Vector<SpriteSortItem>();
		
		/*for ( i in 0...numDepthItems )
		{
			//TODO prevent duplicates
			depthItems[i] = new SpriteSortItem( displayItems[Math.floor( Math.random() * displayItems.length )] );
		}*/
		
		
		
		//get sorted by depth
		startTime = Lib.getTimer();
		SpriteSortItem.sortItems( depthItems );
		endTime = Lib.getTimer();
		
		trace( 'depth sort time: '+( endTime - startTime ) );
		
		
		#end
	}
	
	#if flash9
	private static var graphicCache:Map<Graphics,Sprite>;
	
	public static function __init__():Void
	{
		graphicCache = new Map<Graphics,Sprite>();
	}
	#end
	
	public inline function findSpriteByGraphicCached( start:DisplayObject, graphic:Graphics ):Sprite
	{
		var found:Sprite = null;
		
		#if flash9
		found = graphicCache.get( graphic );
		
		if ( found == null )
		{
		#end
			found = findSpriteByGraphic( start, graphic );
		#if flash9
		}
		
		if ( found != null )
		{
			found.addEventListener(Event.REMOVED_FROM_STAGE, removeFromCache );
			graphicCache.set( graphic, found );
		}
		#end
		return found;
	}
	
	private function removeFromCache(e:Event):Void 
	{
		var target:Sprite = cast( e.target, Sprite );
		
		target.removeEventListener(Event.REMOVED_FROM_STAGE, removeFromCache);
		
		#if flash9
		graphicCache.remove( target.graphics );
		#end
	}
	
	
	public inline function findSpriteByGraphic( start:DisplayObject, graphic:Graphics ):Sprite
	{
		var searchList:Array<DisplayObject> = [start];
		var searchNext:Array<DisplayObject> = [];
		var searchTemp:Array<DisplayObject> = null;
		var found:Sprite = null;
		
		var sprite:Sprite, container:DisplayObjectContainer, button:SimpleButton;
		
		while ( searchList.length > 0 && found == null )
		{
			for ( item in searchList )
			{
				if ( Std.is( item, Sprite ) )
				{
					sprite = cast( item, Sprite );
					
					if ( sprite.graphics == graphic )
					{
						found = sprite;
						break;
					}
				}
				
				if ( Std.is( item, DisplayObjectContainer ) )
				{
					container = cast( item, DisplayObjectContainer );
					
					for ( i in 0...container.numChildren )
					{
						searchNext.push( container.getChildAt( i ) );
					}
				}
				else if ( Std.is( item, SimpleButton ) )
				{
					button = cast( item, SimpleButton );
					
					if ( button.downState != null )
					{
						searchNext.push( button.downState );
					}
					if ( button.upState != null )
					{
						searchNext.push( button.upState );
					}
					if ( button.overState != null )
					{
						searchNext.push( button.overState );
					}
				}
			}
			
			if ( found == null )
			{
				searchTemp = searchList;
				searchList = searchNext;
				searchNext = searchTemp;
				
				clear( searchNext );
			}
		}
		
		return found;
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