/**
 * @description Clase de prueba para rectificación de facturas
 * @author Sistema de Rectificación HAFESA
 * @date 2024
 */
public class TestRectification {
    
    /**
     * @description Método de prueba para rectificación
     */
    public static void testRectification() {
        try {
            System.debug('=== INICIO TEST RECTIFICACIÓN ===');
            
            // Obtener una factura de prueba
            List<Invoice__c> invoices = [SELECT Id, Name, Order__c FROM Invoice__c WITH SECURITY_ENFORCED LIMIT 1];
            
            if (invoices.isEmpty()) {
                System.debug('ERROR: No hay facturas en el sistema');
                return;
            }
            
            Invoice__c testInvoice = invoices[0];
            System.debug('Factura de prueba: ' + testInvoice.Name + ' (ID: ' + testInvoice.Id + ')');
            
            // Probar clonación simple de pedido
            if (testInvoice.Order__c != null) {
                Order__c originalOrder = [SELECT Id, Name, Status__c, FinalAmount__c FROM Order__c WHERE Id = :testInvoice.Order__c WITH SECURITY_ENFORCED LIMIT 1];
                System.debug('Pedido original: ' + originalOrder.Name + ' Status: ' + originalOrder.Status__c);
                
                // Crear pedido clonado simple
                Order__c clonedOrder = originalOrder.clone(false, true, false, false);
                clonedOrder.Status__c = 'Nuevo';
                clonedOrder.FinalAmount__c = -originalOrder.FinalAmount__c;
                
                System.debug('Intentando insertar pedido clonado...');
                insert clonedOrder;
                System.debug('Pedido clonado creado exitosamente: ' + clonedOrder.Id);
                
                // Limpiar
                delete clonedOrder;
                System.debug('Pedido de prueba eliminado');
            }
            
            System.debug('=== TEST COMPLETADO EXITOSAMENTE ===');
            
        } catch (Exception e) {
            System.debug('ERROR en test: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
    }
}