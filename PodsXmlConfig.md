## data/flexibleDashobardAirPods.xml ##
  1. configures what pods to have
  1. see data/flexibleDashboardAirPodsAll.xml for all possible pods
  1. some pods are commented out, can be added back in
  1. xml files used for in browser non air FlexibleDashboard is data/flexibleDashboardPods.xml (with example of all possible pods in data/flexibleDashboardAllPods.xml)


## Overall pod xml structure ##
  1. each view section sets up a tab view
  1. can add, change, delete views the default view config in flexibleDashboardAirPods.xml
  1. can choose to have any of the pods in a given view
  1. same as esria dashboard in general for now
  1. module url of swf set on module=  item

## Charting pods ##
  1. from esria dashboard, uses quietlyscheming chart animations

## Pentaho pod ##
  1. uses code from James Ward's port of pentaho dashboard to flex
  1. built version uses sample data, code that can call pentaho server is commented out

## BIRT report pod ##
  1. this displays a BIRT html report using the birt html viewer and requires a live birt runtime or actuate server installed
  1. The AIR version uses a webkit html control, the in browser one uses an iframe

## JasperReports pod ##
  1. displays reporturl report: default reports/WebappReport.jrpxml
  1. uses code from JasperReports flash viewer, changed to read from file instead of server, works offline without a server, thus more of a demo

## OLAP Grid pod ##
  1. Setup your info for your olap xmla server and take comments off
  1. click the load button to get it connected
  1. click the new grid button to add a tab where you can display data in a pivotable grid (drag item for row and column from the tree)
  1. click the new query button to add a tab where you can enter and run MDX queries

## BlazedDS pods ##
  1. There are two pods that run samples from BlazeDS
  1. BlazeDS pods need blazeds samples.war in your tomcat webapps dir
  1. They also need the the BlazeDS sampledb/startdb.bat running before starting tomcat

## HTML pods ##
  1. works better in AIR since can use air html webkit control
  1. in browser version uses iframe, not as good as air, but 7/21/2011
checked in code that makes the iframes work better by hiding iframes when minimized, when being resized, when being drag/dropped, etc.
  1. AIR also has a browser pod with control in addition to a html one without controls
  1. in pod xml set url to url of web page

## Liferay pods (AIR only) ##
  1. (Each can display a given portlet from a running Liferay server)
  1. the url of liferay can be set with portalUrl in the pod xml
  1. the url of a liferay portlet is set with the portletUrl pod xml. To get the liferay widget url for a given portlet, choose edit configuration on portlet in liferay / sharing tab / any website tab
  1. Also "Look and Feel" config on the portlet in liferay in first tab, unselecting show borders will hide liferay's portlet title and border from showing in these pods
  1. to run liferay in a separate tomcat at the same time as alfresco in another tomcat, I usually change in the liferay conf/server.xml all the ports 80xx to 90xx

## Local files pod (AIR only) ##
  1. displays a tree and list of local files
  1. useful for dragging files into other pods with native air drag/drip support (such as the doclib pods in flexibleshareair)

## Google Gadget pods (AIR only) ##
  1. NOTE: Something has changed where gadget urls from google gmodules.com only display as outlines currently
  1. maybe it would work if you have your own gadget server