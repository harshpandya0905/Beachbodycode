@isTest
public class CPM_Utilities_Test {
    @isTest
    static void testOAuthCallout(){
        Test.setMock(HttpCalloutMock.class, new CPM_HTTPCalloutMock_Test());
        CPM_SFMC_APISettings__c apiSettings = CPM_TestUtilities.getTestApiSettings();
        insert apiSettings;
        test.Starttest();
        String accessToken = CPM_Utilities.getMarketingCloudOAuthToken();
        test.StopTest();
        System.assertEquals('thisIsAnAccessToken', accessToken);
        
    }
    
    @isTest
    static void testCreateSubscriber(){
        Test.setMock(WebServiceMock.class, new CPM_CreateSubscriberCalloutMock_Test());
        BBMidNumbers__c bbMids = CPM_TestUtilities.getBBMidNumbers();
        insert BBMids;
        Map<String,Boolean> subscriptionMap = CPM_TestUtilities.getTestSubscriptionMap();
        test.Starttest();
        CPM_Utilities.createSubscriberCallout('Aarontest2@comitydesigns.com', subscriptionMap);
        test.stopTest();
        System.AssertEquals(200,CPM_Utilities.soapStatus.statusCode);
        System.AssertEquals('Success',CPM_Utilities.soapStatus.statusMessage);
    }
    
    @isTest
    static void testMissingParameters(){
        Application__c testApp = CPM_TestUtilities.getTestApplication('BBLive', 'BBLive');
        insert testApp;
        Question__c testQ = CPM_TestUtilities.getTestQuestion('testQuestion', 'Consent', 'CorpConsent', true, null, null);
        insert testQ;
        testQ = [select id, Name from Question__c];
        Question_Application_Detail__c qad = CPM_TestUtilities.getTestAppDetail('testAppDetail', testApp.Id, false, testQ.Id, null);
        insert qad;
        qad = [Select Id, Name from Question_Application_Detail__c];
        CPM_JSONWrappers.CPM_CreateUserAndConsentRequest reqWrapper = new CPM_JSONWrappers.CPM_CreateUserAndConsentRequest();
        // Test for missing Parameters
        String jsonString = CPM_TestUtilities.getJsonString(testQ.Name,qad.Name);
        reqWrapper = CPM_UserConsentAPI.createConsentRequestParse(jsonString);
        reqWrapper.Country = null;
        reqWrapper.ConsentDetails.ConsentDate = null;
        reqWrapper.ConsentDetails.Consents[0].ConsentType = null;
        jsonString = Json.serialize(reqWrapper);
        CPM_JSONWrappers.CPM_Status status = CPM_Utilities.ValidateRequest(jsonString, true);
        System.assertNotEquals(null, status);
        System.AssertEquals('Mandatory Parameter Missing :country,consentDate,consentType',status.StatusMessage);//
        status = null;
        
        jsonString = CPM_TestUtilities.getJsonString(testQ.Name,qad.Name);
        reqWrapper = new CPM_JSONWrappers.CPM_CreateUserAndConsentRequest();
        //test for invalid email
        reqWrapper = CPM_UserConsentAPI.createConsentRequestParse(jsonString);
        
        reqWrapper.email = reqWrapper.email.replace('@','');
        jsonString = Json.serialize(reqWrapper);
        System.debug('jsonString: '+jsonString);
        status = CPM_Utilities.ValidateRequest(jsonString, true);
        System.assertNotEquals(null, status);
        System.AssertEquals('Mandatory Parameter Missing Values given in Request are not correct for:email',status.statusMessage);
        status = null;

        jsonString = CPM_TestUtilities.getJsonString(testQ.Name,qad.Name);
        Map<String, Object> jsonMap = (Map<String,Object>) JSON.deserializeUntyped(jsonString);
        Map<String, Object> cDetailsMap = (Map<String,Object>) jsonMap.get('consentDetails');
        String consDate = (String) cDetailsMap.get('consentDate');
        consDate = consDate.replace('2018','21');
        cDetailsMap.put('consentDate',consDate);
        jsonMap.put('consentDetails',cDetailsMap);
        jsonString = json.serialize(jsonMap);
        System.debug('jsonString.dates: '+jsonString);
        status = CPM_Utilities.ValidateRequest(jsonString, true);
        System.assertNotEquals(null, status);
        System.AssertEquals('Mandatory Parameter Missing consentDate: requires correct formatting (YYYY-MM-DDTHH:MM:SS.MMMZ)', status.statusMessage);
        
    }
    
    @isTest
    static void testValidatePicklistValues(){
        Application__c testApp = CPM_TestUtilities.getTestApplication('BBLive', 'BBLive');
        insert testApp;
        Question__c testQ = CPM_TestUtilities.getTestQuestion('testQuestion', 'Consent', 'CorpConsent', true, null, null);
        insert testQ;
        testQ = [select id, Name from Question__c];
        Question_Application_Detail__c qad = CPM_TestUtilities.getTestAppDetail('testAppDetail', testApp.Id, false, testQ.Id, null);
        insert qad;
        qad = [Select Id, Name from Question_Application_Detail__c];
        CPM_JSONWrappers.CPM_CreateUserAndConsentRequest reqWrapper = new CPM_JSONWrappers.CPM_CreateUserAndConsentRequest();
        
        String jsonString = CPM_TestUtilities.getJsonString(testQ.Name,qad.Name);
        // test validated json
        System.debug('jsonString: '+jsonString);
        CPM_JSONWrappers.CPM_Status status = CPM_Utilities.validateRequestPicklistValues(jsonString, true);
        System.AssertEquals(null,status);
        // test invalid json
        Map<String, Object> jsonMap = (Map<String,Object>) JSON.deserializeUntyped(jsonString);
        jsonMap.put('country','CB');
        jsonMap.put('language','EX');
        jsonMap.put('appName','');
        Map<String, Object> cDetailsMap = (Map<String,Object>) jsonMap.get('consentDetails');
        List<Object> consentObjects = (List<Object>) cDetailsMap.get('consents');
        Map<String, Object> consent;
        for (Object o : consentObjects){
            consent = (Map<String,Object>) o;
            consent.put('consentType','Banner');
            consent.put('prefCenterQuestionId','Q-301');
            //consent.put('appQuestionId','A-301');
            o = consent;
        }
        cDetailsMap.put('consents',consentObjects);
        jsonMap.put('consentDetails',cDetailsMap);
        jsonString = json.serialize(jsonMap);
        status = CPM_Utilities.validateRequestPicklistValues(jsonString, true);
        
        jsonString = CPM_TestUtilities.getJsonString(testQ.Name,qad.Name);
        jsonMap = (Map<String,Object>) JSON.deserializeUntyped(jsonString);
        cDetailsMap = (Map<String,Object>) jsonMap.get('consentDetails');
        consentObjects = (List<Object>) cDetailsMap.get('consents');
        
        for (Object o : consentObjects){
            consent = (Map<String,Object>) o;
            consent.put('appQuestionID','A-301');
            o = consent;
        }
        cDetailsMap.put('consents',consentObjects);
        jsonMap.put('consentDetails',cDetailsMap);
        jsonString = json.serialize(jsonMap);
        status = CPM_Utilities.validateRequestPicklistValues(jsonString, true);
    }
    
    @isTest
    static void testDateCleanup(){
        String dateVal = '3/17/2018 7:00:00 PM';
        DateTime dt = CPM_Utilities.dateCleanup(dateval);
        System.AssertEquals(dt,DateTime.valueOf('2018-03-17 14:00:00').addhours(-7));
        
    }
    
    /*@isTest
    static void testMainQuestion(){
        Question__c testQuestion = CPM_TestUtilities.getTestQuestion('PrefColName', 'Consent', 'CorpConsent', true, null, null);
        insert testQuestion;
        testQuestion = [Select Id, Name from Question__c where Id = :testQuestion.Id];
        Map<String,Question__c> qMap = CPM_Utilities.getMainQuestionMap(new set<String>{testQuestion.Name});
		System.AssertEquals(qMap.get(testQuestion.Id).Name,testQuestion.Name);
    }*/
    
    @isTest
    static void testGetUpdateSubscriptionMap(){
        Map<String,Boolean> subMap = CPM_Utilities.getUpdateSubscriptionMap(new Set<String>{'BBLive'},true);
        System.AssertEquals(subMap.get('BBLive'),true);
    }
    
    @isTest
    static void testSetCPMStatus(){
        CPM_APEXSettings__mdt settings = CPM_Utilities.getAPEXSettings();
        CPM_JSONWrappers.CPM_Status testStatus = new CPM_JSONWrappers.CPM_Status();
        testStatus = CPM_Utilities.setCPMStatus(401,CPM_Constants.POST,'false',CPM_Constants.ERROR);
        System.AssertEquals(integer.valueOf(settings.X401Code__c),testStatus.StatusCode);
        System.assertEquals(settings.error_401__c+' '+'ERROR',testStatus.statusMessage);
        //testStatus = new CPM_JSONWrappers.CPM_Status();
        //testStatus = CPM_Utilities.setCPMStatus(500,CPM_Constants.PUT,'false',CPM_Constants.ERROR);
    }

}