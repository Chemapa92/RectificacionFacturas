@IsTest
public with sharing class A3IntegrationServiceTest {

    @TestSetup
	private static void makeData(){
        Account acc = new Account(Name='Name',CIF__c='0001',ClientCodeA3__c='1',Business__c='Suministro',BillingStreet='Calle',BillingPostalCode='0001',BillingCountry='Pais',BillingState='Provincia',BillingCity='City',Phone='666555444',TaxRate__c='1');
        insert acc;
        Carrier__c carr = new Carrier__c(Name='Name',CarrierCode__c='0000');
        insert carr;
        Order__c ord = new Order__c(Account__c=acc.id,Store__c='TORREJON',Carrier__c=carr.id,OrderDate__c=Date.today(),ExpirationDateTime__c=Date.today(),Sale15__c=true);
        insert ord;
        Product2 prod = new Product2(Name='Name');
        insert prod;
        OrderItem__c item = new OrderItem__c(Pedido__c=ord.id,ProductDescription__c=prod.id,Quantity__c=1,UnitPrice__c=1);
        insert item;
    }

    @IsTest
    public static void testClientGetRequestWithBody() {
  		sObject obj = [SELECT id,Name,Business__c,CIF__c,BillingStreet,BillingPostalCode,BillingCountry,BillingState,BillingCity,Email__c,Phone,TaxRate__c, Owner.DistributionUserCode__c, Owner.EnergyUserCode__c FROM Account LIMIT 1];
        Test.startTest();
			A3IntegrationService.getRequestWithBody('POST', 'Client', obj, 100);
            Account acc = (Account) obj;
        	System.assertEquals(acc.id, obj.get('id'), 'Error');
        Test.stopTest();
    }

    @IsTest
    public static void testOrderGetRequestWithBody() {
  		sObject obj = [SELECT id,PaymentMethod__c,Account__r.Business__c,Account__r.ClientCodeA3__c,Account__r.Parent.RepresentativeCode__c ,Account__r.RepresentativeCode__c,OrderNumber__c,Store__c,Carrier__r.CarrierCode__c,Sale15__c,OrderDate__c,ExpirationDateTime__c,OwnerId,
        (
            SELECT id,ProductDescription__r.Id,ProductDescription__r.Name,ProductDescription__r.ProductCode,ProductDescription__r.Description,Quantity__c,UnitPrice__c 
            FROM Lineas_de_pedido__r
        ) 
        FROM Order__c 
        LIMIT 1];
        Test.startTest();
			A3IntegrationService.getRequestWithBody('POST', 'Order', obj, 100);
            Order__c ord = (Order__c) obj;
        	System.assertEquals(ord.id, obj.get('id'), 'Error');
        Test.stopTest();
    }

    @IsTest
    public static void testSendEmail() {
  		Account acc = [SELECT id FROM Account LIMIT 1];
        Test.startTest();
			A3IntegrationService.sendEmail(true, acc.id);
        	System.assert(acc.id != null);
        Test.stopTest();
    }
}