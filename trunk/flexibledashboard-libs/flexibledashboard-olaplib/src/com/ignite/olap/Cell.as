package com.ignite.olap
{
	import mx.olap.IOLAPCell;
public class Cell implements IOLAPCell
{
    private var xml:XML
    public var colTuple:Tuple;
    public var rowTuple:Tuple;
    public function Cell(xml:XML)
    {
        this.xml = xml;
    }
    public function get value():Number
    {
        var valueNode:XML = xml.children()[0];
        return Number(valueNode.children()[0]);
    }        
        
    /**
     *  The formatted value in the cell.
     */
    public function get formattedValue():String
    {
    	var mddNS:Namespace= new Namespace( "urn:schemas-microsoft-com:xml-analysis:mddataset");
		
        return String((xml..mddNS::FmtValue)[0]);
    }
     /**
     *  The formatted value in the cell.
     */
    public function get formatString():String
    {
    	var mddNS:Namespace= new Namespace( "urn:schemas-microsoft-com:xml-analysis:mddataset");
		
        return String((xml..mddNS::FormatString)[0]);
    }
}
}