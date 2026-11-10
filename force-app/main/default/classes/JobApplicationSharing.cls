public without sharing class JobApplicationSharing {
   public static void syncHiringManagerShares(List<Job_Application__c> applications, Map<Id, Job_Application__c> oldApplications){
    if(applications == null || applications.isEmpty()){
        return;
    }

    Set<Id> changedApplicationIds = new Set<Id>();
    Set<Id> jobOpeningIds = new Set<Id>();

    //Identify new applications and applications whose Job Opening changed.
    for(Job_Application__c app : applications){
        Job_Application__c oldApp = oldApplications == null ? null : oldApplications.get(app.Id);

        Boolean jobChanged = oldApp == null || oldApp.Job_Opening__c != app.Job_Opening__c;
        if(jobChanged){
            changedApplicationIds.add(app.Id);

            if(app.Job_Opening__c != null){
                jobOpeningIds.add(app.Job_Opening__c);
            }
        }
    }
    if(changedApplicationIds.isEmpty()){
        return;
    }

    //Get the current Hiring Manager for each related Job Opening.
    Map<Id, Id> managerByJobId = new Map<Id, Id>();
    if(!jobOpeningIds.isEmpty()){
        for(Job_Opening__c job : [
            SELECT Id, Hiring_Manager__c
            FROM Job_Opening__c
            WHERE Id IN :jobOpeningIds
        ]) {
            managerByJobId.put(job.Id, job.Hiring_Manager__c);
        }
    }
   
   //Remove only shares created by this sharing information.
    List<Job_Application__Share> sharesToDelete = [
        SELECT Id
        FROM Job_Application__Share
        WHERE ParentId IN :changedApplicationIds
        AND RowCause = 'Recruitment_Access_Manager__c'
    ];

    if(!sharesToDelete.isEmpty()){
        Database.DeleteResult[] deleteResults = Database.delete(sharesToDelete, false);
        for(Database.DeleteResult result : deleteResults){
            System.debug(LoggingLevel.ERROR, 'Application share deletion success: ' + result.isSuccess());

            if(!result.isSuccess()){
                for(Database.Error err : result.getErrors()){
                    System.debug(LoggingLevel.ERROR, 'Application share deletion error: ' + err.getMessage());
                }
            }
        }
    }

    //Create access for the currently assigned Hiring Manager.
    List<Job_Application__Share> sharesToInsert = new List<Job_Application__Share>();

    for(Job_Application__c app : applications){
        if(!changedApplicationIds.contains(app.Id) || app.Job_Opening__c == null){
            continue;
        }

        Id managerId = managerByJobId.get(app.Job_Opening__c);
        if(managerId == null){
            continue;
        }

        Job_Application__Share newShare = new Job_Application__Share();
        newShare.ParentId = app.Id;
        newShare.UserOrGroupId = managerId;
        newShare.AccessLevel = 'Edit';
        newShare.RowCause = Schema.Job_Application__Share.RowCause.Recruitment_Access_Manager__c;
        sharesToInsert.add(newShare);
    }
    if(!sharesToInsert.isEmpty()){
        Database.insert(sharesToInsert, false);
    }
   }
}