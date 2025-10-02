@IsTest
public with sharing class ProductsSelectorControllerTest {

	@TestSetup
	private static void makeData(){
        Product2 p = new product2(name='unittest');
        insert p;
        insert new PricebookEntry(pricebook2id = Test.getStandardPricebookId(), product2id = p.id,unitprice=1.0, isActive=true);
        Pricebook2 pb = new pricebook2(name='unittest');
        insert pb;
        PricebookEntry pbe = new PricebookEntry(pricebook2id=pb.id, product2id=p.id,unitprice=2.0, isActive=true);
        insert pbe;
    }

    @IsTest
    public static void getPricebookEntriesTest() { 
        Test.startTest();
            List<PricebookEntry> lResult = ProductsSelectorController.getPricebookEntries('store', 1, 1, 'text');
            System.assertEquals(0, lResult.size(), 'Error');
        Test.stopTest();
    }

    @IsTest
    public static void getSelectedPricebookEntriesTest() {
        Pricebook2 pb1 = [select id from Pricebook2 where Name like 'unittest'];
        Test.startTest();
            List<PricebookEntry> lResult = ProductsSelectorController.getSelectedPricebookEntries(new List<String>{pb1.Id});
            System.assertEquals(0, lResult.size(), 'Error');
        Test.stopTest();
    }
    
    @IsTest
    Public static void CreateOppTest(){
        Pricebook2 pb1 = [select id from Pricebook2 where Name like 'unittest'];
        PricebookEntry pbe1 = [select id from PricebookEntry where pricebook2id=:pb1.id];
        List<Map<String, String>> listPrices = new List<Map<String, String>>();
        listPrices.add(new Map<String, String>{'Id'=>pbe1.id, 'UnitPrice'=>'1', 'Quantity'=>'1'});
        List<String> listEntryIds = new List<String>{pbe1.id};
        Account acc = new Account(Name='Test');
        Date closeDate = system.today();
        Date orderStartDate = system.today();
        Carrier__c Transportista = new Carrier__c(
            Name = 'Sin transporte',
            CarrierCode__c= '0',
            Business__c= 'Energía'
        );
        insert Transportista;
        insert acc;
        Test.startTest();
        	String result = ProductsSelectorController.createOpp(listPrices, '', acc.Id, 'P', '', closeDate, orderStartDate);
        	String result2 = ProductsSelectorController.createProformaBorrador(listPrices, listEntryIds, '', acc.Id, result, '', closeDate, orderStartDate);
        Test.stopTest();
    }

    @IsTest
    public static void searchTest() {
        Pricebook2 pb1 = [select id from Pricebook2 where Name like 'unittest'];
        PricebookEntry pbe1 = [select id from PricebookEntry where pricebook2id=:pb1.id];
        List<Map<String, String>> listPrices = new List<Map<String, String>>();
        listPrices.add(new Map<String, String>{'Id'=>pbe1.id, 'UnitPrice'=>'1', 'Quantity'=>'1'});
        List<String> listEntryIds = new List<String>{pbe1.id};
        Account acc = new Account(Name='Test');
        insert acc;
        Order__c newOrder = new Order__c(Account__c=acc.id);
        Test.startTest();
            String result = ProductsSelectorController.createOrder(listPrices, listEntryIds, newOrder);
            System.assert(result!=null, 'Error');
        Test.stopTest();
    }
}