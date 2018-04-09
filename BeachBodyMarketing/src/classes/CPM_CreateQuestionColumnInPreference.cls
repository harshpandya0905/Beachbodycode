public class CPM_CreateQuestionColumnInPreference {
    @InvocableMethod
    public static void createColumnPreferenceSFMC(List<Question__c> questionList) {
        List<String> columnNameList= new List<String>();
        for(Question__c question :questionList )
        {
            columnNameList.add(question.Preference_Column_Name__c);
        }
        system.debug('**columnname'+columnNameList);
        CPM_Util.createAllColumnsCallout(columnNameList,columnNameList,true);   
    }

}