trigger JobApplicationTrigger on Job_Application__c (after insert, after update, after delete)
{
    //Sync Hiring Manager access for inserted or updated applications.
    if(Trigger.isInsert || Trigger.isUpdate) {
        JobApplicationSharing.syncHiringManagerShares(Trigger.new, Trigger.isUpdate ? Trigger.oldMap : null);
    }
    Set<Id> candidateIds = new Set<Id>();    

    //Collect candidate IDs from inserted or updated applications.
    if(Trigger.isInsert || Trigger.isUpdate) {
        for(Job_Application__c app : Trigger.new){
            if(app.Candidate__c != null) {
                candidateIds.add(app.Candidate__c);
            }

            if(Trigger.isUpdate){
                Job_Application__c oldApp = Trigger.oldMap.get(app.Id);

                if(oldApp.Candidate__c != null){
                    candidateIds.add(oldApp.Candidate__c);
                }
            }
        }
    }

    //Collect candidate IDs from deleted applications
    if(Trigger.isDelete){
        for(Job_Application__c app : Trigger.old){
            if(app.Candidate__c != null){
                candidateIds.add(app.Candidate__c);
            }
        }
    }

    if(!candidateIds.isEmpty()){
        CandidateSharing.syncCandidateShares(candidateIds);
    }
}
