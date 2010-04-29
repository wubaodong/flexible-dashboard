package com.ignite.olap.views
{
	public class ASPivotGrid extends PivotGrid
	{
		public function ASPivotGrid(dataSource:String,catalog:String,cubeName:String,serverURL:String)
		{//Basically here we want to intialize all the default values
		// as a constructor
		//Cannot have constructors for mxml components so we 
		//do it this wrapping way.
		//<olap:Cube id="cube" dataSource="Provider=Mondrian;DataSource=MondrianFoodMart;"  catalog="FoodMart" name="{_cubeToUse}"
		// serviceURL="{_serverURI}"/>
			super._catalog=catalog;
			super._cubeToUse=cubeName;
			super._dataSource=dataSource;
			super._serverURI=serverURL;
		
			super.initializationComplete();
		}
		
	}
}