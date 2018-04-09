public class CPM_MarketingCloudCallouts {
	
    public static String getInsertMasterJsonBody(CPM_JSONWrappers.CPM_CreateUserAndConsentRequest reqWrapper, CPM_ApplicationWrapper appWrap){
        String businessUnits = CPM_Constants.EMPTYSTRING;
		for (String bu : appWrap.businessUnits){
			businessUnits += (businessUnits != CPM_Constants.EMPTYSTRING)? CPM_Constants.COMMA+bu : bu;
		}
        // generate MasterBody
        JSONGenerator genMaster = JSON.createGenerator(true);//CPM_Utilities.getJsonHeader(reqWrapper.email, reqWrapper.guid);
        
        //System.debug(genMaster.getAsString());
        genMaster.writeStartObject();// {
        genMaster.writeFieldName(CPM_Constants.KEYS);// keys:
        	genMaster.writeStartObject();      // {  
            if (!String.isBlank(reqWrapper.email)){
                genMaster.writeStringField(CPM_Constants.SUBSCRIBERKEY, reqWrapper.email);  //SubscriberKey:Email
            } else 
                genMaster.writeStringField(CPM_Constants.SUBSCRIBERKEY, reqWrapper.guid);  
        		
            genMaster.writeEndObject();
        genMaster.writeFieldName(CPM_Constants.VALUES);
            genMaster.writeStartObject();  
				
                genMaster.writeStringField(CPM_Constants.GUID, reqWrapper.guid);
                genMaster.writeStringField(CPM_Constants.FIRST_NAME, reqWrapper.firstName);
                genMaster.writeStringField(CPM_Constants.LAST_NAME, reqWrapper.lastName);
                genMaster.writeStringField(CPM_Constants.COUNTRY, reqWrapper.country);
                genMaster.writeStringField(CPM_Constants.LANGUAGE, reqWrapper.language);
                genMaster.writeBooleanField(CPM_Constants.IS_COACH, reqWrapper.isCoach);
        		
                if (!String.isBlank(businessUnits)){
                    genMaster.writeStringField(CPM_Constants.BUSINESS_UNITS, businessUnits);                                     
                } else {
                    return appWrap.noAbuErrorMessage;
                }
                      
            genMaster.writeEndObject();
        genMaster.writeEndObject();
        System.debug('MC json string: '+genMaster.getAsString());
        return '['+genMaster.getAsString()+']';
    }
    
    public static String getUpdateMasterJsonBody(String businessUnits){
        
        // generate MasterBody
        JSONGenerator genMaster = JSON.createGenerator(true);
        
        genMaster.writeStartObject();// {
        genMaster.writeFieldName(CPM_Constants.VALUES);
        genMaster.writeStartObject();  
		genMaster.writeStringField(CPM_Constants.BUSINESS_UNITS, businessUnits); 
        genMaster.writeEndObject();
        genMaster.writeEndObject();
        System.debug('MC json string: '+genMaster.getAsString());
        return genMaster.getAsString();
    }
    
    public static CPM_UserConsentAPI.reqBodyWrapper getPrefsJsonBodies(Map<String,Object> dateUserMap, String email, String guid, CPM_ApplicationWrapper appWrap, String Country){
        CPM_UserConsentAPI.reqBodyWrapper reqBodyWrap = new CPM_UserConsentAPI.reqBodyWrapper();
        Boolean isUpdate = (dateUserMap.get(CPM_Constants.ORIGINAL_CREATED_DATE) != null);
        String keyValue = (string.isBlank(email))? guid : email;
        Timezone tz = Timezone.getTimeZone('America/El_Salvador');
        DateTime currentDate = system.now();
        integer offsetToUserTimeZone =tz.getOffset(currentDate);
        currentDate =currentDate.addHours(-(offsetToUserTimeZone / (1000 * 60 *60))) ;
        
        JSONGenerator genPref = JSON.createGenerator(true); 
        genPref.writeStartObject();
       	genPref.writeFieldName(CPM_Constants.KEYS);
        genPref.writeStartObject(); 
        genPref.writeStringField(CPM_Constants.SUBSCRIBERKEY, keyValue);
            
        genPref.writeEndObject();
        	
        JSONGenerator genAudit = JSON.createGenerator(true);
        genAudit.writeStartObject();
       	genAudit.writeFieldName(CPM_Constants.KEYS);
      	genAudit.writeStartObject();      
        genAudit.writeStringField(CPM_Constants.SUBSCRIBERKEY, keyValue);// 4/3 update SubscriberKey assignment to ensure email or guid is available
        //genAudit.writeDateTimeField(CPM_Constants.RECORD_CREATED_DATE, currentDate);
        genAudit.writeDateTimeField(CPM_Constants.CREATED_DATE,(DateTime) dateUserMap.get(CPM_Constants.CONSENT_DATE));
        genAudit.writeEndObject();
                        
        genPref.writeFieldName(CPM_Constants.VALUES);
        genAudit.writeFieldName(CPM_Constants.VALUES);
        genPref.writeStartObject();
        genAudit.writeStartObject();
        	system.debug('input date***'+dateUserMap.get(CPM_Constants.CONSENT_DATE));
        genPref.writeStringField(CPM_Constants.SOURCE_OF_CHANGE, appWrap.appName);
        genAudit.writeStringField(CPM_Constants.SOURCE_OF_CHANGE, appWrap.appName);
        
        genPref.writeStringField(CPM_Constants.LAST_MODIFIED_BY,(String) dateUserMap.get(CPM_Constants.CREATED_BY));
        genPref.writeDateTimeField(CPM_Constants.LAST_MODIFIED_DATE,(DateTime) dateUserMap.get(CPM_Constants.CONSENT_DATE));
      	genAudit.writeStringField(CPM_Constants.CREATED_BY,(String) dateUserMap.get(CPM_Constants.CREATED_BY));
        
        genPref.writeStringField(CPM_Constants.CREATED_BY,(String) dateUserMap.get(CPM_Constants.CREATED_BY));
        genAudit.writeStringField(CPM_Constants.RECORD_CREATED_BY,(String) UserInfo.getName());
        
        genPref.writeDateTimeField(CPM_Constants.CREATED_DATE,(DateTime) dateUserMap.get(CPM_Constants.CONSENT_DATE));
        //genAudit.writeDateTimeField(CPM_Constants.CREATED_DATE,(DateTime) dateUserMap.get(CPM_Constants.CONSENT_DATE));
        genAudit.writeDateTimeField(CPM_Constants.RECORD_CREATED_DATE, currentDate);
        	
        for (Id prefQId : appWrap.consentQuestionListMap.keyset()){
            //System.debug('prefColName: '+appWrap.questionConsentMap.get(prefQId));
            Boolean consent = appWrap.questionConsentMap.get(prefQId).consent;
               
                
            String appQuestionId = appWrap.questionConsentMap.get(prefQId).appQuestionId;
            DateTime CASLExpirationDate = (DateTime) dateUserMap.get(CPM_Constants.CASL_EXPIRATION_DATE);
            //System.debug('CASLExpirationDate: '+CASLExpirationDate);
            for (Question__c q : appWrap.consentQuestionListMap.get(prefQId)){
                // All questions (Consent, Related Bys(Banners, User Coach, etc.. and Preferences are handled here)
                String prefColumnName = q.preference_Column_Name__c;
                System.debug(prefColumnName+' Start Loop');
                genPref.writeBooleanField(q.Preference_Column_Name__c,consent);
                genAudit.writeBooleanField(q.Preference_Column_Name__c,consent);
                    
                System.debug(prefColumnName+': prefQId: '+prefQId+'; '+'q.Id: '+q.Id);
                   
                // Additional fields related to the prefCenterQuestion handled here
                if (q.Id == prefQId && q.Category__c == CPM_Constants.CONSENT){
                    //System.debug('genPref here: '+genPref.getAsString());
                    System.debug('q.Consent_Type__c: '+q.Consent_Type__c+'; Constant is: '+CPM_Constants.COACHCONSENT);
                    if (q.Consent_Type__c == CPM_Constants.CORPCONSENT){
                        System.debug('gets past corpConsent check');
                        genPref.writeStringField(CPM_Constants.CORPCONSENT_APPQUESTIONID,appQuestionID);
                        genAudit.writeStringField(CPM_Constants.CORPCONSENT_APPQUESTIONID,appQuestionID);
                        if ((isUpdate && CASLExpirationDate != null) || (Country == CPM_Constants.CA)){
                            System.debug(prefColumnName+' gets past CALExpirationDate check');
                            genPref.writeDateTimeField(CPM_Constants.CASL_EXPIRATION_DATE,CASLExpirationDate);
                            genAudit.writeDateTimeField(CPM_Constants.CASL_EXPIRATION_DATE,CASLExpirationDate);
                        }
                    } else if (q.Consent_Type__c == CPM_Constants.COACHCONSENT){
                        genPref.writeStringField(CPM_Constants.COACHCONSENT_APPQUESTIONID,appQuestionID);
                        genAudit.writeStringField(CPM_Constants.COACHCONSENT_APPQUESTIONID,appQuestionID);
                    } else if (q.Consent_Type__c == CPM_Constants.HEALTHCONSENT){
                        genPref.writeStringField(CPM_Constants.HEALTHCONSENT_APPQUESTIONID,appQuestionID);
                        genAudit.writeStringField(CPM_Constants.HEALTHCONSENT_APPQUESTIONID,appQuestionID);
                    }
                }
            }
        }
        
        genPref.writeEndObject();
        genAudit.writeEndObject();
        genPref.writeEndObject();
        genAudit.writeEndObject();
        System.debug('genPref.getAsString(): '+genPref.getAsString());
        System.debug('genAudit.getAsString(): '+genAudit.getAsString());
        reqBodyWrap.prefsReqBody = CPM_Constants.OPENBRACE+genPref.getAsString()+CPM_Constants.CLOSEBRACE;
        reqBodyWrap.auditReqBody = CPM_Constants.OPENBRACE+genAudit.getAsString()+CPM_Constants.CLOSEBRACE;
        return reqBodyWrap;
    }
    
    public static CPM_UserConsentAPI.reqBodyWrapper getPrefsUpdateJsonBodies(Map<String,Object> dateUserMap, String email, String guid, CPM_ApplicationWrapper appWrap, String Country){
        CPM_UserConsentAPI.reqBodyWrapper reqBodyWrap = new CPM_UserConsentAPI.reqBodyWrapper();
        String keyValue = (string.isBlank(email))? guid : email; // 4/3 update SubscriberKey assignment to ensure email or guid is available
        String genPrefUpdate = '{ "'+CPM_Constants.VALUES+'" : {';
        String genAuditUpdate = '[{ "'+CPM_Constants.KEYS+'" : { "'+CPM_Constants.SUBSCRIBERKEY+'" : "'+keyValue+'","'+
            														//CPM_Constants.RECORD_CREATED_DATE+'":"'+System.now()+'"'+
            														CPM_Constants.CREATED_DATE+'" : "'+(DateTime) dateUserMap.get(CPM_Constants.CONSENT_DATE)+'"'+
            														'}, "'+CPM_Constants.VALUES+'" : {';
        
        genPrefUpdate += '"'+CPM_Constants.SOURCE_OF_CHANGE+'" : "'+appWrap.appName+'",';
        genAuditUpdate += '"'+CPM_Constants.SOURCE_OF_CHANGE+'" : "'+appWrap.appName+'",';
        
        genPrefUpdate += '"'+CPM_Constants.LAST_MODIFIED_BY+'" : "'+(String) dateUserMap.get(CPM_Constants.CREATED_BY)+'",';
        genPrefUpdate += '"'+CPM_Constants.LAST_MODIFIED_DATE+'" : "'+(DateTime) dateUserMap.get(CPM_Constants.CONSENT_DATE)+'",';
        
        genAuditUpdate += '"'+CPM_Constants.CREATED_BY+'" : "'+(String) dateUserMap.get(CPM_Constants.CREATED_BY)+'",';
        //genAuditUpdate += '"'+CPM_Constants.CREATED_DATE+'" : "'+(String) dateUserMap.get(CPM_Constants.CONSENT_DATE)+'",'; 
        genAuditUpdate += '"'+CPM_Constants.RECORD_CREATED_BY+'" : "'+UserInfo.getName()+'",';
        genAuditUpdate += '"'+CPM_Constants.RECORD_CREATED_DATE+'" : "'+System.now()+'",';
        
        for (Id prefQId : appWrap.consentQuestionListMap.keyset()){
            //System.debug('prefColName: '+appWrap.questionConsentMap.get(prefQId));
            Boolean consent = appWrap.questionConsentMap.get(prefQId).consent;
               
                
            String appQuestionId = appWrap.questionConsentMap.get(prefQId).appQuestionId;
            DateTime CASLExpirationDate = (DateTime) dateUserMap.get(CPM_Constants.CASL_EXPIRATION_DATE);
            //System.debug('CASLExpirationDate: '+CASLExpirationDate);
            for (Question__c q : appWrap.consentQuestionListMap.get(prefQId)){
                // All questions (Consent, Related Bys(Banners, User Coach, etc.. and Preferences are handled here)
                String prefColumnName = q.preference_Column_Name__c;
                System.debug(prefColumnName+' Start Loop');
                genPrefUpdate += '"'+q.Preference_Column_Name__c+'" : "'+consent+'",';
                genAuditUpdate += '"'+q.Preference_Column_Name__c+'" : "'+consent+'",';
                                         
                System.debug(prefColumnName+': prefQId: '+prefQId+'; '+'q.Id: '+q.Id);
                   
                // Additional fields related to the prefCenterQuestion handled here
                if (q.Id == prefQId && q.Category__c == CPM_Constants.CONSENT){
                    
                    System.debug('q.Consent_Type__c: '+q.Consent_Type__c+'; Constant is: '+CPM_Constants.COACHCONSENT);
                    if (q.Consent_Type__c == CPM_Constants.CORPCONSENT){
                        System.debug('gets past corpConsent check');
                        genPrefUpdate += '"'+CPM_Constants.CORPCONSENT_APPQUESTIONID+'" : "'+appQuestionID+'",';
                        genAuditUpdate += '"'+CPM_Constants.CORPCONSENT_APPQUESTIONID+'" : "'+appQuestionID+'",';
                        
                        if (CASLExpirationDate != null){
                            System.debug(prefColumnName+' gets past CALExpirationDate check');
                            
                            genPrefUpdate += '"'+CPM_Constants.CASL_EXPIRATION_DATE+'" : "'+CASLExpirationDate+'",';
                        	genAuditUpdate += '"'+CPM_Constants.CASL_EXPIRATION_DATE+'" : "'+CASLExpirationDate+'",'; 
                        }
                    } else if (q.Consent_Type__c == CPM_Constants.COACHCONSENT){
                        genPrefUpdate += '"'+CPM_Constants.COACHCONSENT_APPQUESTIONID+'" : "'+appQuestionID+'",';
                        genAuditUpdate += '"'+CPM_Constants.COACHCONSENT_APPQUESTIONID+'" : "'+appQuestionID+'",'; 
                            
                        
                    } else if (q.Consent_Type__c == CPM_Constants.HEALTHCONSENT){
                        genPrefUpdate += '"'+CPM_Constants.HEALTHCONSENT_APPQUESTIONID+'" : "'+appQuestionID+'",';
                        genAuditUpdate += '"'+CPM_Constants.HEALTHCONSENT_APPQUESTIONID+'" : "'+appQuestionID+'",'; 
                        
                    }
                }
            }
        }
        //System.debug('genPrefUpdate before removeEnd: '+genPrefUpdate); 
        genPrefUpdate = genPrefUpdate.removeEnd(',');
        genAuditUpdate = genAuditUpdate.removeEnd(',');
        //System.debug('genPrefUpdate after removeEnd: '+genPrefUpdate); 
        genPrefUpdate += '}}';
        genAuditUpdate += '}}]'; 
        System.debug('genPrefUpdate after Complete: '+genPrefUpdate);   
        System.debug('genAuditUpdate after Complete: '+genAuditUpdate);                
        reqBodyWrap.prefsReqBody = genPrefUpdate;
        reqBodyWrap.auditReqBody = genAuditUpdate;
        return reqBodyWrap;
    }
}