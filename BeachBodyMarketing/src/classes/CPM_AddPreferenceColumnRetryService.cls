public class CPM_AddPreferenceColumnRetryService implements Schedulable {
    private List<String> retryPrefColumns;
    private List<String> retryPrefAuditColumns;
    public CPM_AddPreferenceColumnRetryService(List<String> retryPrefColumns,LIST<String> retryPrefAuditColumns) {
        this.retryPrefColumns = retryPrefColumns;
        this.retryPrefAuditColumns=retryPrefAuditColumns;
    }
    
    public void execute(SchedulableContext sc) {
     CPM_Util.createAllColumnsCallout(retryPrefColumns,retryPrefAuditColumns,false);
    }
    
}