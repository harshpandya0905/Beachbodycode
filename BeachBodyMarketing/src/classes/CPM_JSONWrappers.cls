global class CPM_JSONWrappers {
    
    global class CPM_Consent{
		public String consentType {get; set;}
		public Boolean consent {get; set;}
        public String appQuestionId {get; set;}
        public String prefCenterQuestionId {get; set;}
	}
    
    global class CPM_ConsentDetails{
        public datetime consentDate {get {return consentDate;}
     		set { consentDate = value;  }
		}
		public datetime CASLExpirationDate {get;set;}
    	public List<CPM_Consent> consents {get; set;}
    }
	
    global class CPM_Status{
		public Boolean success {get; set;}
		public Integer statusCode {get; set;}
		public String statusMessage {get; set;}
	}
    
    global class CPM_CreateUserAndConsentRequest{
		//public CPM_CustomerData customerData {get; set;}
		public String guid {get; set;}
		public String email {get; set;}
		//public String ebsCustomerId {get; set;}
		public String firstName {get; set;}
		public String lastName {get; set;}
		public String country {get; set;}
        public String language {get; set;}
    	public Boolean isCoach {get; set;}
		public String appName {get; set;}
        public CPM_ConsentDetails consentDetails {get; set;}
	}
    
    global class CPM_UpdateUserRequest{
        public String updatedEmail {get; set;}
		public String firstName {get; set;}
		public String lastName {get; set;}
		public String country {get; set;}
        public String language {get; set;}
    	public Boolean isCoach {get; set;}        
	}
	
	global class CPM_UpdateUserConsentRequest{
        public String appName {get; set;}
		public String guid {get; set;}
        public String email {get; set;}
        public String country {get; set;}
        public DateTime originalCreatedDate {get; set;}
        public String originalCreatedBy {get; set;}
        public String currentBusinessUnits {get; set;}
        public Boolean isCoach {get; set;}
        
		public CPM_ConsentDetails consentDetails {get; set;}
	}
    
    global class CPM_Response{
		public CPM_Status responseStatus {get; set;}
    }
    
    /*global class CPM_GetUserConsentResponse{
		public CPM_Status responseStatus {get; set;}
		public String GUID {get; set;}
		public String email {get; set;}
		public String appName {get; set;}
		public List<CPM_Consent> consents {get; set;}
	}
	
	global class CPM_GetConsentQuestionsResponse{
		public CPM_Status responseStatus {get; set;}
		public List<CPM_Question> questions {get; set;}
	}*/
}