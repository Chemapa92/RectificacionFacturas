@IsTest
public with sharing class ViewInvoiceControllerTest {

	@TestSetup
	private static void makeData(){
        Invoice__c inv = new Invoice__c(name='unittest');
        insert inv;
    }

    @IsTest
    public static void getInvoiceNameTest() {
        Test.startTest();
            Invoice__c inv = [SELECT id, Name FROM Invoice__c LIMIT 1];
            String result  = ViewInvoiceController.getInvoiceName(inv.id);
            System.assert(result.contains(inv.Name), 'Error on Name');
        Test.stopTest();
    }
}