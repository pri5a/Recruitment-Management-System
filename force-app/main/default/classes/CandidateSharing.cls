public without sharing class CandidateSharing {
  public static void syncCandidateShares(Set<Id> candidateIds){
    if(candidateIds == null || candidateIds.isEmpty()){
        return;
    }

    //Find the Hiring Managers who should currently access each candidate.
    Map<Id, Set<Id>> candidateManagers = new Map<Id, set<Id>>();

    for(Job_Application__c app : [
        SELECT Candidate__c, Job_Opening__r.Hiring_Manager__c
        FROM Job_Application__c
        WHERE Candidate__c IN :candidateIds
        AND Job_Opening__r.Hiring_Manager__c != null
    ]) {
        Id candidateId = app.Candidate__c;
        Id managerId = app.Job_Opening__r.Hiring_Manager__c;

        if(!candidateManagers.containsKey(candidateId)){
            candidateManagers.put(candidateId, new Set<Id>());
        }
        candidateManagers.get(candidateId).add(managerId);
    }

    //Remove only shares created by this sharing automation.
    List<Candidate__Share> sharesToDelete = [
        SELECT Id
        FROM Candidate__Share
        WHERE ParentId IN :candidateIds
        AND RowCause = 'Recruitment_Access_Manager__c'
    ];

    if(!sharesToDelete.isEmpty()){
        Database.delete(sharesToDelete, false);
    }

    //Recreate access for the currently associated Hiring Managers.
    List<Candidate__Share> sharesToInsert = new List<Candidate__Share>();

    for(Id candidateId : candidateManagers.keySet()){
        for(Id managerId : candidateManagers.get(candidateId)){
            Candidate__Share newShare = new Candidate__Share();

            newShare.ParentId = candidateId;
            newShare.UserOrGroupId = managerId;
            newShare.AccessLevel = 'Read';
            newShare.RowCause = Schema.Candidate__Share.RowCause.Recruitment_Access_Manager__c;
            sharesToInsert.add(newShare);
        }
    }
    if(!sharesToInsert.isEmpty()){
        Database.insert(sharesToInsert, false);
    }
  }
}