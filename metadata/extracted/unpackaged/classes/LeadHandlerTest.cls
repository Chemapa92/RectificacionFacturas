@IsTest
public class LeadHandlerTest {

    @TestSetup
	private static void makeData(){
        Lead newLead = new Lead(Company='Cliente', LastName='Contacto',Business__c='Energía',EstimatedConsumption__c=11,TaxRate__c='1');
        insert newLead;
    }

    @IsTest
    public static void testOnConvert() {
        Lead updateLead = [SELECT id FROM Lead];
        Test.startTest();
            Database.LeadConvert lc = new database.LeadConvert();
            lc.setLeadId(updateLead.id);
            lc.setDoNotCreateOpportunity(false);
            lc.setConvertedStatus('Convertido');
            Database.LeadConvertResult lcr = Database.convertLead(lc);
            System.assert(lcr.isSuccess());
        Test.stopTest();
    }
}