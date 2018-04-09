@isTest
global  class CPM_SoapCalloutMock_Test implements WebServiceMock {
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
            exacttargetComWsdlPartnerapi.UpdateResponseDE_element response_x = 
                new exacttargetComWsdlPartnerapi.UpdateResponseDE_element();
            response_x.Results= new exacttargetComWsdlPartnerapi.UpdateResultDE[]{};
                exacttargetComWsdlPartnerapi.UpdateResultDE result1= new exacttargetComWsdlPartnerapi.UpdateResultDE();
            result1.StatusCode='Error';
            response_x.Results.Add(result1);
            
            response.put('response_x', response_x); 
        }
    
}