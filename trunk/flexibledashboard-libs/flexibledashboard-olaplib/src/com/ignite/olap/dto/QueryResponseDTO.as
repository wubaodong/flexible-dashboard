package com.ignite.olap.dto 
{
	import mx.olap.IOLAPQuery;
	
	public class QueryResponseDTO
	{
		
		public var mdxString:String;
		public var results:Object;
		public var updateSelectorsWithResults:Boolean=false;
		public var createSelectors:Boolean=false;
		public var query:IOLAPQuery;
		
		public function QueryResponseDTO()
		{
		}

	}
}