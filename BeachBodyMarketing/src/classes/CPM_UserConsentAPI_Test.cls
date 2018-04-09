@isTest
public  class CPM_UserConsentAPI_Test {
    private static CPM_SFMC_APISettings__c apiSettings;
    private static CPM_APEXSettings__mdt apexSettings;
    private static Map<String, Data_Extension_Details__mdt> deDetails;
    private static BBMidNumbers__c bbMids;
    private static Application__c testApplication;
    private static Application_Business_Unit__c abu_BOD_Digital;
    private static Application_Business_Unit__c abu_BOD_Network;
    private static Question__c q_corpConsent_Consent_ALL;
    private static Question__c q_corpConsent_Consent_BOD;
    private static Question__c q_corpConsent_Consent_Network;
    private static Question__c q_corpConsent_Consent_NetworkCoach;
    private static Question__c q_coachConsent_Consent;
    private static Question__c q_healthConsent_Consent;
    private static Question__c q_healthConsent_BOD;
    private static Question__c q_corpConsent_Weekly;
    private static Question__c q_corpConsent_Recipes;
    private static Question__c q_corpConsent_News;
    private static Question_Detail__c qd_corpConsent_Consent_ALL_CA;
    private static Question_Detail__c qd_corpConsent_Consent_BOD_CA;
    private static Question_Detail__c qd_corpConsent_Consent_Network_CA;
    private static Question_Detail__c qd_corpConsent_Consent_NetworkCoach_CA;
    private static Question_Detail__c qd_coachConsent_Consent_CA;
    private static Question_Detail__c qd_healthConsent_Consent_CA;
    private static Question_Detail__c qd_healthConsent_BOD_CA;
    private static Question_Application_Detail__c aqd_corpConsent_Consent_ALL_CA;
    private static Question_Application_Detail__c aqd_corpConsent_Consent_BOD_CA;
    private static Question_Application_Detail__c aqd_corpConsent_Consent_Network_CA;
    private static Question_Application_Detail__c aqd_corpConsent_Consent_NetworkCoach_CA;
    private static Question_Application_Detail__c aqd_coachConsent_Consent_CA;
    private static Question_Application_Detail__c aqd_healthConsent_Consent_CA;
    private static Question_Application_Detail__c aqd_healthConsent_BOD_CA;
    
    private static Map<String,Question__c> qMap = new Map<String,Question__c>();
    private static Map<String,Question_Application_Detail__c> qadMap = new Map<String,Question_Application_Detail__c>();
    
    @testSetup
    static void testSetup(){
        setSettings();
        setTestRecords();
    }
    
    static void loadRecords(){
        testApplication = [Select Id, Name from Application__c where Name = 'BOD'];
        Set<String> colNames = new set<String>{'Digital_Subscription_Status','Coach_Consent_Status','Network_Subscription_Status',
                                            'Health_Consent_Status','All_Subscription_Status','healthConsent_BOD', 'Network_Coach_Signup'};
        for (Question__c q : [Select Id, Name, Preference_Column_Name__c From Question__c 
                              Where Preference_Column_Name__c IN :colNames]){
            if (q.Preference_Column_Name__c == 'Digital_Subscription_Status'){
                qMap.put('BOD_Consent',q);
                q_corpConsent_Consent_BOD = q;
            } else if (q.Preference_Column_Name__c == 'All_Subscription_Status'){
                qMap.put('All_Consent',q);
                q_corpConsent_Consent_ALL = q;
            } else if (q.Preference_Column_Name__c == 'Coach_Consent_Status'){
                qMap.put('Coach_Consent',q);
                q_coachConsent_Consent = q;
            } else if (q.Preference_Column_Name__c == 'Network_Subscription_Status'){
                qMap.put('Network_Consent',q);
                q_corpConsent_Consent_Network = q;
            } else if (q.Preference_Column_Name__c == 'Network_Coach_Signup'){
                qMap.put('Network_Coach',q);
                q_corpConsent_Consent_NetworkCoach = q;
            } else if (q.Preference_Column_Name__c == 'Health_Consent_Status'){
                qMap.put('Health_Consent',q);
                q_healthConsent_Consent = q;
            } else if (q.Preference_Column_Name__c == 'healthConsent_BOD'){
                qMap.put('Health_ConsentBOD',q);
                q_healthConsent_BOD = q;
            }
        }
        Set<Id> qIds = new Set<Id>{q_corpConsent_Consent_BOD.Id,
                                    q_coachConsent_Consent.Id,
                                    q_corpConsent_Consent_Network.Id,
                                    q_corpConsent_Consent_NetworkCoach.Id,
                                    q_healthConsent_Consent.Id,
                                    q_healthConsent_BOD.Id,
                                    q_corpConsent_Consent_ALL.Id};
        for (Question_Application_Detail__c qad :[Select Id, Name, Question__c, Question__r.Name, App_Question_Copy__c 
                                                  From Question_Application_Detail__c 
                                                  where Question__c IN :qIds]){
            if (qad.Question__c == q_corpConsent_Consent_BOD.Id){
                aqd_corpConsent_Consent_BOD_CA = qad;
                qadMap.put(qad.App_Question_Copy__c,qad);
            } else if (qad.Question__c == q_corpConsent_Consent_Network.Id){
                aqd_corpConsent_Consent_Network_CA = qad;
                qadMap.put(qad.App_Question_Copy__c,qad);
                aqd_corpConsent_Consent_Network_CA.Related_App_Question__c = aqd_corpConsent_Consent_BOD_CA.Id;
            } else if (qad.Question__c == q_corpConsent_Consent_NetworkCoach.Id){
                aqd_corpConsent_Consent_NetworkCoach_CA = qad;
                qadMap.put(qad.App_Question_Copy__c,qad);
            } else if (qad.Question__c == q_healthConsent_Consent.Id){
                aqd_healthConsent_BOD_CA = qad;
                qadMap.put(qad.App_Question_Copy__c,qad);
            } else if (qad.Question__c == q_coachConsent_Consent.Id){
                aqd_coachConsent_Consent_CA = qad;
                qadMap.put(qad.App_Question_Copy__c,qad);
            } else if (qad.Question__c == q_corpConsent_Consent_ALL.Id){
                aqd_corpConsent_Consent_ALL_CA = qad;
                qadMap.put(qad.App_Question_Copy__c,qad);
            }
        }
    }
    
    static testMethod void testCreateUserAndConsent_missingParameter(){
        Test.setMock(HttpCalloutMock.class, new CPM_HTTPCalloutMock_Test());
        Test.setMock(WebServiceMock.class, new CPM_CreateSubscriberCalloutMock_Test());
        
        
        loadRecords();
        
        String[] Ddates = String.valueOf(System.Now()).split(' ');
        String dDate = Ddates[0]+'T'+ddates[1];
        System.debug('dDate: '+dDate);
        String testJsonCreateBody = '{"guid":"","email":"","firstName":"Aaron","lastName":"Test",'+
        '"country":"CA","language":"EN","appName":"'+testApplication.Name+'","isCoach":false,"consentDetails" :{"consentDate":"'+dDate+'",'+
        '"CASLExpirationDate":"'+dDate+'","consents" :[{"consentType":"corpConsent","appQuestionId":"'+aqd_corpConsent_Consent_BOD_CA.Name+'",'+
        '"prefCenterQuestionId":"'+aqd_corpConsent_Consent_BOD_CA.Question__r.Name+'","consent":true},'+
            '{"consentType":"coachConsent","appQuestionId":"'+aqd_coachConsent_Consent_CA.Name+
            '","prefCenterQuestionId":"'+aqd_coachConsent_Consent_CA.Question__r.Name+'",'+
        '"consent":true}]}}';
        RestRequest testReq = new RestRequest();
        RestResponse testRes = new RestResponse();
        testReq.requestURI = '/services/apexrest/cpm/userconsents/';
        testReq.httpMethod = 'POST';
        testReq.requestBody = Blob.valueof(testJsonCreateBody);
        
        RestContext.request = testReq;
        RestContext.response = testRes;
        
        test.startTest();
        CPM_UserConsentAPI.createUserAndConsent();
        test.stopTest();
        System.debug('testResponse: '+testRes);
    }
    
    static testMethod void testCreateUserAndConsent(){
        Test.setMock(HttpCalloutMock.class, new CPM_HTTPCalloutMock_Test());
        Test.setMock(WebServiceMock.class, new CPM_CreateSubscriberCalloutMock_Test());
        
        
        loadRecords();
        
        String[] Ddates = String.valueOf(System.Now()).split(' ');
        String dDate = Ddates[0]+'T'+ddates[1];
        System.debug('dDate: '+dDate);
        String testJsonCreateBody = '{"guid":"","email":"Aarontest2@comitydesigns.com","firstName":"Aaron","lastName":"Test",'+
        '"country":"CA","language":"EN","appName":"'+testApplication.Name+'","isCoach":false,"consentDetails" :{"consentDate":"'+dDate+'",'+
        '"CASLExpirationDate":"'+dDate+'","consents" :[{"consentType":"corpConsent","appQuestionId":"'+aqd_corpConsent_Consent_BOD_CA.Name+'",'+
        '"prefCenterQuestionId":"'+aqd_corpConsent_Consent_BOD_CA.Question__r.Name+'","consent":true},'+
            '{"consentType":"coachConsent","appQuestionId":"'+aqd_coachConsent_Consent_CA.Name+
            '","prefCenterQuestionId":"'+aqd_coachConsent_Consent_CA.Question__r.Name+'",'+
        '"consent":true}]}}';
        RestRequest testReq = new RestRequest();
        RestResponse testRes = new RestResponse();
        testReq.requestURI = '/services/apexrest/cpm/userconsents/';
        testReq.httpMethod = 'POST';
        testReq.requestBody = Blob.valueof(testJsonCreateBody);
        
        RestContext.request = testReq;
        RestContext.response = testRes;
        
        test.startTest();
        CPM_UserConsentAPI.createUserAndConsent();
        test.stopTest();
        System.debug('testResponse: '+testRes);
    }
    
    static testMethod void testUpdateUserConsent_missingParameter(){
        Test.setMock(HttpCalloutMock.class, new CPM_HTTPCalloutMock_Test());
        Test.setMock(WebServiceMock.class, new CPM_RetrieveDataExtCalloutMock_Test());
        //Test.setMock(WebServiceMock.class, new CPM_UpdateSubscriberCalloutMock_Test());
        
        loadRecords();
        
        String[] Ddates = String.valueOf(System.Now()).split(' ');
        String dDate = String.valueOf(System.Now());
        System.debug('dDate: '+dDate);
        String testJSonUpdateConsentBody = '{"appName": "'+testApplication.Name+
            '", "consentDetails": {"CASLExpirationDate":"2018-03-25T08:17:00.227Z","consentDate": "2018-03-25T08:17:00.227Z",'+
            '"consents": [{"consentType": "CorpConsent","appQuestionID": "'+aqd_corpConsent_Consent_BOD_CA.Name+'","prefCenterQuestionID": "'+q_corpConsent_Consent_BOD.Name+'","consent": false}]}}';
        
        RestRequest testReq = new RestRequest();
        RestResponse testRes = new RestResponse();
        testReq.params.put('email','');
        testReq.params.put('guid','');
        testReq.requestURI = '/services/apexrest/cpm/userconsents/';
        testReq.httpMethod = 'PUT';
        testReq.requestBody = Blob.valueof(testJSonUpdateConsentBody);
        
        RestContext.request = testReq;
        RestContext.response = testRes;
        
        test.startTest();
        
        CPM_UserConsentAPI.updateUserConsent();
        System.AssertEquals('Mandatory Parameter Missing :missing Subscriber Key (email or guid)',CPM_UserConsentAPI.resStatus.statusMessage);
        test.stopTest();
        
    }
    
    static testMethod void testUpdateUserConsent(){
        Test.setMock(HttpCalloutMock.class, new CPM_HTTPCalloutMock_Test());
        Test.setMock(WebServiceMock.class, new CPM_RetrieveDataExtCalloutMock_Test());
        //Test.setMock(WebServiceMock.class, new CPM_UpdateSubscriberCalloutMock_Test());
        
        loadRecords();
        
        String[] Ddates = String.valueOf(System.Now()).split(' ');
        String dDate = String.valueOf(System.Now());
        System.debug('dDate: '+dDate);
        String testJSonUpdateConsentBody = '{"appName": "'+testApplication.Name+
            '", "consentDetails": {"CASLExpirationDate":"2018-03-25T08:17:00.227Z","consentDate": "2018-03-25T08:17:00.227Z",'+
            '"consents": [{"consentType": "CorpConsent","appQuestionID": "'+aqd_corpConsent_Consent_BOD_CA.Name+'","prefCenterQuestionID": "'+q_corpConsent_Consent_BOD.Name+'","consent": false}]}}';
        
        RestRequest testReq = new RestRequest();
        RestResponse testRes = new RestResponse();
        testReq.params.put('email','Aarontest2@comitydesigns.com');
        testReq.params.put('guid','');
        testReq.requestURI = '/services/apexrest/cpm/userconsents/';
        testReq.httpMethod = 'PUT';
        testReq.requestBody = Blob.valueof(testJSonUpdateConsentBody);
        
        RestContext.request = testReq;
        RestContext.response = testRes;
        
        test.startTest();
        
        CPM_UserConsentAPI.updateUserConsent();
        System.debug(CPM_UserConsentAPI.resStatus);
        test.stopTest();
        
    }
    
    static void setSettings(){
        apiSettings = CPM_TestUtilities.getTestApiSettings();
        insert apiSettings;
        apexSettings = CPM_Utilities.getAPEXSettings();
        deDetails = CPM_Utilities.getDeDetails();
        bbMids = CPM_TestUtilities.getBBMidNumbers();
        insert bbMids;
    }
    
    static void setTestRecords(){
        testApplication = CPM_TestUtilities.getTestApplication('BOD','BOD Android');
        insert testApplication;
        testApplication = [Select Id, Name from Application__c where Id = :testApplication.Id];
        abu_BOD_Digital = CPM_TestUtilities.getTestAppBU(testApplication.Id, 'Digital');
        abu_BOD_Network = CPM_TestUtilities.getTestAppBU(testApplication.Id, 'Network');
        insert new List<Application_Business_Unit__c>{abu_BOD_Digital,abu_BOD_Network};
        q_corpConsent_Consent_ALL = CPM_TestUtilities.getTestQuestion(
            'All_Subscription_Status', 'Consent', 'corpConsent', true, null, null);
        insert q_corpConsent_Consent_ALL;
        q_corpConsent_Consent_BOD = CPM_TestUtilities.getTestQuestion(
            'Digital_Subscription_Status', 'Consent', 'corpConsent', true, q_corpConsent_Consent_ALL.Id, 'Banner Question');
        q_corpConsent_Consent_Network = CPM_TestUtilities.getTestQuestion(
            'Network_Subscription_Status', 'Consent', 'corpConsent', true, q_corpConsent_Consent_ALL.Id, 'Banner Question');
        q_coachConsent_Consent = CPM_TestUtilities.getTestQuestion(
            'Coach_Consent_Status', 'Consent', 'coachConsent', true, null, null);
        q_healthConsent_Consent = CPM_TestUtilities.getTestQuestion(
            'Health_Consent_Status', 'Consent', 'healthConsent', true, null, null);
        insert new List<Question__c>{q_corpConsent_Consent_BOD,q_corpConsent_Consent_Network,q_coachConsent_Consent,q_healthConsent_Consent};
        q_corpConsent_Consent_BOD = [Select Id, Name From Question__c Where Id = :q_corpConsent_Consent_BOD.Id];
        
        q_corpConsent_Weekly = CPM_TestUtilities.getTestQuestion(
            'Digital_Weekly', 'Preference', 'corpConsent', true, q_corpConsent_Consent_BOD.Id, null);
        q_corpConsent_Recipes = CPM_TestUtilities.getTestQuestion(
            'Digital_Recipes', 'Preference', 'corpConsent', true, q_corpConsent_Consent_BOD.Id, null);
        q_corpConsent_News = CPM_TestUtilities.getTestQuestion(
            'Digital_News', 'Preference', 'corpConsent', true, q_corpConsent_Consent_BOD.Id, null);
        q_corpConsent_Consent_NetworkCoach = CPM_TestUtilities.getTestQuestion(
            'Network_Coach_Signup', 'Consent', 'corpConsent', true, q_corpConsent_Consent_Network.Id, 'User Coach');
        q_healthConsent_BOD  = CPM_TestUtilities.getTestQuestion(
            'healthConsent_BOD', 'Consent', 'healthConsent', true, q_healthConsent_Consent.Id, null);
        insert new List<Question__c>{q_corpConsent_Weekly,q_corpConsent_Recipes,q_corpConsent_News,q_corpConsent_Consent_NetworkCoach,q_healthConsent_BOD};
        qd_corpConsent_Consent_ALL_CA = CPM_TestUtilities.getTestDetail(
            q_corpConsent_Consent_BOD.Id,'allSubscription_CA', 'CA', 'FR', true);
        qd_corpConsent_Consent_BOD_CA = CPM_TestUtilities.getTestDetail(
            q_corpConsent_Consent_BOD.Id,'digitalSubscription_CA', 'CA', 'FR', true);
        qd_corpConsent_Consent_Network_CA = CPM_TestUtilities.getTestDetail(
            q_corpConsent_Consent_Network.Id,'networkSubscsription_CA', 'CA', 'FR', true);
        qd_coachConsent_Consent_CA = CPM_TestUtilities.getTestDetail(
            q_coachConsent_Consent.Id,'coach_Consent_CA', 'CA', 'FR', true);
        qd_healthConsent_Consent_CA = CPM_TestUtilities.getTestDetail(
            q_healthConsent_Consent.Id,'health_Consent_CA', 'CA', 'FR', true);
        qd_healthConsent_BOD_CA = CPM_TestUtilities.getTestDetail(
            q_healthConsent_BOD.Id,'health_BOD', 'CA', 'FR', true);
        insert new List<Question_Detail__c>{qd_corpConsent_Consent_ALL_CA,qd_corpConsent_Consent_BOD_CA,
            qd_corpConsent_Consent_Network_CA,qd_coachConsent_Consent_CA,qd_healthConsent_Consent_CA,qd_healthConsent_BOD_CA};
        
        qd_corpConsent_Consent_NetworkCoach_CA = CPM_TestUtilities.getTestDetail(
            q_corpConsent_Consent_NetworkCoach.Id,'networkCoach_CA', 'CA', 'FR', true);
        insert qd_corpConsent_Consent_NetworkCoach_CA;
        
        aqd_corpConsent_Consent_ALL_CA = CPM_TestUtilities.getTestAppDetail(
            'allSubCA', testApplication.Id, true, q_corpConsent_Consent_ALL.Id,qd_corpConsent_Consent_ALL_CA.Id);
        aqd_corpConsent_Consent_BOD_CA = CPM_TestUtilities.getTestAppDetail(
            'digSubCA', testApplication.Id, true, q_corpConsent_Consent_BOD.Id,qd_corpConsent_Consent_BOD_CA.Id);
        aqd_corpConsent_Consent_Network_CA = CPM_TestUtilities.getTestAppDetail(
            'netSubCA', testApplication.Id, true, q_corpConsent_Consent_Network.Id,qd_corpConsent_Consent_Network_CA.Id);
        aqd_corpConsent_Consent_NetworkCoach_CA = CPM_TestUtilities.getTestAppDetail(
            'netCchCA', testApplication.Id, true, q_corpConsent_Consent_NetworkCoach.Id,qd_corpConsent_Consent_NetworkCoach_CA.Id);
        aqd_coachConsent_Consent_CA = CPM_TestUtilities.getTestAppDetail(
            'coachSubCA', testApplication.Id, true, q_coachConsent_Consent.Id,qd_coachConsent_Consent_CA.Id);
        aqd_healthConsent_Consent_CA = CPM_TestUtilities.getTestAppDetail(
            'healthSubCA', testApplication.Id, true, q_healthConsent_Consent.Id,qd_healthConsent_Consent_CA.Id);
        aqd_healthConsent_BOD_CA = CPM_TestUtilities.getTestAppDetail(
            'healthBODCA', testApplication.Id, true, q_healthConsent_BOD.Id,qd_healthConsent_BOD_CA.Id);
        insert new List<Question_Application_Detail__c>{aqd_corpConsent_Consent_ALL_CA,aqd_corpConsent_Consent_BOD_CA,aqd_corpConsent_Consent_Network_CA,
                                            aqd_corpConsent_Consent_NetworkCoach_CA,aqd_coachConsent_Consent_CA,aqd_healthConsent_Consent_CA,aqd_healthConsent_BOD_CA};
        Set<Id> qadIds = new Set<Id>{aqd_corpConsent_Consent_ALL_CA.Id,aqd_corpConsent_Consent_BOD_CA.Id,aqd_corpConsent_Consent_Network_CA.Id,
                                        aqd_coachConsent_Consent_CA.Id,aqd_healthConsent_Consent_CA.Id,aqd_healthConsent_BOD_CA.Id,
                                        aqd_corpConsent_Consent_NetworkCoach_CA.Id};
        for (Question_Application_Detail__c qad :[Select Id, Name, Question__c, Question__r.Name From Question_Application_Detail__c 
                                                  where Id IN :qadIds]){
            if (qad.Id == aqd_coachConsent_Consent_CA.Id){
                aqd_coachConsent_Consent_CA = qad;
            } else if (qad.Id == aqd_corpConsent_Consent_Network_CA.Id){
                aqd_corpConsent_Consent_Network_CA = qad;
            } else if (qad.Id == aqd_healthConsent_BOD_CA.Id){
                aqd_healthConsent_BOD_CA = qad;
            } else if (qad.Id == aqd_healthConsent_Consent_CA.Id){
                aqd_healthConsent_Consent_CA = qad;
            } else if (qad.Id == aqd_corpConsent_Consent_BOD_CA.Id){
                aqd_corpConsent_Consent_BOD_CA = qad;
            } else if (qad.Id == aqd_corpConsent_Consent_ALL_CA.Id){
                aqd_corpConsent_Consent_ALL_CA = qad;
            } else if (qad.Id == aqd_corpConsent_Consent_NetworkCoach_CA.Id){
                aqd_corpConsent_Consent_NetworkCoach_CA = qad;
            }
        }
        aqd_corpConsent_Consent_Network_CA.Related_App_Question__c = aqd_corpConsent_Consent_BOD_CA.Id;
        update aqd_corpConsent_Consent_Network_CA;
    }
}