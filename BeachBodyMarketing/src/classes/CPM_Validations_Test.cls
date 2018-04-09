@isTest
public class CPM_Validations_Test {
	private static Question__c testQ;
    private static Application__c testApp;
    private static Question_Application_Detail__c qad;
    
    private static void setTestRecords(){
        testApp = CPM_TestUtilities.getTestApplication('BBLive', 'BBLive');
        insert testApp;
        testQ = CPM_TestUtilities.getTestQuestion('testQuestion', 'Consent', 'CorpConsent', true, null, null);
        insert testQ;
        testQ = [select id, Name from Question__c];
        qad = CPM_TestUtilities.getTestAppDetail('testAppDetail', testApp.Id, false, testQ.Id, null);
        insert qad;
        qad = [Select Id, Name from Question_Application_Detail__c];
    }
    
    @isTest
    static void testMissingParameters(){
        setTestRecords();
        CPM_JSONWrappers.CPM_CreateUserAndConsentRequest reqWrapper = new CPM_JSONWrappers.CPM_CreateUserAndConsentRequest();
        // Test for missing Parameters
        String jsonString = CPM_TestUtilities.getCreateJsonString(testQ.Name,qad.Name);
        reqWrapper = CPM_UserConsentAPI.createConsentRequestParse(jsonString);
        reqWrapper.Country = null;
        reqWrapper.ConsentDetails.ConsentDate = null;
        reqWrapper.ConsentDetails.Consents[0].ConsentType = null;
        jsonString = Json.serialize(reqWrapper);
        CPM_JSONWrappers.CPM_Status status = CPM_Validations.ValidateRequest(jsonString, 'Create', null, null);
        System.assertNotEquals(null, status);
        System.AssertEquals('Mandatory Parameter Missing :country,consentDate,consentType',status.StatusMessage);//
        status = null;
        
        jsonString = CPM_TestUtilities.getCreateJsonString(testQ.Name,qad.Name);
        reqWrapper = new CPM_JSONWrappers.CPM_CreateUserAndConsentRequest();
        //test for invalid email
        reqWrapper = CPM_UserConsentAPI.createConsentRequestParse(jsonString);
        
        reqWrapper.email = reqWrapper.email.replace('@','');
        jsonString = Json.serialize(reqWrapper);
        System.debug('jsonString: '+jsonString);
        status = CPM_Validations.ValidateRequest(jsonString, 'Create', null,null);
        System.assertNotEquals(null, status);
        System.AssertEquals('Mandatory Parameter Missing Values given in Request are not correct for:email',status.statusMessage);
        status = null;

        jsonString = CPM_TestUtilities.getCreateJsonString(testQ.Name,qad.Name);
        Map<String, Object> jsonMap = (Map<String,Object>) JSON.deserializeUntyped(jsonString);
        Map<String, Object> cDetailsMap = (Map<String,Object>) jsonMap.get('consentDetails');
        String consDate = (String) cDetailsMap.get('consentDate');
        consDate = consDate.replace('2018','21');
        cDetailsMap.put('consentDate',consDate);
        jsonMap.put('consentDetails',cDetailsMap);
        jsonString = json.serialize(jsonMap);
        System.debug('jsonString.dates: '+jsonString);
        status = CPM_Validations.ValidateRequest(jsonString, 'Create', null, null);
        System.assertNotEquals(null, status);
        System.AssertEquals('Mandatory Parameter Missing consentDate: requires correct formatting (YYYY-MM-DDTHH:MM:SS.MMMZ)', status.statusMessage);
    }
    
    @isTest
    static void testValidatePicklistValues(){
        setTestRecords();
        CPM_JSONWrappers.CPM_CreateUserAndConsentRequest reqWrapper = new CPM_JSONWrappers.CPM_CreateUserAndConsentRequest();
        
        String jsonString = CPM_TestUtilities.getCreateJsonString(testQ.Name,qad.Name);
        // test validated json
        System.debug('jsonString: '+jsonString);
        CPM_JSONWrappers.CPM_Status status = CPM_Validations.validateRequestPicklistValues(jsonString, 'Create', null, null);
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
        status = CPM_Validations.validateRequestPicklistValues(jsonString, 'Create', null, null);
        
        jsonString = CPM_TestUtilities.getCreateJsonString(testQ.Name,qad.Name);
        jsonMap = (Map<String,Object>) JSON.deserializeUntyped(jsonString);
        cDetailsMap = (Map<String,Object>) jsonMap.get('consentDetails');
        consentObjects = (List<Object>) cDetailsMap.get('consents');
        Map<String,Object> obj = (Map<String,Object>) consentObjects[0];
        Map<String,Object> obj2 = new Map<String,Object>();
        obj2.put('consentType','CorpConsent');
        obj2.put('consent',true);
        obj2.put('appQuestionId','A-301');
        obj2.put('prefCenterQuestionId','Q-301');
        Object o2 = obj2;
        consentObjects.add(o2);
        cDetailsMap.put('consents',consentObjects);
        jsonMap.put('consentDetails',cDetailsMap);
        jsonString = json.serialize(jsonMap);
        status = CPM_Validations.validateRequestPicklistValues(jsonString, 'Create', null, null);
        
        jsonString = CPM_TestUtilities.getCreateJsonString(testQ.Name,qad.Name);
        jsonMap = (Map<String,Object>) JSON.deserializeUntyped(jsonString);
        cDetailsMap = (Map<String,Object>) jsonMap.get('consentDetails');
        consentObjects = (List<Object>) cDetailsMap.get('consents');
        obj = (Map<String,Object>) consentObjects[0];
        
        obj.put('appQuestionId','A-301');
        obj.put('prefCenterQuestionId','Q-301');
        consentObjects[0] = obj;
        
        cDetailsMap.put('consents',consentObjects);
        jsonMap.put('consentDetails',cDetailsMap);
        jsonString = json.serialize(jsonMap);
        status = CPM_Validations.validateRequestPicklistValues(jsonString, 'Create', null, null);
               
        jsonString = CPM_TestUtilities.getUpdateConsentJsonString(testQ.Name,qad.Name);
        jsonMap = (Map<String,Object>) JSON.deserializeUntyped(jsonString);
        String email = (String) jsonMap.get('email');
        String guid = (String) jsonMap.get('guid');
        status = CPM_Validations.validateRequestPicklistValues(jsonString, 'updateConsent', email, guid);
    }
}