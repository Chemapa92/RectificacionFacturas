@isTest
global with sharing class UpdateOrderScreenFlowControllerTest {
    
    @TestSetup
    static void makeData(){
        Account acc = new Account(Name='Name',CIF__c='0001',ClientCodeA3__c='1',Business__c='Suministro',BillingStreet='Calle',BillingPostalCode='0001',BillingCountry='Pais',BillingState='Provincia',BillingCity='City',Phone='666555444',TaxRate__c='1');
        insert acc;
        Carrier__c carr = new Carrier__c(Name='Name',CarrierCode__c='0000');
        insert carr;
        Order__c ord = new Order__c(PaymentMethod__c = 'C',Account__c=acc.id,Store__c='TORREJON',Carrier__c=carr.id,OrderDate__c=Date.today(),ExpirationDateTime__c=Date.today(),Sale15__c=true);
        insert ord;
        Product2 prod = new Product2(Name='Name');
        insert prod;
        OrderItem__c item = new OrderItem__c(Pedido__c=ord.id,ProductDescription__c=prod.id,Quantity__c=1,UnitPrice__c=1);
        insert item;
        
    }

    @isTest 
    global static void test1(){
        Order__c order = [SELECT PaymentMethod__c,Account__c,Store__c,Carrier__c,OrderDate__c,ExpirationDateTime__c,Sale15__c FROM Order__c LIMIT 1];
        List<OrderItem__c> listItems = [SELECT Pedido__c,ProductDescription__c,Quantity__c,UnitPrice__c,ProductDescription__r.Name FROM OrderItem__c];
        test.startTest();
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

            UpdateOrderScreenFlowController.callOutA3(order,listItems,'test');
        test.stopTest();
    }
    @isTest 
    global static void test2(){
        Order__c order = [SELECT PaymentMethod__c,Account__c,Store__c,Carrier__c,OrderDate__c,ExpirationDateTime__c,Sale15__c FROM Order__c LIMIT 1];
        String testData = 'test;'+order.Id;
        test.startTest();
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

            UpdateOrderScreenFlowController.getAccountNames(new List<String>{testData});
        test.stopTest();
    }
    global class MockHttpResponseGenerator implements HttpCalloutMock {
        // Implement this interface method
        global HTTPResponse respond(HTTPRequest req) {
            // Optionally, only send a mock response for a specific endpoint
            // and method.
            System.assertEquals('https://example.com/example/test', req.getEndpoint());
            System.assertEquals('GET', req.getMethod());
            
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"example":"test"}');
            res.setStatusCode(200);
            return res;
        }
    }
}