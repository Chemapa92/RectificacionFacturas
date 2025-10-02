@IsTest
public with sharing class OrderHandlerTest {

    @TestSetup
	private static void makeData(){
        Account newAccount = new Account(Name='Cliente', Email__c='test@test.test');
        insert newAccount;
        Order__c newOrder = new Order__c(Account__c=newAccount.Id);
        insert newOrder;
    }

    @IsTest
    public static void handleAfterUpdateTest(){
        Order__c updateOrder = [SELECT id FROM Order__c LIMIT 1];
        updateOrder.FreightOder__c = '000000';
        update updateOrder;
    }
}