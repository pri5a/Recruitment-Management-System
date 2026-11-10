trigger JobOpeningTrigger on Job_Opening__c (after insert, after update) {
   //Synchronize Hiring Manager access to Job Openings.
   JobOpeningSharing.syncHiringManagerShares(Trigger.new, Trigger.isUpdate ? Trigger.oldMap : null);

   if(Trigger.isUpdate){
      System.debug(LoggingLevel.ERROR, 'DEBUG: JobOpeningTrigger after update executed.');
      Set<Id> changedJobIds = new Set<Id>();

      for(Job_Opening__c job : Trigger.new){
         Job_Opening__c oldJob = Trigger.oldMap.get(job.Id);

         if(oldJob.Hiring_Manager__c != job.Hiring_Manager__c){
            changedJobIds.add(job.Id);
         }
      }
      System.debug(LoggingLevel.ERROR, 'DEBUG: Changed Job IDs: ' + changedJobIds);
      if(!changedJobIds.isEmpty()){
         Set<Id> candidateIds = new Set<Id>();
         List<Job_Application__c> relatedApplications = new List<Job_Application__c>();

         //Find applications and candidates related to changed Job Openings.
         for(Job_Application__c app : [
            SELECT Id, Job_Opening__c, Candidate__c
            FROM Job_Application__c
            WHERE Job_Opening__c IN :changedJobIds
         ]) {
            relatedApplications.add(app);

            if(app.Candidate__c != null){
               candidateIds.add(app.Candidate__c);
            }
         }
              System.debug(LoggingLevel.ERROR, 'DEBUG: Related Applications: ' + relatedApplications.size());

         //Recalculate Hiring Manager access to applications
         if(!relatedApplications.isEmpty()){
            JobApplicationSharing.syncHiringManagerShares(relatedApplications, null);
         }

         //Recalculate Hiring Manager access to candidates.
         if(!candidateIds.isEmpty()){
            CandidateSharing.syncCandidateShares(candidateIds);
         }
      }
   }
}