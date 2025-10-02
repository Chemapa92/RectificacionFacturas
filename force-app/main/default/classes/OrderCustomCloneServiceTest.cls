/**
 * @description Pruebas unitarias para OrderCustomCloneService
 * @author Assistant
 * @date 2025-01-27
 */
@IsTest
private class OrderCustomCloneServiceTest {
    // Ajusta estos métodos utilitarios a tu modelo si tus campos difieren.
    private static SObject mkOrder() {
        // Crea Order__c mínimo viable (ajusta campos requeridos específicos de tu org)
        SObject o = (SObject) Type.forName('Schema', 'Order__c').newInstance();
        // Si Account__c es requerido en tu org, crea la cuenta y asigna
        Account a = new Account(Name='Cuenta Test');
        insert a;
        o.put('Account__c', a.Id);
        if (OrderCustomCloneService.hasField('Order__c','Status__c')) o.put('Status__c','Draft');
        insert o;
        return o;
    }
    
    private static SObject mkLine(Id orderId) {
        SObject li = (SObject) Type.forName('Schema', 'OrderItem__c').newInstance();
        li.put('Pedido__c', orderId);
        if (OrderCustomCloneService.hasField('OrderItem__c','Quantity__c')) li.put('Quantity__c', 2);
        if (OrderCustomCloneService.hasField('OrderItem__c','UnitPrice__c')) li.put('UnitPrice__c', 10);
        insert li;
        return li;
    }

    @IsTest
    static void clone_withLines_ok() {
        SObject o = mkOrder();
        mkLine((Id) o.get('Id'));
        mkLine((Id) o.get('Id'));

        Test.startTest();
        OrderCustomCloneService.Result r = OrderCustomCloneService.cloneOrder((Id) o.get('Id'));
        Test.stopTest();

        System.assertEquals(null, r.errorMessage, 'Debe clonar sin error');
        System.assertNotEquals(null, r.newOrderId, 'Debe devolver Id nuevo');

        Integer lines = [SELECT COUNT() FROM OrderItem__c WHERE Pedido__c = :r.newOrderId];
        System.assertEquals(2, lines, 'Debe clonar 2 líneas');
    }

    @IsTest
    static void clone_withoutLines_ok() {
        SObject o = mkOrder();

        Test.startTest();
        OrderCustomCloneService.Result r = OrderCustomCloneService.cloneOrder((Id) o.get('Id'));
        Test.stopTest();

        System.assertEquals(null, r.errorMessage);
        System.assertNotEquals(null, r.newOrderId);

        Integer lines = [SELECT COUNT() FROM OrderItem__c WHERE Pedido__c = :r.newOrderId];
        System.assertEquals(0, lines, 'No debe crear líneas si no hay origen');
    }

    @IsTest
    static void clone_withNullId_returnsError() {
        Test.startTest();
        OrderCustomCloneService.Result r = OrderCustomCloneService.cloneOrder(null);
        Test.stopTest();

        System.assertNotEquals(null, r.errorMessage, 'Debe devolver error para ID nulo');
        System.assertEquals(null, r.newOrderId, 'No debe crear pedido con ID nulo');
    }
}