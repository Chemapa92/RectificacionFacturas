@IsTest
public with sharing class InvoiceProformaControllerExtension_Test {

	@TestSetup
	private static void makeData(){
        Opportunity inv = new Opportunity(name='unittest',StageName='Pendiente Pago', Store__c = 'NAVARRA',  CloseDate=date.today());
        insert inv;
    }

    @IsTest
    public static void getAlmacenTest() {
        Test.startTest();
        Opportunity inv = [SELECT id, Store__c, Name FROM Opportunity LIMIT 1];
            Apexpages.StandardController sc = new Apexpages.StandardController(inv);
            InvoiceProformaControllerExtension ext = new  InvoiceProformaControllerExtension(sc); 
            ext.getAlmacen();
        Test.stopTest();
    }
}