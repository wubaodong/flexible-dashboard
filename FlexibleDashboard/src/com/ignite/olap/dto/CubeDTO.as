package com.ignite.olap.dto
{
	public class CubeDTO
	{
		public var _dataSource:String;
		public var _catalog:String;
		public var _cubeName:String;
		
		public function CubeDTO(dataSource:String, catalog:String, cubeName:String)
		{
			this._dataSource=dataSource;
			this._catalog=catalog;
			this._cubeName=cubeName;
		}
		
		public function getConnectionString():String{
			return _dataSource;
		}

	}
}