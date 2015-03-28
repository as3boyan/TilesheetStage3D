package com.asliceofcrazypie.nme;

#if flash11
import flash.display3D.IndexBuffer3D;
import flash.display3D.textures.Texture;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.VertexBuffer3D;
import flash.Vector;
import flash.Vector;
import nme.errors.Error;

/**
 * ...
 * @author Paul M Pepper
 */
class RenderJob 
{
	public var texture:Texture;
	public var vertices(default, null):Vector<Float>;
	public var isRGB:Bool;
	public var isAlpha:Bool;
	public var isSmooth:Bool;
	
	public var dataPerVertice:Int;
	public var numVertices(default, setNumVertices):Int;
	public var numIndices(default, null):Int;
	
	private static var renderJobPool:Array<RenderJob>;
	
	public static inline var NUM_JOBS_TO_POOL:Int = 25;
	
	public function new()
	{
		this.vertices = new Vector<Float>( TilesheetStage3D.MAX_VERTEX_PER_BUFFER>>2 );
	}
	
	private inline function setNumVertices( n:Int ):Int
	{
		this.numVertices = n;
		
		this.numIndices = Std.int( (numVertices / 2) * 3 );
		
		return n;
	}
	
	public inline function render( context:ContextWrapper ):Void
	{
		if ( context.context3D.driverInfo != 'Disposed' )
		{
			context.setProgram(isRGB,isAlpha,isSmooth);//assign appropriate shader
				
			context.setTexture( texture );
			
			//actually create the buffers
			var vertexbuffer:VertexBuffer3D = null;
			var indexbuffer:IndexBuffer3D = null;
			
			// Create VertexBuffer3D. numVertices vertices, of dataPerVertice Numbers each
			vertexbuffer = context.context3D.createVertexBuffer(numVertices, dataPerVertice);
			
			// Upload VertexBuffer3D to GPU. Offset 0, numVertices vertices
			vertexbuffer.uploadFromVector( vertices, 0, numVertices );
			
			// Create IndexBuffer3D.
			indexbuffer = context.context3D.createIndexBuffer(numIndices);
			// Upload IndexBuffer3D to GPU.
			indexbuffer.uploadFromByteArray( TilesheetStage3D.indices, 0, 0, numIndices );
			
			// vertex position to attribute register 0
			context.context3D.setVertexBufferAt (0, vertexbuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			// UV to attribute register 1
			context.context3D.setVertexBufferAt(1, vertexbuffer, 3, Context3DVertexBufferFormat.FLOAT_2);
			
			if ( isRGB && isAlpha )
			{
				context.context3D.setVertexBufferAt(2, vertexbuffer, 5, Context3DVertexBufferFormat.FLOAT_4);//rgba data
			}
			else if ( isRGB )
			{
				context.context3D.setVertexBufferAt(2, vertexbuffer, 5, Context3DVertexBufferFormat.FLOAT_3);//rgb data
			}
			else if ( isAlpha )
			{
				context.context3D.setVertexBufferAt(2, vertexbuffer, 5, Context3DVertexBufferFormat.FLOAT_1);//a data
			}
			else
			{
				context.context3D.setVertexBufferAt(2, null, 5);
			}
			
			context.context3D.drawTriangles( indexbuffer );
		}
	}
	
	public static inline function getJob():RenderJob
	{
		return renderJobPool.length > 0 ? renderJobPool.pop() : new RenderJob();
	}
	
	public static inline function returnJob( renderJob:RenderJob ):Void
	{
		if ( renderJobPool.length < NUM_JOBS_TO_POOL )
		{
			renderJobPool.push( renderJob );
		}
	}
	
	public static function __init__():Void
	{
		renderJobPool = [];
		
		for ( i in 0...NUM_JOBS_TO_POOL )
		{
			renderJobPool.push( new RenderJob() );
		}
	}
}

#end