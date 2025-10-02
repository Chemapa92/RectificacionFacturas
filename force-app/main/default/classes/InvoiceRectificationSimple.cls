public with sharing class InvoiceRectificationSimple {
    
    /**
     * @description Método invocable simple para usar en flows - sin parámetros
     * @return Lista de responses con el resultado
     */
    @InvocableMethod(label='Rectificar Factura Simple' description='Clona pedidos y facturas para rectificación sin parámetros')
    public static List<Response> executeRectification() {
        List<Response> responses = new List<Response>();
        Response res = new Response();
        
        try {
            // Obtener el ID de la factura desde el contexto del flow
            String invoiceId = getCurrentInvoiceId();
            
            if (String.isBlank(invoiceId)) {
                throw new AuraHandledException('No se pudo obtener el ID de la factura desde el contexto');
            }
            
            // Llamar al método que ya sabemos que funciona
            String result = InvoiceRectificationControllerDebugPage.executeRectificationProcess(invoiceId);
            res.isSuccess = true;
            res.message = 'Rectificación completada: ' + result;
            res.rectifiedOrderId = result;
        } catch (Exception e) {
            res.isSuccess = false;
            res.message = 'Error: ' + e.getMessage();
            res.rectifiedOrderId = null;
        }
        
        responses.add(res);
        return responses;
    }
    
    /**
     * @description Obtiene el ID de la factura actual desde el contexto
     * @return ID de la factura
     */
    private static String getCurrentInvoiceId() {
        // Intentar obtener el ID desde diferentes fuentes
        try {
            // Desde el contexto de la página
            String pageId = ApexPages.currentPage().getParameters().get('id');
            if (String.isNotBlank(pageId)) {
                return pageId;
            }
        } catch (Exception e) {
            // Ignorar si no estamos en una página
        }
        
        // Si no podemos obtener el ID del contexto, usar un ID de prueba
        // En producción, esto debería venir del Quick Action o del flow
        return 'a0dt00000000001'; // ID de prueba - reemplazar con lógica real
    }
    
    /**
     * @description Clase para el response
     */
    public class Response {
        @InvocableVariable(label='Éxito' description='Indica si la operación fue exitosa')
        public Boolean isSuccess;
        
        @InvocableVariable(label='Mensaje' description='Mensaje de resultado')
        public String message;
        
        @InvocableVariable(label='ID Pedido Rectificado' description='ID del pedido rectificado creado')
        public String rectifiedOrderId;
    }
}