package com.ignite.olap
{
import com.igniteanalytics.logging.ASLogger;

import mx.collections.ArrayCollection;
import mx.collections.IList;
import mx.olap.IOLAPCell;
import mx.olap.IOLAPCube;
import mx.olap.IOLAPDimension;
import mx.olap.IOLAPHierarchy;
import mx.olap.IOLAPLevel;
import mx.olap.IOLAPMember;
import mx.olap.IOLAPQuery;
import mx.olap.IOLAPResult;
import mx.olap.IOLAPResultAxis;

public class MDDatasetResult implements IOLAPResult
{
	
	public var logger:ASLogger=new ASLogger("com.ignite.olap.MDDatasetResult");
	
    private var _cube:IOLAPCube;
    public function MDDatasetResult(data:XML, cube:IOLAPCube)
    {
    							logger.logDebug("MDDatasetResult instantiation");
        this._cube = cube;
        getXMLAResults(data);
    }
    private var _axes:Array = [];
    public function get axes():Array
    {
        return _axes;
    }

    public function getAxis(axisOrdinal:int):IOLAPResultAxis
    {
        if(axisOrdinal < _axes.length)
            return _axes[axisOrdinal];
        return null;
    }
    private var _query:IOLAPQuery;
    public function get query():IOLAPQuery
    {
        return _query;
    }

    private var cellData:Array;
    public var numCols:int;
    public var numRows:int;
    public function getCell(x:int, y:int):IOLAPCell
    {
    	if (cellData)
	        if(cellData[x] && cellData[x][y])
	            return cellData[x][y];
        return null
    }
    
    public function xmlaHasErrors(data:XML):Boolean{
    	
		return getXMLAError(data)!=null;
    }
    public function getXMLAError(data:XML):String{
    	//SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"
        var soapEnv:Namespace=new Namespace("http://schemas.xmlsoap.org/soap/envelope/");
        var nsXA:Namespace= new Namespace( "http://mondrian.sourceforge.net");
    	try{
	    		var xml:XMLList=data..soapEnv::Fault;
		    	if (xml!=null && xml.length()>0){
		    		var xmlError:XMLList=data..nsXA::error;
		    		var faultCode:String = xmlError..code;
		        	var faultDesc:String = xmlError..desc;
					return faultCode +":"+faultDesc;
		    	}else{
		    		return null;
		    	}
    	}catch(err:Error){
    	}
    		return null;
    }
    private function getXMLAResults(data:XML):void
    {
       /*
			XMLA Result snippet:
			<Axis name="Axis1">
			−
			<Tuples>
			−
				<Tuple>
					−
					<Member Hierarchy="Store Type">
					−
					<UName>
					[Store Type].[All Store Types].[Deluxe Supermarket]
					</UName>
					<Caption>Deluxe Supermarket</Caption>
					<LName>[Store Type].[Store Type]</LName>
					<LNum>1</LNum>
					<DisplayInfo>0</DisplayInfo>
					</Member>
				</Tuple>
			
			*/
		
		if (data!=null){
			logger.logDebug("getXMLAResults data length:"+data.length());
			if (xmlaHasErrors(data)){
				throw new Error(getXMLAError(data),Errors.XMLA_CONTAINS_ERROR);
			}
		}else{
			logger.logError("getXMLAResults data is null");
			throw new Error("No XMLA Result to parse",Errors.XMLA_NOT_PARSEABLE);
		}
			
		var mddNS:Namespace= new Namespace( "urn:schemas-microsoft-com:xml-analysis:mddataset");
		var nsXA:Namespace= new Namespace( "http://mondrian.sourceforge.net");
		
		var dim:IOLAPDimension;
        var hier:IOLAPHierarchy;
        var level:IOLAPLevel;
        var mem:IOLAPMember;
					
        var axesInfoXML:XMLList = (data..mddNS::Axis);				
  		var axisNum:int = axesInfoXML.length();
       
       try{																	logger.logDebug("getXMLAResults getting tuples numAxis:"+axisNum);
		        //Ticket 11
				//Reset flatt data collection'
				_flatResults=null;
		        //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
		        
		        for ( var i:int = 0; i < axisNum; i++)
		        { 
		            var axis:ResultAxis = new ResultAxis();
		            _axes.push(axis);
		            var axisXML:XML = axesInfoXML[i];
		            var tuplesXML:XMLList = axisXML..mddNS::Tuple;
		            var tupleNum:int = tuplesXML.length();						logger.logDebug("getXMLAResults num tuples:"+tupleNum);
		            for (var j:int= 0; j < tupleNum; j++)					
		            {															logger.logDebug("getXMLAResults tuple:"+tuplesXML[j].toString().substr(0,34));	
		                var tuple:Tuple = new Tuple();
		                var tupelMembers:XMLList = tuplesXML[j]..mddNS::Member;	
		                var memNum:int = tupelMembers.length();					logger.logDebug("getXMLAResults members:"+memNum);
		                for ( var k:int = 0;  k < memNum; k++)					
		                {
		                    var memXML:XML = tupelMembers[k];
		                    var hierName:String = memXML.@Hierarchy;
		
		                    dim = getDimension(hierName);
		                    if(dim)
		                    {
		                        hier = getHierarchy(hierName, dim);
		                        if(hier)
		                        {
		                            level = getLevel((memXML..mddNS::LName)[0].children()[0], hier);
		                            if(level)
		                            {
		                                mem = getMember((memXML..mddNS::UName)[0].children()[0], level);
		                                if(mem)
		                                    Tuple(tuple).addMember(mem);		logger.logDebug("getXMLAResults member added:"+mem.uniqueName);
		                            }
		                        }
		                    }
		
		                    dim = null;
		                    hier = null;
		                    level = null;
		                    mem = null;
		                }
		                axis.addTuple(tuple);
		            }
		        }
		        if (_axes && _axes.length>0){
			        numCols = _axes[0].positions.length;					logger.logDebug("getXMLAResults getting celldata from xml");
			        numRows = _axes[1].positions.length;
			        
			        //Now the cellData									
			        var cellDataXML:XMLList = data..mddNS::Cell;
			        axisNum = cellDataXML.length();
			        cellData = [];										logger.logDebug("getXMLAResults found "+axisNum+" cellOrdinals");
			        for ( i = 0; i < axisNum; i++)
			        {
			            var cellOrdinal:int = int(cellDataXML[i].@CellOrdinal);		
			            var row:int = cellOrdinal/numCols;
			            var col:int = cellOrdinal%numCols;
			
			            if(!cellData[row])
			                cellData[row] = [];
			            var newCell:Cell=new Cell(cellDataXML[i]);
			            newCell.colTuple=Tuple(ResultAxis(_axes[0]).positions.getItemAt(col));
			            newCell.rowTuple=Tuple(ResultAxis(_axes[1]).positions.getItemAt(row));
			            cellData[row][col] =newCell; 
			            //Ticket 11
			            buildFlatResults(newCell);
		        	}
		        }
			}catch(err:Error){
				var id:Number=Math.random();
				logger.logError("getXMLAResults "+id+" "+err.errorID+" "+err.message);
				logger.logError("getXMLAResults "+id+" "+data.toXMLString());
			}
    }
    //TICKET 11-------------------------------------------
    public var _flatResults:ArrayCollection;
    private function buildFlatResults(cell:Cell):void{
    	if (_flatResults==null){
    		_flatResults=new ArrayCollection();
    	}
    	var newEntry:Object=new Object();
    	try{newEntry.rowUName=cell.rowTuple.members[0].uniqueName;}catch(err:Error){}
    	try{newEntry.colUName=cell.colTuple.members[0].uniqueName;}catch(err:Error){}
    	try{newEntry.formattedValue=cell.formattedValue;}catch(err:Error){}
    	try{newEntry.value=cell.value;}catch(err:Error){}
    	try{newEntry.rowDisplayName=cell.rowTuple.members[0].displayName;}catch(err:Error){}
    	try{newEntry.colDisplayName=cell.colTuple.members[0].displayName;}catch(err:Error){}
    	_flatResults.addItem(newEntry);
    }
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    public function getDimension(hName:String):IOLAPDimension
    {
    	
        var dName:String = hName;
        if (hName.indexOf("]")>0){
        	dName=hName.substring(1, hName.indexOf("]"));
        }
        return _cube.findDimension(dName);
    }
    public function getHierarchy(hName:String, d:IOLAPDimension):IOLAPHierarchy
    {
        var hName:String = hName;
        if (hName.indexOf("]")>0){
        	hName=hName.substring(hName.lastIndexOf("[")+1, hName.lastIndexOf("]"));
        }
        var h:IOLAPHierarchy = d.findAttribute(hName);
        if(h)
            return h;
        return d.findHierarchy(hName);
    }
    public function getLevel(lName:String, h:IOLAPHierarchy):IOLAPLevel
    {
        var lName:String = lName;
        if (lName.indexOf("]")>0){
        	lName=lName.substring(lName.lastIndexOf("[")+1, lName.lastIndexOf("]"));
        }
        return h.findLevel(lName);
    }

    public function getMember(uName:String, l:IOLAPLevel):IOLAPMember
    {
        var mName:String;
        if (uName.indexOf("UNKNOWNMEMBER") > 0 || uName.indexOf("UnknownMember") > 0)
		{
			// nothing	
		}

        if(uName.charAt(uName.length-1) == "]")
            mName = uName.substring(uName.lastIndexOf("[")+1, uName.lastIndexOf("]"));
        else
            mName = uName.substring(uName.lastIndexOf(".")+1);
        if(mName == "UNKNOWNMEMBER")
            mName = "Unknown";

        var list:IList = l.findMember(mName);
        if(list)
            for ( var i:int = 0;  i < list.length; i++)
                if(list[i].uniqueName == uName)
                    return list[i];
        
        //Haven't seen this member yet
        var m:Member = new Member(mName, uName);
        Level(l).addMember(m);
        return m;
    }
}
}




