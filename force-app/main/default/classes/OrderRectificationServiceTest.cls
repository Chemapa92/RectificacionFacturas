@IsTest
private class OrderRectificationServiceTest {

    @IsTest
    static void testRectification() {
        // Datos mínimos (ajusta a tu modelo real)
        Account acc = new Account(Name='Test Acc');
        insert acc;

        // RecordType Rectificativo debe existir en metadata; no lo usamos al crear el original
        Order__c orig = new Order__c(
            Name='Pedido Original',
            Account__c=acc.Id,
            EffectiveDate__c=Date.today()
        );
        insert orig;

        Product2 prod = new Product2(Name='Producto X', IsActive=true);
        insert prod;

        Pricebook2 pb = new Pricebook2(Name='Std', IsActive=true);
        insert pb;

        // Suponiendo que OrderItem__c no usa PricebookEntries; ajusta a tu objeto custom
        OrderItem__c line = new OrderItem__c(
            Order__c = orig.Id,
            Product__c = prod.Id,
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
            SELECT Id, Original_Order__c,
                   (SELECT Quantity__c, UnitPrice__c FROM OrderItems__r)
            FROM Order__c
            WHERE Original_Order__c = :orig.Id
        ];
        System.assertEquals(1, rectis.size(), 'Debe existir un pedido rectificativo');

        Order__c r = rectis[0];
        System.assertEquals(orig.Id, r.Original_Order__c, 'Debe referenciar al original');
        System.assertEquals(1, r.OrderItems__r.size(), 'Debe clonar líneas');

        System.assertEquals(-3, r.OrderItems__r[0].Quantity__c, 'Cantidad negativa');
        System.assertEquals(10, r.OrderItems__r[0].UnitPrice__c, 'Precio igual');
    }
}
