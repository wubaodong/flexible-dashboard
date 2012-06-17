package com.ignite.olap.browser
{
import mx.controls.advancedDataGridClasses.AdvancedDataGridGroupItemRenderer;
import mx.controls.advancedDataGridClasses.AdvancedDataGridListData;
import mx.olap.IOLAPAttribute;
import mx.olap.IOLAPCube;
import mx.olap.IOLAPDimension;
import mx.olap.IOLAPHierarchy;
import mx.olap.IOLAPLevel;
import mx.olap.IOLAPMember;
           

	

public class CubeRenderer extends AdvancedDataGridGroupItemRenderer
{
	public function CubeRenderer(){
		super();
		mouseEnabled=true;
	
	}
	override public function get width():Number
	{
		if(listData)
		{
			return 160+AdvancedDataGridListData(listData).indent
		}
		return super.width;
	}
	
    public var _node:Object;
    
    override public function set data(value:Object):void
	{
		super.data = value;
		this._node=value;
		
		if(label)
		{
		//	label.background = true;
	    	var color:uint = 0xFFFFFF;
	    	
			if(value is IOLAPCube){
				color = ColorCodes.cubeColor;
			
			}	
			else if (value is IOLAPDimension){
                color = ColorCodes.dimensionColor;
   			}
			else if (value is IOLAPAttribute){
                color = ColorCodes.attributeColor;
                
   			}
			else if (value is IOLAPHierarchy){
                color = ColorCodes.hierarchyColor;
   			}
			else if (value is IOLAPLevel){
                color = ColorCodes.levelColor;
   			}    
            else if (value is IOLAPMember){
                color = ColorCodes.memberColor;
            }
            else{
                color = ColorCodes.defaultColor;
            }
          //  label.backgroundColor = color;
            label.alpha = 1;
         //   this.addEventListener(MouseEvent.MOUSE_DOWN,mouseDownHandler);
         
         //   this.filters = [new GradientGlowFilter(), new DropShadowFilter()];
		}
	}
}
}
class ColorCodes
{
    public static const cubeColor:int = 0xFF9933;
    public static const dimensionColor:int = 0xFF99CC;
    public static const hierarchyColor:int = 0x66CC99;
    public static const attributeColor:int = 0x3399CC;
    public static const levelColor:int = 0xAAAAAA;
    public static const memberColor:int = 0xCCCC66;
    public static const defaultColor:int = 0xCC3366;
}
