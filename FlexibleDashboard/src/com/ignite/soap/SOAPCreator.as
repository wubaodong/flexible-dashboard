package com.ignite.soap
{
	import com.ignite.olap.Cube;
	import com.igniteanalytics.logging.ASLogger;
	
public class SOAPCreator
{
	public var logger:ASLogger=new ASLogger("com.ignite.soap.SOAPCreator");
	
    public static function execute(cube:Cube, query:String):XML
    {
        var properties:XML = makeProperties(["<DataSourceInfo>"+cube.dataSource+"</DataSourceInfo>",
                                             "<Catalog>"+cube.catalog+"</Catalog>",
                                             "<AxisFormat>TupleFormat</AxisFormat>",
                                            "<Format>Multidimensional</Format> "]);
        var queryNode:XML = <Command></Command>;
        queryNode.appendChild(new XML("<Statement>"+query+"</Statement>"));

        return addSOAPHeader(getExecuteRequest(queryNode, properties));

    }
    public static function getDatasources():XML
    {
        var SOAPEnvelope:XML = addSOAPHeader(getDiscoverRequest(XML(<RequestType>DISCOVER_DATASOURCES </RequestType>),
                                            XML(<Restrictions></Restrictions>), 
                                            XML(<Properties></Properties>)));
        return SOAPEnvelope;
    }
    public static function getCatalogs(dataSourceInfo:String):XML
    {
        var properties:XML = makeProperties(["<DataSourceInfo>"+dataSourceInfo+"</DataSourceInfo>",
                                            "<Format>Tabular </Format> "]);
        var SOAPEnvelope:XML = addSOAPHeader(getDiscoverRequest(XML(<RequestType>DBSCHEMA_CATALOGS </RequestType>),
                                            XML(<Restrictions></Restrictions>), 
                                            properties));
        return SOAPEnvelope;

    }
    public static function getCubes(dataSourceInfo:String, catalog:String):XML
    {
        var properties:XML = makeProperties(["<DataSourceInfo>"+dataSourceInfo+"</DataSourceInfo>",
                                            "<Format>Tabular </Format> "]);
        var restrictions:XML = makeRestrictions(["<CATALOG_NAME>"+catalog+"</CATALOG_NAME>"]);
        var SOAPEnvelope:XML = addSOAPHeader(getDiscoverRequest(XML(<RequestType>MDSCHEMA_CUBES</RequestType>),
                                            restrictions, 
                                            properties));
                                            												//trace (SOAPEnvelope);
        return SOAPEnvelope;
    }
    public static function getDimensions(cube:Cube):XML
    {
        var properties:XML = makeProperties(["<DataSourceInfo>"+cube.dataSource+"</DataSourceInfo>",
                                            "<Format>Tabular </Format> "]);
        var restrictions:XML = makeRestrictions(["<CATALOG_NAME>"+cube.catalog+"</CATALOG_NAME>", 
        										"<CUBE_NAME>"+cube.name+"</CUBE_NAME>"]);
        //var restrictions:XML = makeRestrictions(["<CATALOG_NAME>"+catalog+"</CATALOG_NAME>"]);
        var SOAPEnvelope:XML = addSOAPHeader(getDiscoverRequest(XML(<RequestType>MDSCHEMA_DIMENSIONS</RequestType>),
                                            restrictions, 
                                            properties));
        return SOAPEnvelope;
    }
    public static function getHierarchies(cube:Cube, dimension:String):XML
    {
        var properties:XML = makeProperties(["<DataSourceInfo>"+cube.dataSource+"</DataSourceInfo>",
                                            "<Format>Tabular </Format> "]);
        var restrictions:XML = makeRestrictions(["<CATALOG_NAME>"+cube.catalog+"</CATALOG_NAME>", 
                                                 "<CUBE_NAME>"+cube.name+"</CUBE_NAME>",
                                                 "<DIMENSION_UNIQUE_NAME>"+dimension+"</DIMENSION_UNIQUE_NAME>"]);
        var SOAPEnvelope:XML = addSOAPHeader(getDiscoverRequest(XML(<RequestType>MDSCHEMA_HIERARCHIES</RequestType>),
                                            restrictions, 
                                            properties));
        return SOAPEnvelope;
    }
    public static function getLevels(cube:Cube, dimension:String, hierarchy:String):XML
    {
        var properties:XML = makeProperties(["<DataSourceInfo>"+cube.dataSource+"</DataSourceInfo>",
                                            "<Format>Tabular </Format> "]);
        var restrictions:XML = makeRestrictions(["<CATALOG_NAME>"+cube.catalog+"</CATALOG_NAME>", 
                                                 "<CUBE_NAME>"+cube.name+"</CUBE_NAME>",
                                                 "<DIMENSION_UNIQUE_NAME>"+dimension+"</DIMENSION_UNIQUE_NAME>",
                                                 "<HIERARCHY_UNIQUE_NAME>"+hierarchy+"</HIERARCHY_UNIQUE_NAME>"]);
        var SOAPEnvelope:XML = addSOAPHeader(getDiscoverRequest(XML(<RequestType>MDSCHEMA_LEVELS</RequestType>),
                                            restrictions, 
                                            properties));
        return SOAPEnvelope;
    }

    public static function getMembers(cube:Cube, level:String, dimension:String=null, hierarchy:String=null):XML
    {
        var properties:XML = makeProperties(["<DataSourceInfo>"+cube.dataSource+"</DataSourceInfo>",
                                            "<Format>Tabular </Format> "]);
        var restrictions:XML;
        if ((dimension!=null) && (hierarchy!=null)){
        	restrictions= makeRestrictions(["<CATALOG_NAME>"+cube.catalog+"</CATALOG_NAME>", 
                                                 "<CUBE_NAME>"+cube.name+"</CUBE_NAME>",
                                                 "<DIMENSION_UNIQUE_NAME>"+dimension+"</DIMENSION_UNIQUE_NAME>",
                                                 "<HIERARCHY_UNIQUE_NAME>"+hierarchy+"</HIERARCHY_UNIQUE_NAME>",
                                                 "<LEVEL_UNIQUE_NAME>"+level+"</LEVEL_UNIQUE_NAME>"]);
        }else{
        	if (dimension==null && hierarchy==null){
        			restrictions= makeRestrictions(["<CATALOG_NAME>"+cube.catalog+"</CATALOG_NAME>", 
                                                 "<CUBE_NAME>"+cube.name+"</CUBE_NAME>",
                                                  "<LEVEL_UNIQUE_NAME>"+level+"</LEVEL_UNIQUE_NAME>"]);
      		}else{
      			if (dimension==null){
      				  	restrictions= makeRestrictions(["<CATALOG_NAME>"+cube.catalog+"</CATALOG_NAME>", 
                                                 "<CUBE_NAME>"+cube.name+"</CUBE_NAME>",
                                                 "<HIERARCHY_UNIQUE_NAME>"+hierarchy+"</HIERARCHY_UNIQUE_NAME>",
                                                 "<LEVEL_UNIQUE_NAME>"+level+"</LEVEL_UNIQUE_NAME>"]);
      			}else{
      				  	restrictions= makeRestrictions(["<CATALOG_NAME>"+cube.catalog+"</CATALOG_NAME>", 
                                                 "<CUBE_NAME>"+cube.name+"</CUBE_NAME>",
                                                 "<DIMENSION_UNIQUE_NAME>"+dimension+"</DIMENSION_UNIQUE_NAME>",
                                                 "<LEVEL_UNIQUE_NAME>"+level+"</LEVEL_UNIQUE_NAME>"]);
      			}
      		}
        }
        var SOAPEnvelope:XML = addSOAPHeader(getDiscoverRequest(XML(<RequestType>MDSCHEMA_MEMBERS</RequestType>),
                                            restrictions, 
                                            properties));
        return SOAPEnvelope;
    }

    public static function getMeasures(cube:Cube, dimension:String, hierarchy:String, level:String):XML
    {
        var properties:XML = makeProperties(["<DataSourceInfo>"+cube.dataSource+"</DataSourceInfo>",
                                            "<Format>Tabular </Format> "]);
        var restrictions:XML = makeRestrictions(["<CATALOG_NAME>"+cube.catalog+"</CATALOG_NAME>", 
                                                 "<CUBE_NAME>"+cube.name+"</CUBE_NAME>"]);
        var SOAPEnvelope:XML = addSOAPHeader(getDiscoverRequest(XML(<RequestType>MDSCHEMA_MEASURES</RequestType>),
                                            restrictions, 
                                            properties));
        return SOAPEnvelope;
    }

    public static function addSOAPHeader(node:XML):XML
    {
        var SOAPHeader:XML = <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" >
        <SOAP-ENV:Body>
        </SOAP-ENV:Body> 
        </SOAP-ENV:Envelope>;

        var bodyNode:XML =	SOAPHeader.children()[0];
        bodyNode.appendChild(node);
        return SOAPHeader;
    }

    private static function getDiscoverRequest(request:XML, restrictions:XML, properties:XML):XML
    {
        // SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"
        var SOAPDiscover:XML = <Discover xmlns="urn:schemas-microsoft-com:xml-analysis" >
            </Discover> ;
        SOAPDiscover.appendChild(request);
        SOAPDiscover.appendChild(restrictions);
        SOAPDiscover.appendChild(properties);
        return SOAPDiscover;
    }

    private static function getExecuteRequest(queryNode:XML, properties:XML):XML
    {
        // SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"
        var SOAPExecute:XML = <Execute xmlns="urn:schemas-microsoft-com:xml-analysis" >
            </Execute> ;

        SOAPExecute.appendChild(queryNode);
        SOAPExecute.appendChild(properties);
        return SOAPExecute;
    }


    private static function makeProperties(str:Array):XML
    {
        var properties:XML = <Properties>
                                <PropertyList>
                                </PropertyList> 
                            </Properties>;
        var node:XML = properties.children()[0];
        for( var i:int = 0; i < str.length; i++)
            node.appendChild(new XML(str[i]));
        return properties;
    }
    private static function makeRestrictions(str:Array):XML
    {
        var restrictions:XML = <Restrictions><RestrictionList></RestrictionList></Restrictions>;
        var node:XML = restrictions.children()[0];
        for( var i:int = 0; i < str.length; i++)
            node.appendChild(new XML(str[i]));
        return restrictions;
    }
}

}
