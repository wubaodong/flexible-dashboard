package com.ignite.olap
{
import com.igniteanalytics.logging.ASLogger;

import mx.olap.IOLAPQuery;
import mx.olap.IOLAPQueryAxis;
public class Query implements IOLAPQuery
{
	public static var logger:ASLogger=new ASLogger("com.ignite.olap.Query");
	
    public function Query(query:String)
    {
    	if (query!=null && query!=""){
 	   		this.query = query;
       	 mdxFormat=true;	
    	}
        
    }
	public var mdxFormat:Boolean=false;
    public var query:String;
	
	
	public var allowEmpty:Boolean=false;
	
	public var axes:Array=new Array(10);
    public function getAxis(axisOrdinal:int):IOLAPQueryAxis
    {
        return axes[axisOrdinal];
    }

    public function setAxis(axisOrdinal:int, axis:IOLAPQueryAxis):void
    {
    	axes[axisOrdinal]=axis;
    }
   
}
}
