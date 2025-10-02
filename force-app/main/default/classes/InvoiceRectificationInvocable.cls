public with sharing class InvoiceRectificationInvocable {
    
    /**
     * @description Método invocable para usar en flows
     * @param requests Lista de requests con el ID de la factura
     * @return Lista de responses con el resultado
     */
    @InvocableMethod(label='Rectificar Factura' description='Clona pedidos y facturas para rectificación')
    public static List<Response> executeRectification(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            try {
                // Llamar al método que ya sabemos que funciona
                String result = InvoiceRectificationControllerDebugPage.executeRectificationProcess(req.invoiceId);
                res.isSuccess = true;
                res.message = result;
                res.rectifiedOrderId = result; // El método devuelve el ID del pedido rectificado
            } catch (Exception e) {
                res.isSuccess = false;
                res.message = 'Error: ' + e.getMessage();
                res.rectifiedOrderId = null;
            }
            responses.add(res);
        }
        
        return responses;
    }
    
    /**
     * @description Clase para el request
     */
    public class Request {
        @InvocableVariable(label='ID de Factura' description='ID de la factura a rectificar' required=true)
        public String invoiceId;
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