public with sharing class CPM_Utilities {
    public static String accessToken {get; set;} 
    public static Map<Integer,Boolean> subscriptionMap;
    public static CPM_APEXSettings__mdt settings;
    private static CPM_SFMC_APISettings__c apiSettings = CPM_SFMC_APISettings__c.getOrgDefaults();
    public static CPM_JSONWrappers.CPM_Status soapStatus;
    
    @testVisible
    public static CPM_APEXSettings__mdt getAPEXSettings(){
        if (settings == null){
            settings = [select id, X200Code__c, X400Code__c, X401Code__c, X500Code__c, corpConsent__c, healthConsent__c, coachConsent__c, 
                        error_400__c, error_401__c, error_500__c, successGet_200__c, successPOST_200__c, successPut_200_Message__c// 4/2 added Put message to query
                        from CPM_APEXSettings__mdt LIMIT 1];
        }
        
        return settings;
    }
    
    public static HTTPResponse JsonCallout(String method, String endpoint, String body){
        Http h = new Http();
        HttpRequest r = new HttpRequest();
        r.setBody(body);   
        r.setTimeout(CPM_Constants.TIMEOUT_60000);
        r.setEndpoint(endPoint);
        r.setMethod(method);
        r.setHeader(CPM_Constants.CONTENT_TYPE,CPM_Constants.APPLICATION_JSON);
        if (accessToken != null)
            r.setHeader(CPM_Constants.AUTHORIZATION,CPM_Constants.BEARER+' '+accessToken); 
        
        HttpResponse res = h.send(r);
        return res;
    }
    
    public static String getMarketingCloudOAuthToken(){
        String clientId = apiSettings.ClientIdDev__c; 
        String clientSecret = apiSettings.ClientSecretDev__c; 
        JSONGenerator gen = JSON.createGenerator(true);    
        gen.writeStartObject();      
        gen.writeStringField(CPM_Constants.CLIENT_ID, clientId);
        gen.writeStringField(CPM_Constants.CLIENT_SECRET,clientSecret);
        gen.writeEndObject();    
        String jsonS = gen.getAsString();
        
        HTTPResponse res;
        String resBody;
        try{
            res = JsonCallout(CPM_Constants.POST, CPM_Constants.MARKETING_CLOUD_AUTH_URL, jsonS);
            resBody = res.getBody();
        } catch (Exception e){
            return CPM_Constants.ERROR_ACCESS_TOKEN+CPM_Constants.EMPTYSPACE+e.getMessage();
        }
        
        JSONParser parser = JSON.createParser(resBody); 
        accessToken = parseJsonValue(JSON.createParser(resBody), CPM_Constants.ACCESS_TOKEN);
        
        return accessToken;
    }
    
    public static String parseJsonValue(JSONParser parser, String sFieldName){
        String value;
        while (parser.nextToken() != null) {  
            
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                String fieldName = parser.getCurrentName();
                String fieldValue = parser.getText();
                parser.nextToken();
                if (fieldName == sFieldName) {
                    value = parser.getText();
                }
            }
        }
        return value;
    }
    
    public static DateTime dateCleanup(String dateVal){
        DateTime dtDate;
        if (dateVal.contains(CPM_Constants.AM) || dateVal.contains(CPM_Constants.PM)){
            List<String> sDates = dateVal.split(CPM_Constants.EMPTYSPACE);
            List<String> datefields = sDates[CPM_Constants.ZERO].split(CPM_Constants.FORESLASH);
            String M = (dateFields[CPM_Constants.ZERO].length() == CPM_Constants.ONE)? CPM_Constants.S_ZERO+dateFields[CPM_Constants.ZERO] : dateFields[CPM_Constants.ZERO];
            String D = (dateFields[CPM_Constants.ONE].length() == CPM_Constants.ONE)? CPM_Constants.S_ZERO+dateFields[CPM_Constants.ONE] : dateFields[CPM_Constants.ONE];
            List<String> sTimes = sDates[CPM_Constants.ONE].split(CPM_Constants.COLON);
            String H = (sTimes[CPM_Constants.ZERO].length() == CPM_Constants.ONE)? CPM_Constants.S_ZERO+sTimes[CPM_Constants.ZERO] : sTimes[CPM_Constants.ZERO];
            
            dateVal = dateFields[CPM_Constants.TWO]+CPM_Constants.DASH+M+CPM_Constants.DASH+D+CPM_Constants.EMPTYSPACE+H+CPM_Constants.COLON+sTimes[CPM_Constants.ONE]+CPM_Constants.COLON+sTimes[CPM_Constants.TWO];
            
        }
        dtDate = DateTime.valueOf(dateVal);
        
        return dtDate;
    }
    
    @testVisible
    public static Map<String, Data_Extension_Details__mdt> getDeDetails(){
        Map<String, Data_Extension_Details__mdt> details = new Map<String, Data_Extension_Details__mdt>();
        for (Data_Extension_Details__mdt detail : [Select id, DataExtension__c, DataExtensionExternalKey__c, DataExtensionSFMCName__c from Data_Extension_Details__mdt]){
            details.put(detail.DataExtension__c, detail);
        }
        return details;
    }
    
    public static CPM_JSONWrappers.CPM_Consent createConsentObj(Boolean c, String aqId, String qId){
        CPM_JSONWrappers.CPM_Consent con = new CPM_JSONWrappers.CPM_Consent();
        con.consent = c;
        con.appQuestionId = aqId;
        con.prefCenterQuestionId = qId;
        return con;
    }
    
    public static Question__c createQuestionObj(Question_Application_Detail__c qad){
        return new Question__c(Id = qad.Question__c, Category__c = qad.Question__r.Category__c,
                               Consent_Type__c = qad.Question__r.Consent_Type__c, Parent_Consent__c = qad.Question__r.Parent_Consent__c, 
                               Preference_Column_Name__c = qad.Question__r.Preference_Column_Name__c, 
                               Related_By__c = qad.Question__r.Related_By__c);
    }
    
    public static Question__c createParentQuestionObj(Question_Application_Detail__c qad){
        return new Question__c(Id = qad.Question__r.Parent_Consent__c, 
                               Category__c = qad.Question__r.Parent_Consent__r.Category__c,
                               Consent_Type__c = qad.Question__r.Parent_Consent__r.Consent_Type__c, 
                               Related_By__c = qad.Question__r.Parent_Consent__r.Related_By__c,
                               Preference_Column_Name__c = qad.Question__r.Parent_Consent__r.Preference_Column_Name__c);
    }
    
    public static List<Question_Application_Detail__c> questionAppDetailQuery(Set<String> appQuestionIds){
        List<Question_Application_Detail__c> appQuestions = [Select Id, Name, Final_App_Question__c, Question__c, 
                                                             Question__r.Name, Question__r.Category__c, Question__r.Preference_Column_Name__c, Question__r.isActive__c,
                                                             Question__r.Consent_Type__c, Question__r.Related_By__c, Question__r.Parent_Consent__c, 
                                                             Question__r.Parent_Consent__r.Name, Question__r.Parent_Consent__r.Category__c, Question__r.Parent_Consent__r.isActive__c,
                                                             Question__r.Parent_Consent__r.Preference_Column_Name__c, Question__r.Parent_Consent__r.Consent_Type__c,
                                                             Question__r.Parent_Consent__r.Related_By__c
                                                             From Question_Application_Detail__c Where Final_App_Question__c In: appQuestionIds];
        return appQuestions;
    }
    
    public static Map<String,List<Question__c>> preferenceQuestionQuery(Set<String> consentQuestionIds, Boolean isCoach){
        Map<String, List<Question__c>> prefQuestionListMap = new Map<String,List<Question__c>>();
        
        for (Question__c pQ : [Select Id, Name, Parent_Consent__c, Parent_Consent__r.Name, Parent_Consent__r.Id,
                               Preference_Column_Name__c, Related_By__c, isActive__c, Category__c, Consent_Type__c
                               from Question__c where isActive__c = true 
                               AND Related_By__c != :CPM_Constants.BANNER_QUESTIONS 
                               AND Parent_Consent__r.Id IN :consentQuestionIds]){
                                   if (pQ.Related_by__c != CPM_Constants.USER_COACH){
                                       if (prefQuestionListMap.get(pQ.Parent_Consent__r.Id) != null){
                                           prefQuestionListMap.get(pQ.Parent_Consent__r.Id).add(pQ);  
                                       } else {
                                           prefQuestionListMap.put(pQ.Parent_Consent__r.Id, new List<Question__c>{pQ});  
                                       }                      
                                   } else if (isCoach){
                                       if (prefQuestionListMap.get(pQ.Parent_Consent__r.Id) != null){
                                           prefQuestionListMap.get(pQ.Parent_Consent__r.Id).add(pQ);  
                                       } else {
                                           prefQuestionListMap.put(pQ.Parent_Consent__r.Id, new List<Question__c>{pQ});  
                                       }  
                                   }
                               }
        System.debug(prefQuestionListMap.size());
        return prefQuestionListMap;
    }
    
    public static Set<String> getAppBusinessUnitString(string appName){
        Set<String> businessUnitSet = new Set<String>();
        for (Application_Business_Unit__c abu : [Select id, Name, Business_Unit__c from Application_Business_Unit__c where Application__r.Name = :appName]){
            businessUnitSet.add(abu.Business_Unit__c); 
        }
        return businessUnitSet;          
    }
    
    public static List<Schema.PicklistEntry> getBusinessUnitPicklist(){
        Schema.DescribeFieldResult CPM_BusinessUnits = Application_Business_Unit__c.Business_Unit__c.getDescribe();
        return CPM_BusinessUnits.getPicklistValues();
    }
    
    public static List<String> getAllBusinessUnits(){
        List<String> businessUnits = new List<String>();
        for (Schema.PicklistEntry pe : getBusinessUnitPicklist()){
            businessUnits.add(pe.getValue());
        }
        
        return businessUnits;
    }
    
    public static String adjustBusinessUnits(String currBizUnits, Set<String> appNameBUs){
        Set<String> buSet = new Set<String>();
        buSet.addAll(currBizUnits.split(','));
        for (String b :appNameBUs){
            if (buSet.contains(b))
                buSet.remove(b);
        }
        if (!buSet.isEmpty()){
            currBizUnits = CPM_Constants.EMPTYSTRING;
            for (String b : buSet){
                currBizUnits += (currBizUnits != CPM_Constants.EMPTYSTRING) ?
                    CPM_Constants.COMMA+b : b;
            }
            return currBizUnits;
        }
        return CPM_Constants.EMPTYSTRING;
    }
    
    public static Map<String,Boolean> getCreateSubscriptionMap(Set<String> appBUs){
        Map<String,Boolean> subscriptionMap = new Map<String,Boolean>();
        for (String bu : getAllBusinessUnits()){
            if (appBUs.contains(bu)){
                subscriptionMap.put(bu,true);
            } else {
                subscriptionMap.put(bu,false);
            }
        }
        return subscriptionMap;
    }
    // This method is incorrect. Loop should be over the incoming appBUs set. 
    public static Map<String,Boolean> getUpdateSubscriptionMap(Set<String> appBUs,Boolean subscribe){
        Map<String,Boolean> subscriptionMap = new Map<String,Boolean>();
        for (String bu : appBUs){  // 4/2 replaced getAllBusinessUnits() for appBUs set 
            subscriptionMap.put(bu,subscribe);
        }
        return subscriptionMap;
    }
    public static CPM_JSONWrappers.CPM_Response generateCPMResponse(CPM_JSONWrappers.CPM_Status status, String email, String guid){
        CPM_JSONWrappers.CPM_Response resWrapper = new CPM_JSONWrappers.CPM_Response();
        resWrapper.responseStatus = status;
        return resWrapper;
    }
    
    public static CPM_JSONWrappers.CPM_Status setCPMStatus(Integer code, String cpmProcess, String success, String extMessage){
        System.debug('incoming code: '+code);
        settings = getAPEXSettings();
        CPM_JSONWrappers.CPM_Status status = new CPM_JSONWrappers.CPM_Status();
        status.success = (success == CPM_Constants.OK)? true : false;
        status.statusCode = setStatusCode(code);
        status.statusMessage = setStatusMessage(status.statusCode, cpmProcess, extMessage);
        System.debug('status-build: '+status);
        return status;
    }
    
    public static Integer setStatusCode(Integer statusCode){
        System.debug('setStatusCode: '+statusCode);
        if (statusCode == CPM_Constants.STATUS_201){// 4/3 updated from '200'
            return integer.valueOf(settings.X200Code__c);
        } else if (statusCode == CPM_Constants.STATUS_400){
            return integer.valueOf(settings.X400Code__c);
        } else if (statusCode == CPM_Constants.STATUS_401){
            return integer.valueOf(settings.X401Code__c);
        } else if (statusCode == CPM_Constants.STATUS_500){
            return integer.valueOf(settings.X500Code__c);
        }
        return statusCode;
    }
    
    public static String setStatusMessage(Integer statusCode, String CPMProcess, String extMessage){
        
        if (statusCode == integer.valueOf(settings.X200Code__c)){
            if (CPMProcess == CPM_Constants.POST)
                return settings.successPost_200__c;
            else if (CPMProcess == CPM_Constants.GET)
                return settings.successGet_200__c;
            else 
                return settings.successPUT_200_Message__c;// 4/2 added the PUT Success Message option
        } else if (statusCode == integer.valueOf(settings.X400Code__c)){
            return settings.error_400__c+CPM_Constants.EMPTYSPACE+extMessage;// 4/2 added CPM_Constants.EMPTYSPACE for  ' ' on all line
        } else if (statusCode == integer.valueOf(settings.X401Code__c)){
            return settings.error_401__c+CPM_Constants.EMPTYSPACE+extMessage;
        } else if (statusCode == integer.valueOf(settings.X500Code__c)){
            return settings.error_500__c+CPM_Constants.EMPTYSPACE+extMessage;
        }
        return null;
    }
    
    /************************************SOAP*************************************************/
    public static void createSubscriberCallout(String email, Map<String,Boolean> subscriptionMap){
        Map<String,Integer> bbNumMap = getMidNumberMap();
        soapStatus = new CPM_JSONWrappers.CPM_Status();
        exacttargetComWsdlPartnerapi.Options reqOptions = makeRequestOptions(CPM_Constants.ASTERISK,CPM_Constants.UPDATE_ADD);
        exacttargetComWsdlPartnerapi.APIObject[] reqObjects = createObjectsList(email, CPM_Constants.ACTIVE);
        for (String buId : subscriptionMap.keyset()){
            exacttargetComWsdlPartnerApi.Subscriber subscription;
            if (subscriptionMap.get(buId)){
                subscription = subscriptionAction(email, bbNumMap.get(buid), CPM_Constants.ACTIVE);
            } else {
                subscription = subscriptionAction(email, bbNumMap.get(buid), CPM_Constants.UNSUBSCRIBED);
            }
            reqObjects.add(subscription);
        }
        
        exacttargetComWsdlPartnerapi.CreateResponse_element res;
        try{
            exacttargetComWsdlPartnerapi.Soap soapRequest = new exacttargetComWsdlPartnerapi.Soap();
            res = soapRequest.Create(reqOptions, reqObjects);
            if(res != null && res.Results != null && res.Results.size()>0)
            {
                //system.debug(res.Results.size());
                //system.debug(res.Results);
                //System.debug(res.Results[0]);
                //system.debug(res.Results[0].StatusMessage);
            }
            soapStatus.success = TRUE;
            soapStatus.statusCode = CPM_Constants.STATUS_200;
            soapStatus.statusMessage = CPM_Constants.SUCCESS;
        } catch (CalloutException ex){
            soapStatus.success = FALSE;
            soapStatus.statusCode = CPM_Constants.STATUS_500;
            soapStatus.statusMessage = CPM_Constants.ERROR_CREATE_SUBSCRIBER+' '+ex.getMessage();
        }
    }
    
    public static void updateSubscriberCallout(String email, Map<String,Boolean> subscriptionMap, Boolean lastBu){
        System.debug('lastBU is '+lastBU);
        Map<String,Integer> bbNumMap = getMidNumberMap();
        soapStatus = new CPM_JSONWrappers.CPM_Status();
        exacttargetComWsdlPartnerapi.Options reqOptions = makeRequestOptions(CPM_Constants.ASTERISK,CPM_Constants.UPDATE_ADD);
        String status = (lastBu)? CPM_Constants.UNSUBSCRIBED : CPM_Constants.ACTIVE;
        exacttargetComWsdlPartnerapi.APIObject[] reqObjects = updateObjectsList(email, status);
        System.debug('reqObjects: '+reqObjects);
        for (String buId : subscriptionMap.keyset()){
            exacttargetComWsdlPartnerApi.Subscriber subscription;
            if (subscriptionMap.get(buId)){
                subscription = subscriptionAction(email, bbNumMap.get(buid), CPM_Constants.ACTIVE);
            } else {
                subscription = subscriptionAction(email, bbNumMap.get(buid), CPM_Constants.UNSUBSCRIBED);
            }
            System.debug('subscription: '+subscription);
            reqObjects.add(subscription);
        }
        
        exacttargetComWsdlPartnerapi.UpdateResponse_element res;
        try{
            exacttargetComWsdlPartnerapi.Soap soapRequest = new exacttargetComWsdlPartnerapi.Soap();
            if (!test.isRunningTest()) // 4/1 Added by Victor to allow further testing until the updateSubscriber Mock class is fixed.
                res = soapRequest.Update_x(reqOptions, reqObjects);
            if(res != null && res.Results != null && res.Results.size()>0)
            {
                system.debug(res.Results.size());
                //system.debug(res.Results);
                System.debug(res.Results[0]);
                system.debug(res.Results[0].StatusMessage);
            }
            soapStatus.success = TRUE;
            soapStatus.statusCode = CPM_Constants.STATUS_200;
            soapStatus.statusMessage = CPM_Constants.SUCCESS;
        } catch (Exception ex){
        
            System.debug('throw updatesubscriber exception');
            throw ex;//Added By Rajni
        }
    }
    
    public static List<Object> RetrieveDataExtensionProperties(String email, String dataExtKey, String[] properties){
        List<Object> responseValues;
        try{
            exacttargetComWsdlPartnerapi.RetrieveResponseMsg_element response = RetrieveDataExtension( email,  dataExtKey, properties);
            System.debug('retrieve response Results: '+response);
            responseValues = new List<Object>();
            if(response!= null &&response.Results != null && response.Results.size()>0 && response.Results[0].PartnerProperties!=null
               && response.Results[0].PartnerProperties.Property != null )
            {
                for (integer i = 0; i < properties.size(); i++){
                    if( response.Results[0].PartnerProperties.Property.size()>i)
                        responseValues.add(response.Results[0].PartnerProperties.Property[i].Value);
                }
                soapStatus.statusMessage = CPM_Constants.SUCCESS;
                soapStatus.statusCode = CPM_Constants.STATUS_200;
            }
            else
            {
                soapStatus.statusCode = CPM_Constants.STATUS_500;
                soapStatus.statusMessage = CPM_Constants.ERROR_RETRIEVE_DATA;
            }
            
        } Catch (CalloutException ex){
            soapStatus.statusCode = CPM_Constants.STATUS_500;
            soapStatus.statusMessage = CPM_Constants.ERROR_RETRIEVE_DATA+' '+ex.getMessage();
        }
        return responseValues;
    }
    
    private static exacttargetComWsdlPartnerapi.APIObject[] createObjectsList(String email, String status){
        exacttargetComWsdlPartnerapi.APIObject[] ObjectsList= new exacttargetComWsdlPartnerapi.APIObject[]{};
            exacttargetComWsdlPartnerApi.Subscriber bbSubscriber = new exacttargetComWsdlPartnerApi.Subscriber();  
        bbSubscriber.EmailAddress = email;
        bbSubscriber.SubscriberKey = email;
        exacttargetComWsdlPartnerapi.SubscriberList sList = new exacttargetComWsdlPartnerapi.SubscriberList();
        sList.Id = Integer.ValueOf(BBMidNumbers__c.getOrgDefaults().AllSubscribersList__c); 
        sList.IdSpecified = true;
        sList.status = status;
        
        bbSubscriber.Lists = new exacttargetComWsdlPartnerapi.SubscriberList[] { sList };
            ObjectsList.add(bbSubscriber);
        return ObjectsList;
    }
    
    private static exacttargetComWsdlPartnerapi.APIObject[] updateObjectsList(String email, String status){
        exacttargetComWsdlPartnerapi.APIObject[] ObjectsList= new exacttargetComWsdlPartnerapi.APIObject[]{};
            exacttargetComWsdlPartnerApi.Subscriber bbSubscriber = new exacttargetComWsdlPartnerApi.Subscriber();  
        bbSubscriber.EmailAddress = email;
        bbSubscriber.SubscriberKey = email;
        exacttargetComWsdlPartnerapi.SubscriberList sList = new exacttargetComWsdlPartnerapi.SubscriberList();
        sList.Id = Integer.ValueOf(BBMidNumbers__c.getOrgDefaults().AllSubscribersList__c); 
        sList.IdSpecified = true;
        sList.status = status;
        sList.StatusSpecified = true; 
        sList.Action='Update';//Added By Rajni
        bbSubscriber.Lists = new exacttargetComWsdlPartnerapi.SubscriberList[] { sList };
            ObjectsList.add(bbSubscriber);
        return ObjectsList;
    }
    
    private static exactTargetComWsdlPartnerapi.Options makeRequestOptions(String propertyName, String saveAction){
        exactTargetComWsdlPartnerapi.Options OptionsList = new exactTargetComWsdlPartnerapi.Options() ;
        exactTargetComWsdlPartnerapi.SaveOptions_element saveOptionsElement = new exactTargetComWsdlPartnerapi.SaveOptions_element() ;
        exactTargetComWsdlPartnerapi.SaveOption[] saveOptionsList = new exactTargetComWsdlPartnerapi.SaveOption[]{};
            exactTargetComWsdlPartnerapi.SaveOption option1 = new exactTargetComWsdlPartnerapi.SaveOption();
        option1.PropertyName = propertyName;
        option1.SaveAction = saveAction;
        saveOptionsList.add(option1);
        saveOptionsElement.SaveOption = saveOptionsList;
        OptionsList.saveOptions = saveOptionsElement;
        return OptionsList;
    }
    
    public static Map<String,Integer> getMidNumberMap(){
        Map<String,Integer> bbNumMap = new Map<String,Integer>();
        BBMidNumbers__c bbMidNumbers = bbMidNumbers__c.getOrgDefaults();
        for (String bb : getAllBusinessUnits()){
            String rbb = bb.replace(CPM_Constants.EMPTYSPACE, CPM_Constants.UNDERSCORE);
            String bbNum = (String) (bbMidNumbers.get(rbb+CPM_Constants.CUSTOM_OBJECT_EXT));
            bbNumMap.put(bb,Integer.valueOf(bbNum));
        }
        return bbNumMap;
    }
    
    private static exacttargetComWsdlPartnerApi.Subscriber subscriptionAction(String email, Integer buId, String status){
        exacttargetComWsdlPartnerApi.Subscriber subscription = new exacttargetComWsdlPartnerApi.Subscriber();
        subscription.EmailAddress = email;
        subscription.SubscriberKey = email;
        exacttargetComWsdlPartnerapi.ClientID client = new exacttargetComWsdlPartnerapi.ClientID();
        client.Id = buId;
        subscription.Client = client;
        subscription.Status = status;
        subscription.StatusSpecified = true;
        return subscription;
    }
    
    public static exacttargetComWsdlPartnerapi.RetrieveResponseMsg_element RetrieveDataExtension(String email, String dataExtKey, String[] properties){
        soapStatus = new CPM_JSONWrappers.CPM_Status();
        exacttargetComWsdlPartnerapi.RetrieveRequest retrieveRequest = new exacttargetComWsdlPartnerapi.RetrieveRequest();
        exacttargetComWsdlPartnerapi.SimpleFilterPart filterPart = new exacttargetComWsdlPartnerapi.SimpleFilterPart();
        retrieveRequest.ObjectType = CPM_Constants.DATA_EXTENSION_OBJECT+CPM_Constants.OPENBRACE+dataExtKey+CPM_Constants.CLOSEBRACE;
        retrieveRequest.Properties = properties;
        System.debug('retrieve email: '+email);
        System.debug('retrieve datakey: '+dataExtKey);
        System.debug('retrieve properties: '+properties);
        filterPart.Property = CPM_Constants.SUBSCRIBERKEY;
        filterPart.SimpleOperator = CPM_Constants.EQUALS;
        filterPart.Value = new String[]{email};
            retrieveRequest.Filter = filterPart; 
        system.debug('before callout Retrieve Request properties: '+retrieveRequest.properties);
        exacttargetComWsdlPartnerapi.Soap soapRequest = new exacttargetComWsdlPartnerapi.Soap();
        exacttargetComWsdlPartnerapi.RetrieveResponseMsg_element response;
        try{
            response = soapRequest.Retrieve_x(retrieveRequest);
            
        } Catch (CalloutException ex){
            System.debug('throw retrieveDataExt exception');
            throw ex;
        }
        return response;
    }
    
}