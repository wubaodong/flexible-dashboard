package com.ignite.olap
{
import mx.olap.IOLAPAttribute;
public class AttributeHierarchy extends Hierarchy
    implements IOLAPAttribute
{
    public function AttributeHierarchy(name:String, uniqueName:String)
    { 
        super(name, uniqueName);
    }
}
}
