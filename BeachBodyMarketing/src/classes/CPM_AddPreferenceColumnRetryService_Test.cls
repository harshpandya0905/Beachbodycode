@isTest
private class CPM_AddPreferenceColumnRetryService_Test {
    
    @isTest 
        static void testInvocableMethod() { 
        List<String> retryPrefColumns = new List<String>();
        List<String> retryPrefAuditColumns = new List<String>();
        Test.StartTest();
        
        String CRON_EXP = '0 0 * * * ?';           
        CPM_AddPreferenceColumnRetryService retryService= new CPM_AddPreferenceColumnRetryService(retryPrefColumns,retryPrefAuditColumns);       
        String jobid = system.schedule('varam', CRON_EXP, retryService);  
        
        Test.StopTest();  
        
        
    }

}