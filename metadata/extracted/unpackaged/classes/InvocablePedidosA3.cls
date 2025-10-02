public class InvocablePedidosA3 {
    @InvocableMethod(label='Enviar Pedidos a A3' description='Se envian los pedidos a A3')
    public static void EnviarPedido(List<string> recordId){
        sObject obj = [SELECT id,PaymentMethod__c,Name,Account__r.Business__c,Account__r.ClientCodeA3__c,Account__r.Parent.RepresentativeCode__c,Account__r.RepresentativeCode__c,OrderNumber__c,Store__c,Carrier__r.CarrierCode__c,Sale15__c,OrderDate__c,ExpirationDateTime__c,OwnerId,
                       (
                           SELECT id,ProductDescription__r.Id,ProductDescription__r.Name,ProductDescription__r.ProductCode,ProductDescription__r.Description,Quantity__c,UnitPrice__c 
                           FROM Lineas_de_pedido__r
                       ) 
                       FROM Order__c 
                       WHERE id = :recordId[0] Order by Name asc];
        
        QueueCallA3Service newQueue = new QueueCallA3Service(recordId[0], 'POST', 'Order', obj, 50000);
        System.enqueueJob(newQueue);
    }
}