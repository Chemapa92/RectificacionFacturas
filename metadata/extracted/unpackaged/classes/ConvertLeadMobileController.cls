public with sharing class ConvertLeadMobileController {

    @AuraEnabled
    public static String convertLeadAutomatic(String recordId){
        Lead myLead = [SELECT id FROM Lead where id = :recordId];

        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(myLead.id);

        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);

        try{
            Database.LeadConvertResult lcr = Database.convertLead(lc);
            myLead = [SELECT id, ConvertedAccountId FROM Lead where id = :recordId];
            return myLead.ConvertedAccountId;
        }catch(Exception e){
            System.debug('Error on convertLeadAutomatic: ' + e.getMessage() + ' on ' + e.getLineNumber());
            String errorText = e.getMessage();
            if(errorText.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                errorText = errorText.split('FIELD_CUSTOM_VALIDATION_EXCEPTION').get(1).split(':').get(1);
            }
            return 'ERROR: ' + errorText;
        }
    }
}