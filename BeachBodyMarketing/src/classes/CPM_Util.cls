public class CPM_Util {
    @future (callout=true)
    public static void createAllColumnsCallout(List<string> prefColumnsList,List<string> prefAuditColumnsList,boolean canRetry)
    {
        system.debug('**columnname'+prefColumnsList);
        List<string> retryPrefColumns= new List<string>();
        List<string> retryPrefAuditColumns= new List<string>();
        string dataExtKey= '';
        string dataExtKey_PrefrenceAudit= '';
        Data_Extension_Details__mdt[] deDetails=[SELECT DataExtensionExternalKey__c,DataExtension__c  FROM Data_Extension_Details__mdt 
                                                 WHERE DataExtension__c = :CPM_Constants.PREFERENCE_DE_NAME OR
                                                 DataExtension__c = :CPM_Constants.PREFERENCE_AUDIT_DE_NAME];
        if(deDetails!= null && deDetails.size()>0)
        {
            for(Data_Extension_Details__mdt deDetail :deDetails)
            { 
            if( deDetail.DataExtension__c == CPM_Constants.PREFERENCE_DE_NAME){
                system.debug('inside pref');

                dataExtKey=deDetail.DataExtensionExternalKey__c;
                 system.debug(dataExtKey);
            }
            if(deDetail.DataExtension__c == CPM_Constants.PREFERENCE_AUDIT_DE_NAME){
                system.debug('inside audit');
                dataExtKey_PrefrenceAudit=deDetail.DataExtensionExternalKey__c;
                system.debug(dataExtKey_PrefrenceAudit);
            }
            }
        }
        for(string preferenceColumnName :prefColumnsList )
        {
            
            try
            {
                exacttargetComWsdlPartnerapi.Soap soapRequest = new exacttargetComWsdlPartnerapi.Soap();
                
                exacttargetComWsdlPartnerapi.Options updateOptionList = createSaveOptions('*','UpdateOnly') ;
                
                exacttargetComWsdlPartnerapi.APIObject[] ObjectsList= createObjectsList( preferenceColumnName, dataExtKey);
                
                system.debug('SOAP: '+ObjectsList);        
                exacttargetComWsdlPartnerapi.UpdateResponseDE_element response = soapRequest.UpdateDataExtension_x(updateOptionList,ObjectsList);
                system.debug('SOAP: '+response);
                if(response != null && response.Results != null && response.Results.size()>0)
                {
                    if(response.Results[0].StatusCode=='Error')
                    {
                        logError('CPM_Util.createColumnPreferenceCallout-PreferenceColumn',response.Results[0].StatusMessage,preferenceColumnName) ; 
                    }
                    system.debug(response.Results[0].StatusMessage);
                }
                else
                {
                    logError('CPM_Util.createColumnPreferenceCallout-PreferenceColumn','Unknown exception',preferenceColumnName) ; 
                }
                
            }
            catch(System.CalloutException ex)
            {
                system.debug(ex.getMessage());
                if(canRetry)
                {
                    retryPrefColumns.add(preferenceColumnName);
                    
                }
                else
                {
                    logError('CPM_Util.createColumnPreferenceCallout-PreferenceColumn',ex.getMessage(),preferenceColumnName) ; 
                }
            }
            catch(Exception ex)
            {
                logError('CPM_Util.createColumnPreferenceCallout-PreferenceColumn',ex.getMessage(),preferenceColumnName) ; 
            }
            
        }
        for(string preferenceColumnName :prefAuditColumnsList )
        {
            system.debug('**inside pref audit columnname'+dataExtKey_PrefrenceAudit);
            try
            {
                exacttargetComWsdlPartnerapi.Soap soapRequest = new exacttargetComWsdlPartnerapi.Soap();
                
                exacttargetComWsdlPartnerapi.Options updateOptionList = createSaveOptions('*','UpdateOnly') ;
                
                exacttargetComWsdlPartnerapi.APIObject[] ObjectsList= createObjectsList( preferenceColumnName, dataExtKey_PrefrenceAudit);
                
                system.debug('SOAP: '+ObjectsList);        
                exacttargetComWsdlPartnerapi.UpdateResponseDE_element response = soapRequest.UpdateDataExtension_x(updateOptionList,ObjectsList);
                system.debug('SOAP: '+response);
                if(response != null && response.Results != null && response.Results.size()>0)
                {
                    if(response.Results[0].StatusCode=='Error')
                    {
                        logError('CPM_Util.createColumnPreferenceCallout-PreferenceAuditColumn',response.Results[0].StatusMessage,preferenceColumnName) ; 
                    }
                    system.debug(response.Results[0].StatusMessage);
                }
                else
                {
                    logError('CPM_Util.createColumnPreferenceCallout-PreferenceAuditColumn','Unknown exception',preferenceColumnName) ; 
                }
                
            }
            catch(System.CalloutException ex)
            {
                system.debug(ex.getMessage());
                if(canRetry)
                {
                    retryPrefAuditColumns.add(preferenceColumnName);
                    
                }
                else
                {
                    logError('CPM_Util.createColumnPreferenceCallout-PreferenceAuditColumn',ex.getMessage(),preferenceColumnName) ; 
                }
            }
            catch(Exception ex)
            {
                logError('CPM_Util.createColumnPreferenceCallout-PreferenceAuditColumn',ex.getMessage(),preferenceColumnName) ; 
            }
            
        }
        if(retryPrefColumns.size()>0 || retryPrefAuditColumns.size()>0)
        {
            // Schedule the retry after 2 mins
            DateTime now = System.now();
            DateTime dtime = now.addMinutes(2);
            String schedule = dtime.second() + ' ' + dtime.minute() + ' ' + dtime.hour() + ' ' + dtime.day() + ' ' + dtime.month() + ' ? ' + dtime.year();
            CPM_AddPreferenceColumnRetryService service = new CPM_AddPreferenceColumnRetryService(retryPrefColumns,retryPrefAuditColumns);
            System.schedule('Conversion Retry - ' + dtime.time(), schedule, service);
        }
    }
    
    private static void logError(string methodName,string errMessage,string errorField)
    {
        SFMCCalloutErrorLog__c err= new SFMCCalloutErrorLog__c ();
        err.MethodName__c =methodName;
        err.ErrorMessage__c=errMessage;
        err.ErrorField__c =errorField;
        insert err;
    }
    private static exacttargetComWsdlPartnerapi.APIObject[] createObjectsList(string preferenceColumnName,string dataExtKey)
    {
        exacttargetComWsdlPartnerapi.APIObject[] ObjectsList= new exacttargetComWsdlPartnerapi.APIObject[]{};
            exacttargetComWsdlPartnerapi.DataExtension dataExt= new exacttargetComWsdlPartnerapi.DataExtension();
        dataExt.CustomerKey=dataExtKey;
        dataExt.Fields= new exacttargetComWsdlPartnerapi.Fields_element();
        
        dataExt.Fields.Field=new exacttargetComWsdlPartnerapi.DataExtensionField[]{};
            exacttargetComWsdlPartnerapi.DataExtensionField field1= new exacttargetComWsdlPartnerapi.DataExtensionField();
        field1.IsPrimaryKey=false;
        field1.Name=preferenceColumnName;
        field1.FieldType='Boolean';
        dataExt.Fields.Field.add(field1);
        ObjectsList.add(dataExt);
        
        
        system.debug('SOAP: '+ObjectsList); 
        
        return ObjectsList;
    }
    private static exacttargetComWsdlPartnerapi.Options createSaveOptions(string propertyName,string saveAction)
    {
        exacttargetComWsdlPartnerapi.Options saveOptionList = new exacttargetComWsdlPartnerapi.Options() ;
        exacttargetComWsdlPartnerapi.SaveOption[] SaveOptionsList= new exacttargetComWsdlPartnerapi.SaveOption[]{};
            exacttargetComWsdlPartnerapi.SaveOption option1= new exacttargetComWsdlPartnerapi.SaveOption();
        option1.PropertyName=propertyName;
        option1.SaveAction=saveAction;
        SaveOptionsList.add(option1);
        saveOptionList.SaveOptions=new exacttargetComWsdlPartnerapi.SaveOptions_element();
        saveOptionList.SaveOptions.SaveOption=SaveOptionsList;
        
        return saveOptionList;
        
    }
    
}