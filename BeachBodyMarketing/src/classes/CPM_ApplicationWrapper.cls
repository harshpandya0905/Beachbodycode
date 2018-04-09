public class CPM_ApplicationWrapper {
    private Boolean isCoach {get; set;}
    public Boolean corpConsentBool {get; set;}
    public Boolean coachConsentBool {get; set;}
    public Boolean healthConsentBool {get; set;}
    public String appName {get; set;}
    private static List<CPM_JSONWrappers.CPM_Consent> consents{get; set;}
	public Set<String> businessUnits {get; set;}
    public Set<String> appQuestionIds {get; set;}
    public Map<String,List<String>> appQuestionMap {get; set;}
    public Map<String,CPM_JSONWrappers.CPM_Consent> appQuestionConsentMap {get; set;}
    public Map<String,CPM_JSONWrappers.CPM_Consent> QuestionConsentMap {get; set;}
    public Map<String,List<Question__c>> consentQuestionListMap {get; set;}
    public String noAbuErrorMessage;
    public String noQadErrorMessage;
    
    public CPM_ApplicationWrapper(List<CPM_JSONWrappers.CPM_Consent> reqConsents, String appName, Boolean isCoach){
        //Main Maps used for generating JSON Bodies
        this.consentQuestionListMap = new Map<String, List<Question__c>>();
        this.questionConsentMap = new Map<String, CPM_JSONWrappers.CPM_Consent>();
        //System.debug('appName is '+appName);
        this.businessUnits = CPM_Utilities.getAppBusinessUnitString(appName);
        this.isCoach = isCoach;
        this.appName = appName;
        consents = reqConsents;
        getConsentMaps();
    }
    
    
    
    private void getConsentMaps(){
        this.appQuestionIds = new Set<String>();
        this.appQuestionConsentMap = new Map<String,CPM_JSONWrappers.CPM_Consent>();
        
        //Add request appQuestionIds from Consents to Set and ConsentMap
        for (CPM_JSONWrappers.CPM_Consent c : consents){
            System.debug('consent: '+c);
            this.appQuestionIds.add(c.appQuestionId);
            
            this.appQuestionConsentMap.put(c.appQuestionId,c);
            if (c.consentType == 'corpConsent')
                corpConsentBool = c.consent;
            else if (c.consentType == 'coachConsent')
                coachConsentBool = c.consent;
            else if (c.consenttype == 'healthConsent')
                healthConsentBool = c.consent;
        }
        System.debug('appQuestionConsentMap: '+appQuestionConsentMap);
        // questionAppDetailQuery gathers all appQuestions, Related AppQuestions, prefQuestions and pref BannerQuestions
        for (Question_Application_Detail__c qad : CPM_Utilities.questionAppDetailQuery(appQuestionIds)){
            System.debug('thisQad: '+qad.Question__r.Preference_Column_Name__c);     
            //Add the Question to the main Maps, and to its own List in the consentQuestionListMap
            if (qad.Name == qad.Final_App_Question__c){
                
                Question__c q = CPM_Utilities.createQuestionObj(qad);
                this.consentQuestionListMap.put(qad.Question__r.Id, new List<Question__c>{q});
                System.debug('MainAppQ: '+q);
                this.questionConsentMap.put(qad.Question__r.Id, appQuestionConsentMap.get(qad.Name));  
            }
            // Manage Related AppQuestions (BOD/TBB scenario to ensure TBB Subscription Consent Question is included with BOD Consent)
            if (qad.Name != qad.Final_App_Question__c){
                // Add the RelatedAppQuestion prefCtrQuestion to the main Maps (to find Preference or UserCoach questions) 
                
                Question__c q = CPM_Utilities.createQuestionObj(qad);
                this.consentQuestionListMap.put(qad.Question__r.Id, new List<Question__c>{q});
                System.debug('reltAppQ: '+q);
                // Add a Consent Object for the Related App Question with its FinalAppQuestion's Consent parameter
                this.questionConsentMap.put(
                    qad.Question__r.Id, CPM_Utilities.createConsentObj(this.appQuestionConsentMap.get(qad.Final_App_Question__c).consent, 
                                                                         qad.Name, qad.Question__r.Name));
            // Manage Banner Questions
            } else if (qad.Question__r.Parent_Consent__c != null && !consentQuestionListMap.keyset().contains(qad.Question__r.Parent_Consent__c)){
                // Parent_Consent Banner Question is added to the subscription question's List
                Question__c q = CPM_Utilities.createParentQuestionObj(qad);
                System.debug('BanrAppQ: '+q);
                consentQuestionListMap.get(qad.Question__r.Id).add(q);
            }
        }
        Map<String,List<Question__c>> prefQuestionListMap = CPM_Utilities.preferenceQuestionQuery(consentQuestionListMap.keyset(), isCoach);
        // Get Preference Questions where available
        System.debug(consentQuestionListMap.keyset());
        System.debug(prefQuestionListMap.keyset());
        for (Id qId : consentQuestionListMap.keyset()){
            if (prefQuestionListMap.get(qId) != null)
            	consentQuestionListMap.get(qId).addAll(prefQuestionListMap.get(qId));
        }
        System.debug('consentQuestionListMap: '+consentQuestionListMap);
    }
}