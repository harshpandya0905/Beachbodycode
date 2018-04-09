@isTest
global  class CPM_CreateSubscriberCalloutMock_Test  implements WebServiceMock{
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
       exacttargetComWsdlPartnerapi.CreateResponse_element resElement = 
           new exacttargetComWsdlPartnerapi.CreateResponse_element();
               exacttargetComWsdlPartnerapi.CreateResult[] crList = new exacttargetComWsdlPartnerapi.CreateResult[]{};
       exacttargetComWsdlPartnerapi.CreateResult cr = new exacttargetComWsdlPartnerapi.CreateResult();
       cr.StatusCode = CPM_Constants.S_200;
       cr.StatusMessage = CPM_Constants.CREATED_SUBSCRIBER;
       exacttargetComWsdlPartnerapi.Subscriber subscriber = new exacttargetComWsdlPartnerapi.Subscriber();
       subscriber.Status = CPM_Constants.ACTIVE;
       subscriber.EmailAddress = CPM_Constants.TEST_EMAIL;
       cr.Object_x = subscriber;
       crList.add(cr);
       resElement.Results = crList;
       response.put(CPM_Constants.RESPONSE_X, resElement); 
   }
}