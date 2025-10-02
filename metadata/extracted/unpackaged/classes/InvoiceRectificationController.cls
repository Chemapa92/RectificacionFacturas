/**
 * @description Controller para la página de rectificación de facturas
 * @author Sistema de Rectificación HAFESA
 * @date 2024
 */
public with sharing class InvoiceRectificationController {
    
    public String errorMessage { get; set; }
    public String loadingMessage { get; set; }
    public String successMessage { get; set; }
    
    /**
     * @description Método que se ejecuta automáticamente al cargar la página
     */
    public PageReference rectifyInvoice() {
        try {
            // Obtener el ID de la factura desde los parámetros de la URL
            String invoiceId = ApexPages.currentPage().getParameters().get('id');
            
            if (String.isBlank(invoiceId)) {
                errorMessage = 'No se proporcionó el ID de la factura';
                return null;
            }
            
            loadingMessage = 'Iniciando proceso de rectificación...';
            
            // Llamar al método del controlador final
            String rectifiedOrderId = InvoiceRectificationControllerFinal.startRectificationProcess(invoiceId);
            
            if (String.isNotBlank(rectifiedOrderId)) {
                successMessage = 'Proceso de rectificación completado exitosamente. Redirigiendo al pedido rectificado...';
                
                // Redirigir al pedido rectificado después de un breve delay
                PageReference redirectPage = new PageReference('/' + rectifiedOrderId + '/e');
                redirectPage.setRedirect(true);
                return redirectPage;
            } else {
                errorMessage = 'No se pudo obtener el ID del pedido rectificado';
                return null;
            }
            
        } catch (Exception e) {
            errorMessage = 'Error durante el proceso de rectificación: ' + e.getMessage();
            System.debug('Error en InvoiceRectificationController.rectifyInvoice: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            return null;
        }
    }
}