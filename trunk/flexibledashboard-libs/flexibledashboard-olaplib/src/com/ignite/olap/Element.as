package  com.ignite.olap
{
import mx.olap.IOLAPDimension;
import mx.olap.IOLAPElement;

public class Element implements IOLAPElement
{
	public var drillDownSelected:Boolean=false;
    public function Element(name:String, uniqueName:String)
    {
        this.name = name;
        this.uniqueName = uniqueName;
    }

    private var _dimension:IOLAPDimension;
    public function set dimension(value:IOLAPDimension):void
    {
        _dimension = value;
    }
    public function get dimension():IOLAPDimension
    {
        return _dimension;
    }

    public function get displayName():String
    {
        return _name;
    }

    private var _name:String;
    public function set name(value:String):void
    {
        this._name = value;
    }
    public function get name():String
    {
        return _name;
    }

    private var _uniqueName:String;
    public function set uniqueName(value:String):void
    {
        this._uniqueName = value;
    }
    public function get uniqueName():String
    {
        return _uniqueName;
    }
	public function isRelated(element:Element):Boolean{
		return isRelatedByName(element.uniqueName);
	}
	private function isRelatedByName(checkName:String):Boolean{
		var rValue:Boolean=false;
		try{
			var rootLoc:int=checkName.indexOf(".");
			var checkRoot:String=checkName;
			if (rootLoc>0){
				checkRoot=(checkName.substr(0,rootLoc));
			}
			return (this._uniqueName.indexOf(checkRoot)>-1);
		}catch(err:Error){}
		return rValue;
	}
}
}
