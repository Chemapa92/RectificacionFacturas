@IsTest
public class InvocablePedidosA3Test {
	@IsTest
    public static void EnviarPedidoTest(){
        Account acc = new Account(Name='Test');
        insert acc;
        
        Order__c newOrder = new Order__c(Account__c=acc.id);
        insert newOrder; 
        
        list<Id> Ordenes = new list<Id>();
        Ordenes.add(newOrder.Id);
        
        Test.startTest();
        	InvocablePedidosA3.EnviarPedido(Ordenes);
        Test.stopTest();
    }
}