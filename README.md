TilesheetStage3D
================

This is a class which extends openfl.display.Tilesheet and adds stage3D support to the drawTiles method, if available.

Ported to Haxe 3/OpenFL by AS3Boyan

Original repository: https://code.google.com/p/tilesheet-stage3d/

Currently it's not very fast at rendering lots of sprites, but at least, it's much better than default Flash fallback(In tilelayer).
Also it has much lower CPU consumption.

### How to use it
    //Init Stage3D
    #if flash11
        TilesheetStage3D.init(stage, 0, 5, init, Context3DRenderMode.AUTO);
    #else
        init();
    #end
		
    function init(?result:String):Void
    {
    //init
    addEventListener(Event.ENTER_FRAME, onEnterFrame);
    }
		
    //Add this before calling drawTiles to onEnterFrame handler
    #if flash11
    TilesheetStage3D.clearGraphic(graphics);
    #end

You can use TilesheetStage3D under the terms of the MIT license.

OpenFL Stage3D drawTiles thread:
http://www.openfl.org/developer/forums/general-discussion/stage3d-based-drawtiles-implementation-alpha/
