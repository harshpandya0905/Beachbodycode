@isTest
public class CPM_TestUtilities {
	
    public static String getCreateJsonString(String qName, String qadName){  
        return '{"guid":"victortest1@comitydesigns.com",'+
        '"email":"victortest1@comitydesigns.com",'+
        '"firstName":"Victor",'+
        '"lastName":"Manning",'+
        '"country":"CA",'+
        '"language":"EN",'+
        '"appName":"BBLive",'+
        '"isCoach":false,'+
        '"consentDetails" :{'+
            '"consentDate":"2018-04-02T12:51:02.227Z",'+
            '"CASLExpirationDate":"2018-04-02T12:51:02.227Z",'+
            '"consents" :[{'+
            '"consentType":"corpConsent",'+
            '"appQuestionId":"'+qadName+'",'+
            '"prefCenterQuestionId":"'+qName+'",'+
            '"consent":true}]'+
            '}'+
        '}';
    }
    
    public static String getUpdateConsentJsonString(String qName, String qadName){
        String jsonString = '{'+
            '"appName":"BBLive",'+
            '"consentDetails" :{'+
                '"consentDate":"2018-04-02T12:51:02.227Z",'+
                '"CASLExpirationDate":"2018-04-02T12:51:02.227Z",'+
                '"consents" :[{'+
                    '"consentType":"corpConsent",'+
                    '"appQuestionId":"'+qadName+'",'+
                    '"prefCenterQuestionId":"'+qName+'",'+
                    '"consent":true}]'+
            '}'+
        '}';
        
        return jsonString;
    }
    
    public static CPM_SFMC_APISettings__c getTestApiSettings (){
        CPM_SFMC_APISettings__c apiSettings = new CPM_SFMC_APISettings__c();
        apiSettings.ClientIdDev__c = 'clientId';
        apiSettings.ClientSecretDev__c = 'clientSecret';
        apiSettings.SFMC_API_Password__c = 'password';
        apiSettings.SFMC_API_UserName__c = 'username@testorg.com';
        return apiSettings;
    }
    
    public static BBMidNumbers__c getBBMidNumbers(){
        BBMidNumbers__c bbmids = new BBMidNumbers__c();
        bbMids.Digital__c = '6422699';
        bbMids.AllSubscribersList__c = '627470';
        bbMIds.BBLive__c = '6422698';
        bbMIds.Direct_Marketing__c = '6422700';
        bbMIds.Network__c = '6422701';
        return bbMIds;
    }
    
    public static Map<String,Boolean> getTestSubscriptionMap(){
        Map<String,Boolean> subscriptionMap = new Map<String,Boolean>();
        subscriptionMap.put('BBLive',true);
        subscriptionMap.put('Digital',false);
        subscriptionMap.put('Direct Marketing',false);
        subscriptionMap.put('AllSubscribersList',false);
        subscriptionMap.put('Network',false);
        return subscriptionMap;
    }
        
    public static Question__c getTestQuestion(String colId, String cat, String consType, Boolean active, String parentId, String relBy){
        return new Question__c(Preference_Column_Name__c = colId, Category__c = cat, Consent_Type__C = consType,
                              isActive__c = active, Parent_Consent__c = parentId, Related_By__c = relBy);
    }
    
    public static Question_Detail__c getTestDetail(Id prefQId, String prefCopy, String country, String language, Boolean active){
        return new Question_Detail__c(Preference_Center_Question_Id__c = prefQId, Preference_Center_Question_Copy__c = prefCopy,
                                     Country__c = country, Language__c = language, isActive__c = active);
    }
    
    public static Question_Application_Detail__c getTestAppDetail(String qCopy, Id appId, Boolean hasSpon, Id qId, Id qdId){
        return new Question_Application_Detail__c(App_Question_Copy__c = qCopy, Application_Name__c = appId, has_Sponsor__c = hasSpon,
                                                 Question__c = qId, Question_Detail__c = qdId);
    }
    
    public static Application__c getTestApplication(String name, String appPlat){
        return new Application__c(Name = name, Application_Platform__c = appPlat);
    }
    
    public static Application_Business_Unit__c getTestAppBU(Id appId, String bu){
        return new Application_Business_Unit__c(Application__c = appId, Business_Unit__c = bu);
    }
}