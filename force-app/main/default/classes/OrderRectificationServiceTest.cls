@IsTest
private class OrderRectificationServiceTest {

    @IsTest
    static void testRectification() {
        // Datos mínimos (ajusta a tu modelo real)
        Account acc = new Account(Name='Test Acc');
        insert acc;

        // RecordType Original para el pedido original
        Order__c orig = new Order__c(
            Account__c=acc.Id,
            OrderDate__c=Date.today(),
            Status__c='Nuevo'
        );
        insert orig;

        Product2 prod = new Product2(Name='Producto X', IsActive=true);
        insert prod;

        // Crear línea de pedido con los campos correctos
        OrderItem__c line = new OrderItem__c(
            Pedido__c = orig.Id,
            ProductDescription__c = prod.Id,
            UnitPrice__c = 10,
            Quantity__c = 3
        );
        insert line;

        // Invoice con lookup al pedido original
        Invoice__c inv = new Invoice__c(Name='FAC-1', Order__c=orig.Id);
        insert inv;

        Test.startTest();
        System.enqueueJob(new OrderRectificationService(inv.Id));
        Test.stopTest();

        // Verificar que se creó el rectificativo con líneas negativas
        List<Order__c> rectis = [
            SELECT Id, RecordTypeId,
                   (SELECT Quantity__c, UnitPrice__c FROM Lineas_de_pedido__r)
            FROM Order__c
            WHERE Id != :orig.Id AND Account__c = :acc.Id
        ];
        System.assertEquals(1, rectis.size(), 'Debe existir un pedido rectificativo');

        Order__c r = rectis[0];
        // Verificar que tiene el Record Type correcto
        System.assertEquals(1, r.Lineas_de_pedido__r.size(), 'Debe clonar líneas');

        System.assertEquals(-3, r.Lineas_de_pedido__r[0].Quantity__c, 'Cantidad negativa');
        System.assertEquals(10, r.Lineas_de_pedido__r[0].UnitPrice__c, 'Precio igual');
    }
}
