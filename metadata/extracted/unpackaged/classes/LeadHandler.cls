public with sharing class LeadHandler {

    public static Savepoint sp;

    //Check if one lead comes for convert and call WS
    public static void onConverted(Map<Id, Lead> newLeads, Map<Id, Lead> oldLeads){
        if(newLeads.size() == 1){
            for(Id key : newLeads.keySet()){
                if(oldLeads.get(key).IsConverted == false && newLeads.get(key).IsConverted == true){
                    sObject acc = [SELECT id, Name, Business__c, CIF__c, BillingStreet, BillingPostalCode, BillingCountry, BillingState, BillingCity, Email__c, Phone, TaxRate__c, Owner.DistributionUserCode__c, Owner.EnergyUserCode__c FROM Account WHERE id = :newLeads.get(key).ConvertedAccountId];
                    QueueCallA3Service newQueue = new QueueCallA3Service(key, 'POST', 'Client', acc, 50000);
                    System.enqueueJob(newQueue);
                }
            }
        }
    }
}