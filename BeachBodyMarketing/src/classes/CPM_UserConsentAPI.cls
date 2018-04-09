@RestResource(urlMapping='/cpm/userconsents/*')
global class CPM_UserConsentAPI {
    
    private static CPM_SFMC_APISettings__c apiSettings;
    public static CPM_APEXSettings__mdt settings;
    @testVisible private static Boolean testError;
    @testVisible private static String testString;
    private static Map<String, Data_Extension_Details__mdt> deDetails;
    private static Map<String,Object> dateUserMap;
    private static reqBodyWrapper reqBodyWrap;
    private static Boolean continueProcess;
    private static CPM_JSONWrappers.CPM_CreateUserAndConsentRequest reqWrapper;
    private static CPM_JSONWrappers.CPM_Response resWrapper;
    @testVisible private static CPM_JSONWrappers.CPM_Status resStatus;
    private static CPM_ApplicationWrapper appWrapper;
    private static String accessToken;
    private static String email;
    private static String guid;
    private static String endpoint = CPM_Constants.DATAEVENTS_ENDPOINT;
    private static String rowset = CPM_Constants.DATAEVENTS_ROWSET;
    private static String rows = CPM_Constants.DATAEVENTS_ROWS;
    private static String masterDataExtKey;
    private static String prefsDataExtKey;
    private static String auditsDataExtKey;
    private static integer errorCode;
    private static blob responseBody;
    private static HTTPResponse res;
    public class reqBodyWrapper{
        public String prefsReqBody {get; set;}
        public String auditReqBody {get; set;}
        public String errorMessage {get; set;}
    }
    
    private static void setSettings(){
        settings = CPM_Utilities.getAPEXSettings();
        apiSettings = CPM_SFMC_APISettings__c.getOrgDefaults();
        deDetails = CPM_Utilities.getDeDetails();
        masterDataExtKey = deDetails.get(CPM_Constants.MASTER_DE_NAME).DataExtensionExternalKey__c; // Custom Settings
        prefsDataExtKey = deDetails.get(CPM_Constants.PREFERENCE_DE_NAME).DataExtensionExternalKey__c;
        auditsDataExtKey = deDetails.get(CPM_Constants.PREFERENCE_AUDIT_DE_NAME).DataExtensionExternalKey__c;
        
    }
    
    @HttpPost
    global static void createuserandconsent(){
        try{
            // set Settings
            setSettings();
            continueProcess = true; 
            // deserialize RestRequest
            RestRequest req = RestContext.request;
            resWrapper = new CPM_JSONWrappers.CPM_Response();
            // Check Mandatory Parameters
           System.debug(req.requestBody.toString());
           resStatus = CPM_Validations.validateRequest(req.requestBody.toString(),'Create', null, null);//, CPM_Constants.CREATE
            if (resStatus != null){
                System.debug('resStatus: '+resStatus);
                generateCPMResponse(CPM_Constants.STATUS_400,resStatus,email,guid);
                continueProcess = false;
            }
            
            if (continueProcess){
                reqWrapper = createConsentRequestParse(req.requestBody.toString());
                email = reqWrapper.email;
                guid = reqWrapper.guid;
                //Changes To Correct TimeZone in SFMC-Start
                Timezone tz = Timezone.getTimeZone('America/El_Salvador');
                if(reqWrapper.ConsentDetails!=null && reqWrapper.ConsentDetails.consentDate!=null)
                {
                    integer offsetToUserTimeZone =tz.getOffset(reqWrapper.ConsentDetails.consentDate);
                    system.debug('inputdate**'+offsetToUserTimeZone);
                    reqWrapper.ConsentDetails.consentDate=reqWrapper.ConsentDetails.consentDate.addHours(-(offsetToUserTimeZone / (1000 * 60 *60))) ;
                    system.debug('inputdate**'+reqWrapper.ConsentDetails.consentDate);
                }
                if(reqWrapper.ConsentDetails!=null && reqWrapper.ConsentDetails.CASLExpirationDate!=null)
                {
                    integer offsetToUserTimeZone =tz.getOffset(reqWrapper.ConsentDetails.CASLExpirationDate);
                    system.debug('inputdate**'+offsetToUserTimeZone);
                    reqWrapper.ConsentDetails.CASLExpirationDate=reqWrapper.ConsentDetails.CASLExpirationDate.addHours(-(offsetToUserTimeZone / (1000 * 60 *60))) ;
                    system.debug('inputdate**'+reqWrapper.ConsentDetails.CASLExpirationDate);
                }
                //Changes To Correct TimeZone in SFMC-End
            }
                
            if (continueProcess){
                // get Application-related Questions, Details and QuestionApps
                appWrapper = new CPM_ApplicationWrapper(reqWrapper.ConsentDetails.Consents, reqWrapper.appName, reqWrapper.isCoach);
                createSubscriber(reqWrapper.email);
                System.debug('soap StatusCode: '+CPM_Utilities.soapStatus.statusCode);
                if (CPM_Utilities.soapStatus.statusCode == CPM_Constants.STATUS_500){
                    generateCPMResponse(CPM_Constants.STATUS_500,resStatus,email,guid);
                    continueProcess = false;
                } 
            }
            
            if (continueProcess){
                // REST Callout for the MC AccessToken
                String accessToken = CPM_Utilities.getMarketingCloudOAuthToken();
                if (CPM_Utilities.accessToken.startsWith(CPM_Constants.ERROR)){
                    resStatus = CPM_Utilities.setCPMStatus(401, CPM_Constants.POST, CPM_Constants.ERROR, accessToken);
                    generateCPMResponse(res.getStatusCode(),resStatus,email,guid);
                    continueProcess = false;
                }
            }
            
            if (continueProcess){
                System.debug('Master callout phase');
                // Master DE Insert
                String masterJsonBody = CPM_MarketingCloudCallouts.getInsertMasterJsonBody(reqWrapper, appWrapper);
                // AppBusinessUnit unfound error
                if (!masterJsonBody.startsWith(CPM_Constants.OPENBRACKET) && !masterJsonBody.startsWith(CPM_Constants.OPENBRACE)){
                    resStatus = CPM_Utilities.setCPMStatus(CPM_Constants.STATUS_400, CPM_Constants.POST, CPM_Constants.ERROR, masterJsonBody);
                    generateCPMResponse(CPM_Constants.STATUS_400,resStatus,email,guid);
                    continueProcess = false;
                } else {
                    res = DataExtensionCallout(CPM_Constants.POST,endPoint+masterDataExtKey+rowset,masterJsonBody);
                    String masterResBody = res.getBody();
                    masterResBody = masterResBody.removeStart(CPM_Constants.OPENBRACE).removeEnd(CPM_Constants.CLOSEBRACE);
                    CPM_JSONWrappers.CPM_Status masterStatus = CPM_Utilities.setCPMStatus(res.getStatusCode(), CPM_Constants.POST, res.getStatus(), CPM_Constants.MASTER_DE_INSERT);
                    // Master DE Callout Error
                    if (res.getStatusCode() != CPM_Constants.STATUS_200){
                        generateCPMResponse(res.getStatusCode(),masterStatus,email,guid);
                        continueProcess = false;
                    }
                }
            }
            
            if (continueProcess){
                setDateUserMap(reqWrapper.ConsentDetails, null, null);
                //dateMap.put('OriginalCreatedDate',reqWrapper.ConsentDetails.consentDate);
                
                reqBodyWrap = CPM_MarketingCloudCallouts.getPrefsJsonBodies(dateUserMap, email, guid, appWrapper, reqWrapper.Country);
                String prefsJsonBody = reqBodyWrap.prefsReqBody;
                res = DataExtensionCallout(CPM_Constants.POST,endPoint+prefsDataExtKey+rowset,prefsJsonBody);  
                
                CPM_JSONWrappers.CPM_Status prefsStatus = CPM_Utilities.setCPMStatus(res.getStatusCode(), CPM_Constants.POST, res.getStatus(), CPM_Constants.PREFERENCES_DE_INSERT);
                
                // Prefs DE Callout Error
                if (res.getStatusCode() != CPM_Constants.STATUS_200){
                    generateCPMResponse(res.getStatusCode(),prefsStatus,email,guid);
                    continueProcess = false;
                }
            }
            
            if (continueProcess){
                String auditJsonBody = reqBodyWrap.auditReqBody;
                res = DataExtensionCallout(CPM_Constants.POST,endPoint+auditsDataExtKey+rowset,auditJsonBody);   
                String auditResBody = res.getBody();
                auditResBody = auditResBody.removeStart(CPM_Constants.OPENBRACE).removeEnd(CPM_Constants.CLOSEBRACE);
                Integer statCode = (res.getStatusCode() == CPM_Constants.STATUS_200)? CPM_Constants.STATUS_201 : res.getStatusCode();
                CPM_JSONWrappers.CPM_Status auditStatus = CPM_Utilities.setCPMStatus(statCode, CPM_Constants.POST, res.getStatus(), CPM_Constants.PREFERENCE_AUDIT_DE_INSERT);
                
                // Audit DE Callout Error
                if (res.getStatusCode() != CPM_Constants.STATUS_200 && res.getStatusCode() != CPM_Constants.STATUS_201){
                    generateCPMResponse(statCode,auditStatus,email,guid);
                } else {
                    resWrapper = CPM_Utilities.generateCPMResponse(auditStatus, email, guid);
                }
            }   
            if(resWrapper!=null &&resWrapper.responseStatus!=null && resWrapper.responseStatus.success!=null)
            {
                RestContext.response.statusCode = (errorCode == null)? CPM_Constants.STATUS_201 : errorCode;// 4/3 updated Status to '201' from '200'
                RestContext.response.responseBody = Blob.valueOf(json.serialize(resWrapper));
            }
            else
            {
                
                RestContext.response.statusCode = CPM_Constants.STATUS_408;
                resWrapper = new CPM_JSONWrappers.CPM_Response();
                resWrapper.responseStatus= new CPM_JSONWrappers.CPM_Status();
                resWrapper.responseStatus.success=false;
                resWrapper.responseStatus.statusCode=Integer.valueOf(settings.X500Code__c);
                resWrapper.responseStatus.statusMessage=settings.error_500__c ;
                RestContext.response.responseBody = Blob.valueOf(json.serialize(resWrapper));
            }
            
        }
        catch(Exception ex )
        {
            system.debug(ex.getMessage());
            RestContext.response.statusCode = CPM_Constants.STATUS_500;
            resWrapper = new CPM_JSONWrappers.CPM_Response();
            resWrapper.responseStatus= new CPM_JSONWrappers.CPM_Status();
            resWrapper.responseStatus.success=false;
            resWrapper.responseStatus.statusCode=Integer.valueOf(settings.X500Code__c);
            resWrapper.responseStatus.statusMessage=settings.error_500__c ;
            RestContext.response.responseBody = Blob.valueOf(json.serialize(resWrapper));
        }
    }
    
    @HttpPut
    global static void UpdateUserConsent(){
        try
        {
            setSettings();
            Boolean continueProcess = true;
            RestRequest req = RestContext.request;
            email = req.params.get(CPM_Constants.EMAIL);
            guid = req.params.get(CPM_Constants.GUID);
            
            CPM_JSONWrappers.CPM_UpdateUserConsentRequest reqWrapper;
            resWrapper = new CPM_JSONWrappers.CPM_Response();
            //Check Mandatory Parameters
            if (String.isBlank(email) && String.isBlank(guid)){
                String missingParameter = CPM_Constants.ERROR_MISSING_SUBSCRIBER_KEY;
                resStatus = CPM_Utilities.setCPMStatus(CPM_Constants.STATUS_400,CPM_Constants.PUT, CPM_Constants.ERROR, CPM_Constants.COLON+ missingParameter);
                generateCPMResponse(CPM_Constants.STATUS_400,resStatus,email,guid);
                continueProcess = false;
            }
            if (continueProcess){
                System.debug('request json is: '+req.requestBody.toString());
                resStatus = CPM_Validations.validateRequest(req.requestBody.toString(),'updateConsent', email, guid);//, CPM_Constants.CREATE
                if (resStatus != null){
                    System.debug('resStatus: '+resStatus);
                    generateCPMResponse(CPM_Constants.STATUS_400,resStatus,email,guid);
                    continueProcess = false;
                }
            }
            System.debug('continueProcess after parameter check:'+continueProcess);
            if (continueProcess){
                String accessToken = CPM_Utilities.getMarketingCloudOAuthToken();
                System.debug('MC accessToken: '+accessToken);
                if (CPM_Utilities.accessToken.startsWith(CPM_Constants.ERROR)){
                    resStatus = CPM_Utilities.setCPMStatus(CPM_Constants.STATUS_401, CPM_Constants.POST, CPM_Constants.ERROR, accessToken);
                    generateCPMResponse(CPM_Constants.STATUS_401,resStatus,email,guid);
                    continueProcess = false;
                }
            }
            System.debug('continueProcess after token:'+continueProcess);
            if (continueProcess){
                System.debug(req.requestBody.toString());
                reqWrapper = updateConsentRequestParse(req.requestBody.toString());
                reqWrapper.email = email;
                reqWrapper.guid = guid;
                //Changes To Correct TimeZone in SFMC-Start
                Timezone tz = Timezone.getTimeZone('America/El_Salvador');
                if(reqWrapper.ConsentDetails!=null && reqWrapper.ConsentDetails.consentDate!=null)
                {
                    integer offsetToUserTimeZone =tz.getOffset(reqWrapper.ConsentDetails.consentDate);
                    system.debug('inputdate**'+offsetToUserTimeZone);
                    reqWrapper.ConsentDetails.consentDate=reqWrapper.ConsentDetails.consentDate.addHours(-(offsetToUserTimeZone / (1000 * 60 *60))) ;
                    system.debug('inputdate**'+reqWrapper.ConsentDetails.consentDate);
                }
                if(reqWrapper.ConsentDetails!=null && reqWrapper.ConsentDetails.CASLExpirationDate!=null)
                {
                    integer offsetToUserTimeZone =tz.getOffset(reqWrapper.ConsentDetails.CASLExpirationDate);
                    system.debug('inputdate**'+offsetToUserTimeZone);
                    reqWrapper.ConsentDetails.CASLExpirationDate=reqWrapper.ConsentDetails.CASLExpirationDate.addHours(-(offsetToUserTimeZone / (1000 * 60 *60))) ;
                    system.debug('inputdate**'+reqWrapper.ConsentDetails.CASLExpirationDate);
                }
                //Changes To Correct TimeZone in SFMC-End
                String[] soapProperties = new String[]{CPM_Constants.CREATED_DATE,CPM_Constants.CREATED_BY};
                    List<Object> responseValues = RetrievePreferenceTableData(soapProperties);
                System.debug(CPM_Utilities.soapStatus.statusCode);
                
                if (CPM_Utilities.soapStatus.statusCode == CPM_Constants.STATUS_500){
                    generateCPMResponse(CPM_Constants.STATUS_500,CPM_Utilities.soapStatus, email, guid);
                    continueProcess = false;
                } else {
                    DateTime dtDate = CPM_Utilities.dateCleanup((String) responseValues[0]);
                    reqWrapper.originalCreatedDate = dtDate;
                    System.debug('OriginalCreatedBy returned value: '+(String) responseValues[1]);
                    reqWrapper.originalCreatedBy = (String) responseValues[1];
                }
                System.debug('continueProcess after soap-retrieve-prefs:'+continueProcess);
                if (continueProcess){
                    soapProperties = new String[]{CPM_Constants.IS_COACH, CPM_Constants.BUSINESS_UNITS, CPM_Constants.GUID};
                        responseValues = RetrieveMasterTableData(soapProperties);
                    if (CPM_Utilities.soapStatus.statusCode == CPM_Constants.STATUS_500){
                        generateCPMResponse(CPM_Constants.STATUS_500,CPM_Utilities.soapStatus, email, guid);
                        continueProcess = false;
                    } else {
                        System.debug('responseValues: '+responseValues);
                        Boolean isCoachResponse = (responseValues[CPM_Constants.ZERO] == 'True')? true : false; 
                        reqWrapper.isCoach = (test.isRunningTest())? true : isCoachResponse;
                        reqWrapper.currentBusinessUnits = (test.isRunningTest())? CPM_Constants.BOD_NETWORK :(String) responseValues[CPM_Constants.ONE];
                        reqWrapper.guid = (String) responseValues[CPM_Constants.TWO];
                    }
                }
            }
            System.debug('continueProcess after soap-retrieve-master:'+continueProcess);
            if (continueProcess){
                // get req appName BusinessUnits, set consentBooleans on appwrapper
                Boolean lastBU = false;
                appWrapper = new CPM_ApplicationWrapper(reqWrapper.ConsentDetails.Consents, reqWrapper.appName, reqWrapper.isCoach);
                system.debug('appwrapper'+appWrapper);
                if (appWrapper.corpConsentBool!=null && !appWrapper.corpConsentBool){//added by Rajni
                    
                    reqWrapper.currentBusinessUnits = CPM_Utilities.adjustBusinessUnits(reqWrapper.currentBusinessUnits, appWrapper.businessUnits);
                    if (reqWrapper.currentBusinessUnits == CPM_Constants.EMPTYSTRING)
                        lastBU = true;
                    // unsubscribe user from BU and AllSubscribers list (using lastBU value)
                }
                system.debug('reqWrapper.email'+reqWrapper);
                if (appWrapper.corpConsentBool!=null )//If added by Rajni
                {
                    updateSubscriber(reqWrapper.email, lastBU);
                    
                    System.debug('soap StatusCode: '+CPM_Utilities.soapStatus.statusCode);
                    if (CPM_Utilities.soapStatus.statusCode == CPM_Constants.STATUS_500){
                        generateCPMResponse(CPM_Constants.STATUS_500,resStatus,email,guid);
                        continueProcess = false;
                    }
                }
            }
            System.debug('continueProcess after UpdateSubscriber: '+continueProcess);
            // Update Master Table: BusinessUnits, appName (if adding)
            if (continueProcess){
                String masterJsonBody = CPM_MarketingCloudCallouts.getUpdateMasterJsonBody(reqWrapper.currentBusinessUnits);
                res = DataExtensionCallout(CPM_Constants.PUT,endPoint+masterDataExtKey+rows+email,masterJsonBody); 
                String masterResBody = res.getBody();
                
                // Master DE Callout Error
                if (res.getStatusCode() != CPM_Constants.STATUS_200){
                    CPM_JSONWrappers.CPM_Status masterStatus = CPM_Utilities.setCPMStatus(res.getStatusCode(), CPM_Constants.PUT, res.getStatus(), CPM_Constants.MASTER_DE_UPDATE);
                    generateCPMResponse(res.getStatusCode(),masterStatus,email,guid);
                    continueProcess = false;
                }
            }
            System.debug('continueProcess after Update MasterTable: '+continueProcess);
            ReqBodyWrapper reqBodyWrapper; 
            if (continueProcess){
                setDateUserMap(reqWrapper.ConsentDetails, reqWrapper.originalCreatedDate, reqWrapper.OriginalCreatedBy);// 4/2 - Victor - fixed OriginalCreatedBy missing value error 
                reqBodyWrapper = CPM_MarketingCloudCallouts.getPrefsUpdateJsonBodies(dateUserMap,email,guid,appWrapper,null);
                System.debug('prefs: '+reqBodyWrapper.prefsReqBody);
                System.debug('audit: '+reqBodyWrapper.auditReqBody);
                res = DataExtensionCallout(CPM_Constants.PUT,endPoint+prefsDataExtKey+rows+email,reqBodyWrapper.prefsReqBody); 
                system.debug('prefsRes: '+res);
                CPM_JSONWrappers.CPM_Status prefsStatus = CPM_Utilities.setCPMStatus(res.getStatusCode(), CPM_Constants.PUT, res.getStatus(), CPM_Constants.PREFERENCES_DE_UPDATE);
                if (res.getStatusCode() != CPM_Constants.STATUS_200){
                    generateCPMResponse(res.getStatusCode(),prefsStatus,email,guid);
                    continueProcess = false;
                }
            }
            System.debug('continueProcess afterUpdatePrefs:'+continueProcess);
            if (continueProcess){
                res = DataExtensionCallout(CPM_Constants.POST,endPoint+auditsDataExtKey+rowset,reqBodyWrapper.auditReqBody); 
                Integer statCode = (res.getStatusCode() == CPM_Constants.STATUS_200)? CPM_Constants.STATUS_201 : res.getStatusCode();
                CPM_JSONWrappers.CPM_Status auditStatus = CPM_Utilities.setCPMStatus(statCode, CPM_Constants.POST, res.getStatus(), CPM_Constants.PREFERENCE_AUDIT_DE_UPDATE);
                System.debug('statcode-update: '+statCode);
                if (statCode != CPM_Constants.STATUS_200 && statCode != CPM_Constants.STATUS_201){
                    generateCPMResponse(statCode,auditStatus,email,guid);
                } else {
                    generateCPMResponse(CPM_Constants.STATUS_201,auditStatus, email, guid);// 4/3 updated Status to '201' from '200'
                }
            }
            if(resWrapper!=null &&resWrapper.responseStatus!=null && resWrapper.responseStatus.success!=null)
            {	//System.debug('resWrapper: '+resWrapper);
                RestContext.response.addHeader(CPM_Constants.CONTENT_TYPE, CPM_Constants.APPLICATION_JSON);
                RestContext.response.responseBody = Blob.valueOf(json.serialize(resWrapper));
            }
            else
            {
                RestContext.response.statusCode = CPM_Constants.STATUS_408;
                resWrapper = new CPM_JSONWrappers.CPM_Response();
                resWrapper.responseStatus= new CPM_JSONWrappers.CPM_Status();
                resWrapper.responseStatus.success=false;
                resWrapper.responseStatus.statusCode=Integer.valueOf(settings.X500Code__c);
                resWrapper.responseStatus.statusMessage=settings.error_500__c ;
                RestContext.response.responseBody = Blob.valueOf(json.serialize(resWrapper));
            }
        }
        catch(Exception ex )
        {
            system.debug(ex.getMessage());
            RestContext.response.statusCode = CPM_Constants.STATUS_500;
            resWrapper = new CPM_JSONWrappers.CPM_Response();
            resWrapper.responseStatus= new CPM_JSONWrappers.CPM_Status();
            resWrapper.responseStatus.success=false;
            resWrapper.responseStatus.statusCode=Integer.valueOf(settings.X500Code__c);
            resWrapper.responseStatus.statusMessage=settings.error_500__c ;
            RestContext.response.responseBody = Blob.valueOf(json.serialize(resWrapper));
        }
    }
    
    @HttpGet
    global static void GetUserConsent(){
        String guid = RestContext.request.params.get(CPM_Constants.GUID);
        String email = RestContext.request.params.get(CPM_Constants.EMAIL);
        String appName = RestContext.request.params.get(CPM_Constants.APPNAME);
        String consentType = RestContext.request.params.get(CPM_Constants.CONSENTTYPE);
        
        Map<String,String> mainMap = new Map<String,String>{CPM_Constants.GUID => guid,CPM_Constants.EMAIL => email, 
            												CPM_Constants.APPNAME => appName, CPM_Constants.CONSENTTYPE => consentType};
        //CPM_JSONWrappers.CPM_GetUserConsentResponse resWrapper = generateGetConsentSuccessResponse();
        RestContext.response.addHeader(CPM_Constants.CONTENT_TYPE, CPM_Constants.APPLICATION_JSON);
        //RestContext.response.responseBody = Blob.valueOf(json.serialize(resWrapper));		
    }
        
    public static CPM_JSONWrappers.CPM_CreateUserAndConsentRequest createConsentRequestParse(String jsonString) {
        CPM_JSONWrappers.CPM_CreateUserAndConsentRequest reqWrap = (CPM_JSONWrappers.CPM_CreateUserAndConsentRequest) 
            System.JSON.deserialize(jsonString, CPM_JSONWrappers.CPM_CreateUserAndConsentRequest.class);
        reqWrap.isCoach = (reqWrap.isCoach == null)? false : reqWrap.isCoach;
        System.debug('input date'+reqWrap.ConsentDetails.consentDate);
        return reqWrap;
    }
    
    public static CPM_JSONWrappers.CPM_UpdateUserConsentRequest updateConsentRequestParse(String jsonString) {
        CPM_JSONWrappers.CPM_UpdateUserConsentRequest reqWrap = (CPM_JSONWrappers.CPM_UpdateUserConsentRequest)
            System.JSON.deserialize(jsonString, CPM_JSONWrappers.CPM_UpdateUserConsentRequest.class);
        System.debug('reqWrap: '+reqWrap);
        return reqWrap;
    }
    
    /*private static CPM_JSONWrappers.CPM_GetUserConsentResponse generateGetConsentSuccessResponse(){
CPM_JSONWrappers.CPM_GetUserConsentResponse resWrap = new CPM_JSONWrappers.CPM_GetUserConsentResponse();
CPM_JSONWrappers.CPM_Status status = new CPM_JSONWrappers.CPM_Status();
status.statusCode = 1000;
status.statusMessage = 'User created successfully';
status.success = true;
resWrap.responseStatus = status;
List<CPM_JSONWrappers.CPM_Consent> consents = new List<CPM_JSONWrappers.CPM_Consent>{};
CPM_JSONWrappers.CPM_Consent consent = new CPM_JSONWrappers.CPM_Consent();
consent.consent = true;
//consent.consentDate = system.now();
consent.consentType = 'PREF1';
//consent.expirationDate = null;// Canada only
consents.add(consent);
resWrap.consents = consents;
resWrap.email = 'email@string.com';
resWrap.guid = 'thisGUID';
resWrap.appName = 'thisApp';

return resWrap;
}	*/
    
    public static void createSubscriber(String email){
        //SFMC SOAP Callout to Create the Subscriber
        System.debug('appWrapper.BusinessUnits: '+appWrapper.BusinessUnits);
        Map<String,Boolean> subscriptionMap = CPM_Utilities.getCreateSubscriptionMap(appWrapper.businessUnits);
        CPM_Utilities.createSubscriberCallout(email, subscriptionMap);// needs SubscriptionMap<Integer, Boolean>
        System.debug('soapStatus:  '+CPM_Utilities.soapStatus);
        
    }
    
    public static void updateSubscriber(String email, Boolean lastBU){
        //SFMC SOAP Callout to Create the Subscriber
        Map<String,Boolean> subscriptionMap = CPM_Utilities.getUpdateSubscriptionMap(appWrapper.businessUnits, appWrapper.corpConsentBool);
        CPM_Utilities.updateSubscriberCallout(email, subscriptionMap, lastBU);// needs SubscriptionMap<Integer, Boolean>
        System.debug('soapStatus:  '+CPM_Utilities.soapStatus);
        
    }
    
    public static List<Object> RetrievePreferenceTableData(String[] soapProperties){
        //SFMC SOAP Callout to Retrieve Data from the Subscriber's Preference Table
        List<Object> responseValues = CPM_Utilities.RetrieveDataExtensionProperties(
            email,deDetails.get(CPM_Constants.PREFERENCE_DE_NAME).DataExtensionExternalKey__c,soapProperties);
        System.debug('soapStatus:  '+CPM_Utilities.soapStatus);
        return responseValues;
    }
    
    public static List<Object> RetrieveMasterTableData(String[] soapProperties){
        //SFMC SOAP Callout to Retrieve Data from the Subscriber's Master Table
        System.debug('Master Table soapProperties: '+soapProperties);
        List<Object> responseValues = CPM_Utilities.RetrieveDataExtensionProperties(
            email,deDetails.get(CPM_Constants.MASTER_DE_NAME).DataExtensionExternalKey__c,soapProperties);
        System.debug('soapStatus:  '+CPM_Utilities.soapStatus);
        System.debug('Master Table responseValues: '+responseValues);
        return responseValues;
    }
    
    public static HTTPResponse DataExtensionCallout(String HTTPProcess, String endpoint, String body){
        return CPM_Utilities.JSONCallout(HTTPProcess, endpoint, body);
    }
    																							// 4/2 - Victor - fixed OriginalCreatedBy missing value error 
    private static void setDateUserMap(CPM_JSONWrappers.CPM_ConsentDetails det, DateTime originalCreatedDate, String originalCreatedBy){
        System.debug('det is :'+det);
        dateUserMap = new Map<String,Object>();
        dateUserMap.put(CPM_Constants.CONSENT_DATE,det.consentDate);
        dateUserMap.put(CPM_Constants.CASL_EXPIRATION_DATE,det.CASLExpirationDate);
        String userName = UserInfo.getName();
        dateUserMap.put(CPM_Constants.CREATED_BY,userName);
        dateUserMap.put(CPM_Constants.ORIGINAL_CREATED_DATE,originalCreatedDate);
        dateUserMap.put(CPM_Constants.ORIGINAL_CREATED_BY,originalCreatedBy); // 4/2 - Victor - fixed OriginalCreatedBy missing value error 
        System.debug('dateUserMap: '+dateUserMap);
    }
    
    private static void generateCPMResponse(Integer statusCode, CPM_JSONWrappers.CPM_Status status, String email, String guid){
        errorCode = statusCode;
        resWrapper = CPM_Utilities.generateCPMResponse(status, email, guid);
    }
}