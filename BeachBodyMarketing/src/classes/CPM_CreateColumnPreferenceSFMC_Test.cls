@isTest
private  class CPM_CreateColumnPreferenceSFMC_Test  {
    @isTest static void testInvocableMethod() { 
        List<Question__c> questionList= new List<Question__c>();
            Question__c question= new Question__c();
        	question.Preference_Column_Name__c='col1';
        questionList.add(question);
        CPM_CreateQuestionColumnInPreference.createColumnPreferenceSFMC(questionList);
    }

}