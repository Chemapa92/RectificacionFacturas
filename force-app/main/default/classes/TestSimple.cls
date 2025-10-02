/**
 * @description Clase de prueba ultra-simple
 * @author Sistema de Rectificación HAFESA
 * @date 2024
 */
public class TestSimple {
    
    /**
     * @description Método ultra-simple para probar
     */
    public static void testBasic() {
        try {
            System.debug('=== INICIO TEST BÁSICO ===');
            
            // Solo crear un pedido simple
            Order__c testOrder = new Order__c();
            testOrder.FinalAmount__c = 100;
            testOrder.OrderDate__c = Date.today();
            testOrder.Status__c = 'Nuevo';
            testOrder.Account__c = '001dt0000000T0hAAE'; // Usar un Account válido
            
            System.debug('Insertando pedido de prueba...');
            insert testOrder;
            
            System.debug('Pedido creado exitosamente: ' + testOrder.Id);
            System.debug('=== TEST COMPLETADO ===');
            
        } catch (Exception e) {
            System.debug('ERROR: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
    }
}