public class CPM_Validations {
	public static String missingParameters = CPM_Constants.EMPTYSTRING;
    public static Map<String, Object> main;
    public static Map<String, Object> details;
    public static List<Object> consents;
    
    public static CPM_JSONWrappers.CPM_Status validateRequest(String requestBody,String process, String email, String guid){//, string APIProcess
        
        main = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
        
        if (process == 'updateConsent'){
            if (!String.isBlank(email))
            	main.put('email',email);
            else 
                main.put('guid',guid);
        }
        System.debug('Main Map email is '+main.get('email'));    
        String missingParameters = checkReqParameters(main,process); 
        if (missingParameters != CPM_Constants.EMPTYSTRING){
            return CPM_Utilities.setCPMStatus(CPM_Constants.STATUS_400,CPM_Constants.POST, CPM_Constants.ERROR, CPM_Constants.COLON+missingParameters);
        }
        
        Map<String, Object> cDetails = (Map<String, Object>) main.get(CPM_Constants.CONSENT_DETAILS);
        String dateIssue = CPM_Constants.EMPTYSTRING;
        dateIssue += (!ValidateDate((String) cDetails.get(CPM_Constants.CONSENT_DATE)))? CPM_Constants.CONSENT_DATE : CPM_Constants.EMPTYSTRING;
        
        dateIssue += (!ValidateDate((String) cDetails.get(CPM_Constants.CASL_EXPIRATION_DATE)))? 
            ((dateIssue != CPM_Constants.EMPTYSTRING)? CPM_Constants.COMMA+CPM_Constants.EMPTYSPACE+CPM_Constants.CASL_EXPIRATION_DATE : CPM_Constants.CASL_EXPIRATION_DATE) : CPM_Constants.EMPTYSTRING; 
        System.debug('dateIssue after CASLDate: '+dateIssue);
        dateIssue += (dateIssue != CPM_Constants.EMPTYSTRING)? ': '+CPM_Constants.ERROR_DATE_FORMAT : CPM_Constants.EMPTYSTRING;
        if (dateIssue != CPM_Constants.EMPTYSTRING){
            return CPM_Utilities.setCPMStatus(CPM_Constants.STATUS_400,CPM_Constants.POST, CPM_Constants.ERROR, dateIssue);
        }
        
        //Changes CPM-207 incorrect Picklist values start
        CPM_JSONWrappers.CPM_Status stResponse= validateRequestPicklistValues(requestBody,process, email, guid);
        if(stResponse != null)
        {
            return stResponse;
        }
        //Changes CPM-207 incorrect Picklist values end
        
        
        return null;
    }
    
    public static Boolean validateEmail(String email) {
        Boolean res = true;
        System.debug('email in validation is '+email);
        Pattern MyPattern = Pattern.compile(CPM_Constants.EMAIL_REGEX);
        Matcher MyMatcher = MyPattern.matcher(email);
        
        if (!MyMatcher.matches()) 
            res = false;
        return res;	
    }
    
    public static Boolean validateDate(String sDate){
        
        Pattern p = Pattern.compile(CPM_Constants.DATETIME_REGEX);
        Matcher m = p.matcher(sDate);
        System.debug('Date validated: '+m.matches());
        return m.matches();
    }
    
    public static String checkReqParameters(Map<String, Object> main, String process){
        missingParameters = '';
        Set<String> paramExceptions = (process == 'Create')? CPM_Constants.CREATE_PARAMETER_EXCEPTIONS : 
        (process == 'updateConsent')? new Set<String>{'email', 'guid'} : new Set<String>();
        Set<String> mainKeys = (process == 'Create')? CPM_Constants.CREATE_BODY_MAIN_KEYS : 
        						(process == 'updateConsent')? CPM_Constants.UPDATE_CONSENT_BODY_MAIN_KEYS :
        						CPM_Constants.UPDATE_USER_BODY_KEYS;
        
        checkParameters(main,paramExceptions,mainKeys, process);
        if (main.get(CPM_Constants.CONSENT_DETAILS) != null){
            details = (Map<String,Object>) main.get(CPM_Constants.CONSENT_DETAILS);
            checkParameters(details,paramExceptions, CPM_Constants.CONSENT_DETAILS_BODY_KEYS, process);
            consents = (List<Object>) details.get(CPM_Constants.CONSENTS);
            for (Object consObj : consents){
                Map<String,Object> consMap = (Map<String,Object>) consObj;
                checkParameters(consMap,paramExceptions, CPM_Constants.CONSENT_BODY_KEYS, process);
            }
        }
        System.debug('missingParameters: '+missingParameters);
        return missingParameters;
    }
    
    private static void checkParameters(Map<String, Object> m, Set<String> paramExceptions, Set<String> keys, String process){
        Set<String> foundKeys = new Set<String>();
        for (String key :m.keyset()){
            foundKeys.add(key);
            Object value = m.get(key);
            
            if (paramExceptions.contains(key)){
                continue;
            } else if (value instanceOf List<Object>){
                continue;
            } else if (value instanceOf Map<Object,Object>){
                continue;
            } else {
                missingParameters += (value != null && value != CPM_Constants.EMPTYSTRING)? CPM_Constants.EMPTYSTRING : 
                (missingParameters != CPM_Constants.EMPTYSTRING)? CPM_Constants.COMMA+key : key;
            }
        }
        for (String key :keys){
            if (!foundKeys.contains(key)){
                missingParameters += key+' keyName,';
            }
        }
    }
    
    @testVisible
    private static CPM_JSONWrappers.CPM_Status validateRequestPicklistValues(string requestBody,String process, String email, String guid)
    {
        String appName;
        CPM_JSONWrappers.CPM_ConsentDetails cDetails;
        string invalidValues= CPM_Constants.EMPTYSTRING;
        Schema.DescribeFieldResult fieldResult; 
        if(process == 'Create')
        {
            CPM_JSONWrappers.CPM_CreateUserAndConsentRequest reqWrapper = CPM_UserConsentAPI.createConsentRequestParse(requestBody);
            
            if (!validateEmail(reqWrapper.email)){
                invalidValues= invalidValues+CPM_Constants.EMAIL+CPM_Constants.COMMA;
            }
            // Values are already verified as not null in CheckParameters method
            fieldResult = Question_Detail__c.Country__c.getDescribe();
            if(!checkPicklistValues(fieldResult,reqWrapper.country))
                invalidValues= invalidValues+CPM_Constants.COUNTRY+CPM_Constants.COMMA;
                
            fieldResult = Question_Detail__c.Language__c.getDescribe();
            if(!checkPicklistValues(fieldResult,reqWrapper.language))
                invalidValues= invalidValues+CPM_Constants.LANGUAGE+CPM_Constants.COMMA;
                
            appName = reqWrapper.appName;
            cDetails=  reqWrapper.consentDetails;
        }
        else if (process == 'updateConsent')
        {
            CPM_JSONWrappers.CPM_UpdateUserConsentRequest reqWrapper = CPM_UserConsentAPI.updateConsentRequestParse(requestBody);
            if (!String.isBlank(email)){
                if (!validateEmail(email)){
                    invalidValues= invalidValues+CPM_Constants.EMAIL+CPM_Constants.COMMA;
                }
            } else {
                // NEED A CLEAR FORMAT FOR GUID TO VALIDATE IT
                //if (!validateEmail(guid)){
                  //  invalidValues= invalidValues+CPM_Constants.GUID+CPM_Constants.COMMA;
                //}
            }
            reqWrapper.email = email;
            reqWrapper.guid = guid;
                
            appName = reqWrapper.appName;
            cDetails=  reqWrapper.consentDetails;
        } else if (process == 'updateUser'){
            // updateUser validations
        }
        if(appName!=null )
        {
            
            Boolean foundApp = false;
            for (Application__c app :[select ID, Name from Application__c]){
                if (appName == app.Name){
                    foundApp = true;
                    break;
                }
            }
            if (!foundApp){
                invalidValues= invalidValues+CPM_Constants.APPNAME+CPM_Constants.COMMA;
            }
        }
        			//Check that consents exist
        if(cDetails!=null && cDetails.consents != null && cDetails.consents.size()>0)
        {
            Map<string,string> reqAppQuestiontoQuestionMap= new  Map<string,string>();
            // Check the ConsentType value
            for(CPM_JSONWrappers.CPM_Consent cons : cDetails.consents)
            {
                fieldResult = Question__c.Consent_Type__c.getDescribe();
                    if(!checkPicklistValues(fieldResult,cons.consentType))
                        invalidValues= invalidValues+CPM_Constants.CONSENTTYPE+CPM_Constants.COMMA;
                
                if(cons.appQuestionID != null && cons.prefCenterQuestionId !=null)
                {
                    reqAppQuestiontoQuestionMap.put(cons.appQuestionID,cons.prefCenterQuestionId);
                }
            }
            if(reqAppQuestiontoQuestionMap.keySet().size()>0)
            {
                List<Question_Application_Detail__c> appQuests= [SELECT ID,name,Question__r.name 
                                                                 FROM Question_Application_Detail__c
                                                                 WHERE Name in :reqAppQuestiontoQuestionMap.keySet()];
                Map<string,string> appQuestiontoQuestionMap= new  Map<string,string>();
                if(appQuests!=null && appQuests.size()>0)
                {
                    for(Question_Application_Detail__c app : appQuests)
                    {
                        appQuestiontoQuestionMap.put(app.Name, app.Question__r.name);
                    }
                    for(string appKey : reqAppQuestiontoQuestionMap.keySet())
                    {
                        if(appQuestiontoQuestionMap.containsKey(appKey))
                        {
                            if(!(reqAppQuestiontoQuestionMap.get(appKey)==appQuestiontoQuestionMap.get(appKey)))
                            {
                                invalidValues= invalidValues+CPM_Constants.PREFQUESTID+reqAppQuestiontoQuestionMap.get(appKey)+CPM_Constants.COMMA;
                            }
                        }
                        else
                        {
                            invalidValues= invalidValues+CPM_Constants.APPQUESTID+appKey+CPM_Constants.COMMA;
                        }
                    }
                    
                }
                else
                {
                    invalidValues= invalidValues+CPM_Constants.APPQUESTID+reqAppQuestiontoQuestionMap.keySet()+CPM_Constants.COMMA;
                }
                
            }
        }
        
        if(invalidValues != CPM_Constants.EMPTYSTRING )
        {
            invalidValues= invalidValues.removeEnd(CPM_Constants.COMMA);
            return CPM_Utilities.setCPMStatus(CPM_Constants.STATUS_400,CPM_Constants.POST, CPM_Constants.ERROR,  CPM_Constants.ERROR_INVALID_Values+invalidValues);
        }
        else
            return null;
    }
    private static Boolean checkPicklistValues(Schema.DescribeFieldResult fieldResult,string value)
    {
        Boolean isValueCorrect= false;
        List<Schema.PicklistEntry> picklistValues= fieldResult.getPicklistValues();
        for(Schema.PicklistEntry pE : picklistValues){
            if(pE.getValue() == value)
            {
                isValueCorrect=true;
                break;
            }                
        }
        return isValueCorrect;
    }
}