@isTest
private  class CPM_Util_Test{
    @isTest static void testCallout() {   
        List<string> columnsList= new List<string>();
        columnsList.add('col1');
        Test.setMock(WebServiceMock.class, new Test_CPM_SoapCalloutMock());
        CPM_Util.createAllColumnsCallout(columnsList,columnsList,false);
    }

}