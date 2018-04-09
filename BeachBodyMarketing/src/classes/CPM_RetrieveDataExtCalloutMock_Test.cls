@isTest
global class CPM_RetrieveDataExtCalloutMock_Test implements WebServiceMock{
	global void doInvoke(
           Object stub,
           Object request,
           Map<String, Object> response,
           String endpoint,
           String soapAction,
           String requestName,
           String responseNS,
           String responseName,
           String responseType) {
       	exacttargetComWsdlPartnerapi.RetrieveResponseMsg_element resElement = 
           new exacttargetComWsdlPartnerapi.RetrieveResponseMsg_element();
       	
		exacttargetComWsdlPartnerapi.APIObject result1 = new exacttargetComWsdlPartnerapi.APIObject();
       	result1.PartnerProperties = new exacttargetComWsdlPartnerapi.Properties_element();
        
        exacttargetComWsdlPartnerapi.APIProperty p1 = new exacttargetComWsdlPartnerapi.APIProperty();
               p1.Name = 'CreatedDate';
               p1.Value = String.valueOf(System.now());
        exacttargetComWsdlPartnerapi.APIProperty p2 = new exacttargetComWsdlPartnerapi.APIProperty();
               p2.Name = 'CreatedBy';
               p2.Value = String.valueOf(UserInfo.getName());
        exacttargetComWsdlPartnerapi.APIProperty p3 = new exacttargetComWsdlPartnerapi.APIProperty();
               p2.Name = 'guid';
               p2.Value = String.valueOf('123456');

        result1.PartnerProperties.Property = new exacttargetComWsdlPartnerapi.APIProperty[]{p1,p2,p3};
        resElement.Results = new exacttargetComWsdlPartnerapi.APIObject[]{result1};
        resElement.OverallStatus = '200';
       
       response.put('response_x', resElement); 
   }
}