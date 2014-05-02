package com.asliceofcrazypie.nme;

import flash.Vector;
import nme.display.BitmapData;
import nme.display.Tilesheet;
import nme.events.Event;

#if flash11
import flash.utils.TypedDictionary;
import flash.Vector;
import haxe.Timer;
import nme.display.DisplayObject;
import nme.display.DisplayObjectContainer;
import nme.display.SimpleButton;
import nme.display.Sprite;
import nme.errors.Error;
import nme.utils.Endian;
import flash.display3D.Context3D;
import flash.display3D.Context3DRenderMode;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Program3D;
import flash.display3D.textures.Texture;
import flash.display3D.VertexBuffer3D;
import nme.geom.Matrix3D;
import nme.geom.Vector3D;
import nme.display.Stage;
import nme.display.Graphics;
import nme.Vector;
import nme.errors.ArgumentError;
import nme.utils.ByteArray;
import nme.events.ErrorEvent;
import nme.geom.Matrix;
import nme.geom.Point;
import nme.geom.Rectangle;
#end

/**
 * ...
 * @author Paul M Pepper
 */

class TilesheetStage3D extends Tilesheet
{
	public function new( inImage:BitmapData ) 
	{
		super( inImage );
		
		#if flash11
		
		fallbackMode = FallbackMode.ALLOW_FALLBACK;
		
		if ( !_isInited && !Type.enumEq( fallbackMode, FallbackMode.NO_FALLBACK ) )
		{
			throw new Error( 'Attemping to create TilesheetStage3D object before Stage3D has initialised.' );
		}
		
		if ( context != null && context.context3D != null )
		{
			onResetTexture( null );
			context.addEventListener( ContextWrapper.RESET_TEXTURE, onResetTexture );
		}
		
		#end
	}
	
	#if flash11
	private function onResetTexture(e:Event):Void 
	{
		texture = context.uploadTexture( nmeBitmap );
	}
	
	private var texture:Texture;
	
	//static vars
	private static var context:ContextWrapper;
	private static var _isInited:Bool;
	
	//config
	public var fallbackMode:FallbackMode;
	
	//internal
	private static var _stage:Stage;
	private static var _stage3DLevel:Int;
	private static var _initCallback:String->Void;
	public static inline var MAX_VERTEX_PER_BUFFER:Int = 65532;
	public static inline var MAX_INDICES_PER_BUFFER:Int = 98298;
	
	public static var indices:ByteArray;
	
	public static function init( stage:Stage, stage3DLevel:Int = 0, antiAliasLevel:Int = 5, initCallback:String->Void = null, renderMode:Context3DRenderMode = null ):Void
	{
		if ( !_isInited )
		{
			if ( stage3DLevel < 0 || stage3DLevel >= Std.int( stage.stage3Ds.length ) )
			{
				throw new ArgumentError( 'stage3D depth of '+stage3DLevel+' out of bounds 0-'+(stage.stage3Ds.length-1) );
			}
			
			antiAliasing = antiAliasLevel;
			
			_isInited = true;
			
			context = new ContextWrapper( stage3DLevel );
			
			indices = new ByteArray();
			indices.endian = Endian.LITTLE_ENDIAN;
			
			for ( i in 0...Std.int( ( MAX_VERTEX_PER_BUFFER / 4 ) ) )
			{
				indices.writeShort( (i*4) + 2 );
				indices.writeShort( (i*4) + 1 );
				indices.writeShort( (i*4) + 0 );
				indices.writeShort( (i*4) + 3 );
				indices.writeShort( (i*4) + 2 );
				indices.writeShort( (i*4) + 0 );
			}
			
			_stage = stage;
			_stage3DLevel = stage3DLevel;
			_initCallback = initCallback;
			
			context.init( stage, onContextInit, renderMode );
		}
	}
	
	private static function onContextInit():Void 
	{
		if ( _initCallback != null )
		{
			//really not sure why this delay is needed
			Timer.delay( function(){
			_initCallback( context.context3D == null ? 'failure' : 'success' );
			_initCallback = null;
			},
			50);
		}
	}
	
	public static inline function clearGraphic( graphic:Graphics ):Void
	{
		if ( context != null )
		{
			context.clearGraphic( graphic );
		}
	}
	
	override public function drawTiles(graphics:Graphics, tileData:Array<Float>, smooth:Bool = false, flags:Int = 0,count:Int = -1):Void
	{
		if ( context != null && context.context3D != null && !Type.enumEq( fallbackMode, FallbackMode.FORCE_FALLBACK ) )
		{
			//parse flags
			var isMatrix:Bool = (flags & Tilesheet.TILE_TRANS_2x2) > 0;
			var isScale:Bool = (flags & Tilesheet.TILE_SCALE) > 0;
			var isRotation:Bool = (flags & Tilesheet.TILE_ROTATION) > 0;
			var isRGB:Bool = (flags & Tilesheet.TILE_RGB) > 0;
			var isAlpha:Bool = (flags & Tilesheet.TILE_ALPHA) > 0;
			
			var scale:Float = 1;
			var rotation:Float = 0;
			var cosRotation:Float = Math.cos( rotation );
			var sinRotation:Float = Math.sin( rotation );
			var r:Float = 1;
			var g:Float = 1;
			var b:Float = 1;
			var a:Float = 1;
			
			
			//determine data structure based on flags
			var tileDataPerItem:Int = 3;
			var xOff:Int = 0;
			var yOff:Int = 1;
			var tileIdOff:Int = 2;
			var scaleOff:Int = 3;
			var rotationOff:Int = 3;
			var rOff:Int = 3;
			var gOff:Int = 4;
			var bOff:Int = 5;
			var aOff:Int = 3;
			
			var dataPerVertice:Int = 5;
			
			if ( isMatrix )
			{
				tileDataPerItem += 4;
				rOff += 4;
				gOff += 4;
				bOff += 4;
				aOff += 4;
			}
			else
			{
				if ( isScale )
				{
					tileDataPerItem ++;
					rotationOff++;
					rOff++;
					gOff++;
					bOff++;
					aOff++;
				}
				
				if ( isRotation )
				{
					tileDataPerItem++;
					rOff++;
					gOff++;
					bOff++;
					aOff++;
				}
			}
			
			if ( isRGB )
			{
				tileDataPerItem += 3;
				dataPerVertice += 3;
				aOff+=3;
			}
			
			if ( isAlpha )
			{
				dataPerVertice += 1;
				tileDataPerItem++;
			}
			
			var totalCount = count;
			if (count < 0) {
				totalCount = tileData.length;
			}
			var numItems:Int = Std.int( totalCount / tileDataPerItem );
			
			if ( numItems == 0 )
			{
				return;
			}
			
			if ( totalCount % tileDataPerItem != 0 )
			{
				throw new ArgumentError( 'tileData length must be a multiple of '+tileDataPerItem );
			}
			
			//vertex data
			var indicesPerItem:Int = 6;
			var vertexPerItem:Int = 4;
			var numVertices:Int = numItems * vertexPerItem;
			
			var renderJob:RenderJob;
			
			var tileDataPos:Int = 0;
			var vertexPos:Int = 0;
			
			var transform_tx:Float, transform_ty:Float, transform_a:Float, transform_b:Float, transform_c:Float, transform_d:Float;
			
			///////////////////
			// for each item //
			///////////////////
			var maxNumItems:Int = 16383;
			var startItemPos:Int = 0;
			var numItemsThisLoop:Int = 0;
			
			var spriteSortItem:SpriteSortItem = context.getSpriteSortItem( graphics );
			
			while ( tileDataPos < totalCount )
			{
				numItemsThisLoop = numItems > maxNumItems ? maxNumItems : numItems;
				
				renderJob = RenderJob.getJob();
				renderJob.texture = texture;
				renderJob.isRGB = isRGB;
				renderJob.isAlpha = isAlpha;
				renderJob.isSmooth = smooth;
				renderJob.dataPerVertice = dataPerVertice;
				renderJob.numVertices = numItemsThisLoop * vertexPerItem;
				
				vertexPos = 0;
				
				for( i in 0...numItemsThisLoop )
				{
					//calculate transforms
					transform_tx = tileData[tileDataPos + xOff];
					transform_ty = tileData[tileDataPos + yOff];
					
					if ( isMatrix )
					{
						transform_a = tileData[tileDataPos + 3];
						transform_c = tileData[tileDataPos + 4];
						transform_b = tileData[tileDataPos + 5];
						transform_d = tileData[tileDataPos + 6];
					}
					else
					{
						if ( isScale )
						{
							scale = tileData[tileDataPos+scaleOff];
						}
						
						if ( isRotation )
						{
							rotation = -tileData[tileDataPos + rotationOff];
							cosRotation = Math.cos( rotation );
							sinRotation = Math.sin( rotation );
						}
						
						transform_a = scale * cosRotation;
						transform_c = scale * -sinRotation;
						transform_b = scale * sinRotation;
						transform_d = scale * cosRotation;
					}
					
					if ( isRGB )
					{
						r = tileData[tileDataPos + rOff];
						g = tileData[tileDataPos + gOff];
						b = tileData[tileDataPos + bOff];
					}
					
					if ( isAlpha )
					{
						a = tileData[tileDataPos + aOff];
					}
					
					setVertexData( 
						Std.int( tileData[tileDataPos + tileIdOff] ), 
						transform_tx, 
						transform_ty, 
						transform_a, 
						transform_b, 
						transform_c, 
						transform_d, 
						isRGB, 
						isAlpha, 
						r, 
						g, 
						b, 
						a, 
						renderJob.vertices, 
						vertexPos,
						context.getNextDepth()
					);
					
					tileDataPos += tileDataPerItem;
					vertexPos += vertexPerItem * dataPerVertice;
				}
				
				//push vertices into jobs list
				spriteSortItem.addJob( renderJob );
			}//end while
		}
		else if( !Type.enumEq( fallbackMode, FallbackMode.NO_FALLBACK ) )
		{
			if ( (flags & Tilesheet.TILE_TRANS_2x2) > 0 )
			{
				throw new ArgumentError( 'Fallback mode does not support matrix transformations' );
			}
			
			super.drawTiles(graphics, tileData, smooth, flags,count);
		}
	}
		
	
	
	private inline function setVertexData(tileId:Int, transform_tx:Float, transform_ty:Float, transform_a:Float, transform_b:Float, transform_c:Float, transform_d:Float, isRGB:Bool, isAlpha:Bool, r:Float, g:Float, b:Float, a:Float, vertices:Vector<Float>, vertexPos:Int, depth:Float ):Void 
	{
		var c:Point = tilePoints[tileId];
		
		var uv:Rectangle = tileUVs[tileId];
		
		var tile:Rectangle = tiles[tileId];
		var imgWidth:Int = Std.int( tile.width );
		var imgHeight:Int = Std.int( tile.height );
		
		var centerX:Float = c.x * imgWidth;
		var centerY:Float = c.y * imgHeight;
		
		var px:Float;
		var py:Float;
		
		//top left
		px = -centerX;
		py = -centerY;
		
		var off:Int = 0;
		
		vertices[vertexPos++] = ( px * transform_a + py * transform_c + transform_tx );//top left x
		vertices[vertexPos++] = ( px * transform_b + py * transform_d + transform_ty );//top left y
		vertices[vertexPos++] = ( depth );//top left z
		
		vertices[vertexPos++] = ( uv.x );//top left u
		vertices[vertexPos++] = ( uv.y );//top left v
		
		if ( isRGB )
		{
			vertices[vertexPos++] = ( r );
			vertices[vertexPos++] = ( g );
			vertices[vertexPos++] = ( b );
		}
		
		if ( isAlpha )
		{
			vertices[vertexPos++] = ( a );
		}
		
		//top right
		px = imgWidth-centerX;
		py = -centerY;
		
		vertices[vertexPos++] = ( px * transform_a + py * transform_c + transform_tx );//top right x
		vertices[vertexPos++] = ( px * transform_b + py * transform_d + transform_ty );//top right y
		vertices[vertexPos++] = ( depth );//top right z
		
		vertices[vertexPos++] = ( uv.width );//top right u
		vertices[vertexPos++] = ( uv.y );//top right v
		
		if ( isRGB )
		{
			vertices[vertexPos++] = ( r );
			vertices[vertexPos++] = ( g );
			vertices[vertexPos++] = ( b );
		}
		
		if ( isAlpha )
		{
			vertices[vertexPos++] = ( a );
		}
		
		//bottom right
		px = imgWidth-centerX;
		py = imgHeight-centerY;
		
		vertices[vertexPos++] = ( px * transform_a + py * transform_c + transform_tx );//bottom right x
		vertices[vertexPos++] = ( px * transform_b + py * transform_d + transform_ty );//bottom right y
		vertices[vertexPos++] = ( depth );//bottom right z
		
		vertices[vertexPos++] = ( uv.width );//bottom right u
		vertices[vertexPos++] = ( uv.height );//bottom right v
		
		if ( isRGB )
		{
			vertices[vertexPos++] = ( r );
			vertices[vertexPos++] = ( g );
			vertices[vertexPos++] = ( b );
		}
		
		if ( isAlpha )
		{
			vertices[vertexPos++] = ( a );
		}
		
		//bottom left
		px = -centerX;
		py = imgHeight-centerY;
		
		vertices[vertexPos++] = ( px * transform_a + py * transform_c + transform_tx );//bottom left x
		vertices[vertexPos++] = ( px * transform_b + py * transform_d + transform_ty );//bottom left y
		vertices[vertexPos++] = ( depth );//bottom left z
		
		vertices[vertexPos++] = ( uv.x );//bottom left u
		vertices[vertexPos++] = ( uv.height );//bottom left v
		
		if ( isRGB )
		{
			vertices[vertexPos++] = ( r );
			vertices[vertexPos++] = ( g );
			vertices[vertexPos++] = ( b );
		}
		
		if ( isAlpha )
		{
			vertices[vertexPos++] = ( a );
		}
	}
	
	public static var antiAliasing(default,setAntiAliasing):Int;
	
	private static inline function setAntiAliasing( value:Int ):Int
	{
		antiAliasing = value > 0 ? value < 16 ? value : 16 : 0;//limit value to 0-16
		
		if ( context != null && context.context3D != null )
		{
			context.onStageResize( null );
		}
		
		return antiAliasing;
	}
	
	public static var driverInfo(getDriverInfo, never):String;
	
	private static function getDriverInfo():String
	{
		if ( context != null && context.context3D != null)
		{
			return context.context3D.driverInfo;
		}
		
		return '';
	}
	
	public function dispose():Void
	{
		this.fallbackMode = null;
		
		if ( this.texture != null )
		{
			this.texture.dispose();
			this.texture = null;
		}
		
		if ( this.nmeBitmap != null )
		{
			this.nmeBitmap.dispose();
			this.nmeBitmap = null;
		}
	}
	
	//helper methods
	public static inline function roundUpToPow2( number:Int ):Int
	{
		number--;
		number |= number >> 1;
		number |= number >> 2;
		number |= number >> 4;
		number |= number >> 8;
		number |= number >> 16;
		number++;
		return number;
	}
	
	public static inline function isTextureOk( texture:BitmapData ):Bool
	{
		return ( roundUpToPow2( texture.width ) == texture.width ) && ( roundUpToPow2( texture.height ) == texture.height );
	}
	
	public static inline function fixTextureSize( texture:BitmapData, autoDispose:Bool = false ):BitmapData
	{
		return if ( isTextureOk( texture ) )
		{
			texture;
		}
		else
		{
			var newTexture:BitmapData = new BitmapData( roundUpToPow2( texture.width ), roundUpToPow2( texture.height ), true, 0 );
			
			newTexture.copyPixels( texture, texture.rect, new Point(), null, null, true );
			
			texture.dispose();
			
			newTexture;
		}
	}
	
	
	#end
}

#if flash11

enum FallbackMode
{
	NO_FALLBACK;
	ALLOW_FALLBACK;
	FORCE_FALLBACK;
}

#end