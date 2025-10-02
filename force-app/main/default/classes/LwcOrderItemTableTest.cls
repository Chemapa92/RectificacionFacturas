@isTest
public with sharing class LwcOrderItemTableTest {
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
 
    @isTest
    static void test1(){
        OrderItem__c testId = [SELECT ID FROM OrderItem__c LIMIT 1];
        Test.startTest();
            LwcOrderItemTable.getOrderItems(new List<String>{testId.Id});
        Test.stopTest();
    }
}