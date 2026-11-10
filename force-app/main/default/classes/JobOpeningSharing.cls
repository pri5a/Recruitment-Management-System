public without sharing class JobOpeningSharing {
    public static void syncHiringManagerShares(List<Job_Opening__c> newJobs, Map<Id, Job_Opening__c> oldJobs){
        if(newJobs == null || newJobs.isEmpty()){
            return;
        }

        Set<Id> changedJobIds = new Set<Id>();
        Map<Id, Id> newManagers = new Map<Id, Id>();

        for(Job_Opening__c job : newJobs){
            Job_Opening__c oldJob = oldJobs == null ? null : oldJobs.get(job.Id);

            Boolean assignmentChanged = oldJobs == null || oldJob.Hiring_Manager__c != job.Hiring_Manager__c;
            if(!assignmentChanged){
                continue;
            }
            changedJobIds.add(job.Id);

            if(job.Hiring_Manager__c != null){
                newManagers.put(job.Id, job.Hiring_Manager__c);
            }
        }
        if(changedJobIds.isEmpty()){
            return;
        }

        //Remove only shares created for Recruitment Access Manager
        List<Job_Opening__Share> sharesToDelete = [
            SELECT Id
            FROM Job_Opening__Share
            WHERE ParentId IN :changedJobIds
            AND RowCause = 'Recruitment_Access_Manager__c'
        ];

        if(!sharesToDelete.isEmpty()){
            Database.delete(sharesToDelete, false);
        }

        //Create access for the currently assigned Hiring Manager.
        List<Job_Opening__Share> sharesToInsert = new List<Job_Opening__Share>();

        for(Id jobId : newManagers.keySet()){
            Job_Opening__Share newShare = new Job_Opening__Share();
            newShare.ParentId = jobId;
            newShare.UserOrGroupId = newManagers.get(jobId);
            newShare.AccessLevel = 'Edit';
            newShare.RowCause = Schema.Job_Opening__Share.RowCause.Recruitment_Access_Manager__c;
            sharesToInsert.add(newShare);
        }
        if(!sharesToInsert.isEmpty()){
           // Database.insert(sharesToInsert, false);
           Database.SaveResult[] results = Database.insert(sharesToInsert, false);

           for (Database.SaveResult result : results) {
                if (!result.isSuccess()) {
                    for (Database.Error err : result.getErrors()) {
                        System.debug(LoggingLevel.ERROR,
                            'Job Opening share failed: ' + err.getMessage());
                    }
                }
            }
           }
    }
}