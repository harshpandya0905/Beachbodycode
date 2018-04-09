@isTest
private  class CPM_exacttargetComWsdlPartnerapi_Test {
     @isTest static void testCallout_UpdateDataExtension_x() {              
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new Test_CPM_SoapCalloutMock());
        // Call the method that invokes a callout
        exacttargetComWsdlPartnerapi.Soap soapRequest = new exacttargetComWsdlPartnerapi.Soap();
        
        exacttargetComWsdlPartnerapi.Options updateOptionList = new  exacttargetComWsdlPartnerapi.Options();
        
        exacttargetComWsdlPartnerapi.APIObject[] ObjectsList= new exacttargetComWsdlPartnerapi.APIObject[]{};
            
        exacttargetComWsdlPartnerapi.UpdateResponseDE_element response = soapRequest.UpdateDataExtension_x(updateOptionList,ObjectsList);
        // Verify that a fake result is returned
        System.assertEquals('Error', response.Results[0].StatusCode); 
    }

}