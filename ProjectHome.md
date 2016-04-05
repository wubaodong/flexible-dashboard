Update 8/2/2012: [FlexibleDashboard+Liferay](http://code.google.com/p/flexible-liferay/) now available: extension of FlexibleDashboard with Liferay backend, uses Liferay to manage user/group config of BI Dashboards/etc. mixing FlexibleDashboard Flex pods and regular portlets

Update 6/17/2012: Mobile AIR version of FlexibleDashboard for iOS and Android tablets now available (built Android version download available, iOS version can be built from common source).

<a href='http://integratedsemantics.org/wp-content/uploads/2011/02/flexibledashboard-bld3-1.png' title='FlexibleDashboard+AIR'><img src='http://integratedsemantics.org/wp-content/uploads/2011/02/flexibledashboard-bld3-2.png' alt='FlexibleDashboard+AIR' /></a>

Started with esria dashboard / adobe flex devnet dashboard sample and evolved it:

Added flexmdi cascade/tile (esria pod drag/drop in tile mode) and more pods, and both flex+browser and flex+air versions

Was Adobe Flex 3 based. In Build 3 introduced a first cut at Flex 4 / Spark.

In Build4:
  * Pods now in separate flex modules
  * Each use of a pod/module can be configured/autowired separately with Spring ActionScript in context.xml files in src/spring-actionscript/ (currently used in 3 differently configured GridPods and 1 ChartGridPod). Basic config still in data/flexibleDashboardAirPods.xml
  * Added simple IDataService, SoapDataService, XmlDataService, RemoteObjectDataService (for data from BlazeDS, etc.) These are configured in spring-actionscript/-context.xml files and which kind of dataservice injected / autowired into GridPod and ChartGridPod

**FlexibleDashoard (Flex+Browser)pods:**
line, bar, pie charts, JasperReports viewer, BIRT Report viewer, OLAP pivotable grid  with XMLA datasource support and mdx query editor (from Grebulon sourceforge project), Pentaho Charts, Spring ActionScript configured GridPod and ChartGridPod for BlazeDS data sources, simple blazeds pod, external Flex app SWFLoader, calendar, iframe html.

OLAP pivotable grid / mdx query editor has been tested with the following XMLA data sources: Mondrian, Pentaho, and IBM InfoSphere Warehouse Cubing Services.

**FlexibleDashboardAir (Flex+AIR) pods:**
FlexibleDashboard pods plus additional AIR pods: webkit HTML, web browser, Google gadgets, Liferay portlets, local files browser

**Plans / Roadmap:**
Plan to add support for semantic data sources / semantic data integration, and more visualization support. Support Apache Flex (test Apache Flex 4.8 that is the same as Adobe Flex 4.6, and also support newer versions of Apache Flex that add features, etc.) Also plan to have a HTML5/CSS/JavaScript version of FlexibleDashboard.

**Extensions / customizations** of FlexibleDashboard are available in other google code projects also from Integrated Semantics:

**FlexibleDashboard+Liferay:**
[FlexibleDashboard+Liferay](http://code.google.com/p/flexible-liferay/) provides a key extension of FlexibleDashboard for management of user dashboard configs and group collaboration on BI Dashboards,etc. It extends FlexibleDashboard with a Liferay backend to manage user/group dashboards mixing Flex pods without html wrappers and regular Liferay portlets (with FlexibleDashboard thus being a Flex based portal container for Liferay).

**FlexibleShare:**
[FlexibleShare](http://code.google.com/p/flexibleshare/) extends FlexibleDashboard with FlexSpaces pods: (Alfreso doc mgt / workflow / OpenCalais semantic auto-tagging) and Flex pods for collaboration (Alfresco Share). It differs from FlexibleDashboard+Liferay in that a pods XML file is used to config dashboard layout, not Share dashboard layouts.

**Elixir:**
An extension with pods that can display IBM ILog Elixir charting / visualizations is available from Integrated Semantics but not part of the open source projects

Also see:

[integratedsemantics.org](http://www.integratedsemantics.org) blog

[integratedsemantics.com](http://www.integratedsemantics.com)

[FlexibleDashboard+Liferay Google Code site](http://code.google.com/p/flexible-liferay/)

[FlexibleShare Google Code site](http://code.google.com/p/flexibleshare/)