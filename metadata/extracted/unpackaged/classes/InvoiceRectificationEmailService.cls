/**
 * @description Servicio para envío de emails de notificación de rectificación
 * @author Sistema de Rectificación HAFESA
 * @date 2025-01-27
 */
public with sharing class InvoiceRectificationEmailService {
    
    /**
     * @description Envía email de notificación del proceso de rectificación
     * @param rectificationData Datos de los registros creados en la rectificación
     */
    public static void sendNotification(Map<String, Object> rectificationData) {
        try {
            // Obtener usuario actual
            User currentUser = [SELECT Id, Name, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            // Preparar datos del email
            String originalInvoiceId = (String) rectificationData.get('originalInvoiceId');
            String correctorOrderId = (String) rectificationData.get('correctorOrderId');
            String correctorInvoiceId = (String) rectificationData.get('correctorInvoiceId');
            String rectifiedOrderId = (String) rectificationData.get('rectifiedOrderId');
            
            // Obtener información detallada de los registros
            Map<String, String> recordInfo = getRecordInformation(originalInvoiceId, correctorOrderId, correctorInvoiceId, rectifiedOrderId);
            
            // Crear el email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[]{currentUser.Email});
            email.setSubject('Rectificación de Factura Completada - ' + recordInfo.get('originalInvoiceName'));
            email.setHtmlBody(buildEmailBody(recordInfo));
            email.setSaveAsActivity(false);
            
            // Enviar email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            
            System.debug('Email de notificación enviado correctamente');
            
        } catch (Exception e) {
            System.debug('Error enviando email de notificación: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @description Obtiene información detallada de los registros
     */
    private static Map<String, String> getRecordInformation(String originalInvoiceId, String correctorOrderId, String correctorInvoiceId, String rectifiedOrderId) {
        Map<String, String> recordInfo = new Map<String, String>();
        
        try {
            // Obtener información de la factura original
            List<Invoice__c> originalInvoices = [
                SELECT Id, Name, TotalAmount__c, Account__r.Name
                FROM Invoice__c 
                WHERE Id = :originalInvoiceId 
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            if (!originalInvoices.isEmpty()) {
                Invoice__c original = originalInvoices[0];
                recordInfo.put('originalInvoiceName', original.Name);
                recordInfo.put('originalInvoiceAmount', String.valueOf(original.TotalAmount__c));
                recordInfo.put('originalAccountName', original.Account__r.Name);
            }
            
            // Obtener información del pedido corrector
            List<Order__c> correctorOrders = [
                SELECT Id, Name, FinalAmount__c
                FROM Order__c 
                WHERE Id = :correctorOrderId 
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            if (!correctorOrders.isEmpty()) {
                Order__c corrector = correctorOrders[0];
                recordInfo.put('correctorOrderName', corrector.Name);
                recordInfo.put('correctorOrderAmount', String.valueOf(corrector.FinalAmount__c));
            }
            
            // Obtener información de la factura correctora
            List<Invoice__c> correctorInvoices = [
                SELECT Id, Name, TotalAmount__c
                FROM Invoice__c 
                WHERE Id = :correctorInvoiceId 
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            if (!correctorInvoices.isEmpty()) {
                Invoice__c corrector = correctorInvoices[0];
                recordInfo.put('correctorInvoiceName', corrector.Name);
                recordInfo.put('correctorInvoiceAmount', String.valueOf(corrector.TotalAmount__c));
            }
            
            // Obtener información del pedido rectificado
            List<Order__c> rectifiedOrders = [
                SELECT Id, Name, FinalAmount__c
                FROM Order__c 
                WHERE Id = :rectifiedOrderId 
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            if (!rectifiedOrders.isEmpty()) {
                Order__c rectified = rectifiedOrders[0];
                recordInfo.put('rectifiedOrderName', rectified.Name);
                recordInfo.put('rectifiedOrderAmount', String.valueOf(rectified.FinalAmount__c));
            }
            
        } catch (Exception e) {
            System.debug('Error obteniendo información de registros: ' + e.getMessage());
        }
        
        return recordInfo;
    }
    
    /**
     * @description Construye el cuerpo HTML del email
     */
    private static String buildEmailBody(Map<String, String> recordInfo) {
        String htmlBody = '<html><body>';
        htmlBody += '<h2>Rectificación de Factura Completada</h2>';
        htmlBody += '<p>El proceso de rectificación se ha completado exitosamente. A continuación se detallan los registros creados:</p>';
        
        htmlBody += '<h3>Factura Original</h3>';
        htmlBody += '<ul>';
        htmlBody += '<li><strong>Nombre:</strong> ' + recordInfo.get('originalInvoiceName') + '</li>';
        htmlBody += '<li><strong>Importe:</strong> ' + recordInfo.get('originalInvoiceAmount') + ' €</li>';
        htmlBody += '<li><strong>Cliente:</strong> ' + recordInfo.get('originalAccountName') + '</li>';
        htmlBody += '</ul>';
        
        htmlBody += '<h3>Pedido Corrector (Valores Negativos)</h3>';
        htmlBody += '<ul>';
        htmlBody += '<li><strong>Nombre:</strong> ' + recordInfo.get('correctorOrderName') + '</li>';
        htmlBody += '<li><strong>Importe:</strong> ' + recordInfo.get('correctorOrderAmount') + ' €</li>';
        htmlBody += '</ul>';
        
        htmlBody += '<h3>Factura Correctora</h3>';
        htmlBody += '<ul>';
        htmlBody += '<li><strong>Nombre:</strong> ' + recordInfo.get('correctorInvoiceName') + '</li>';
        htmlBody += '<li><strong>Importe:</strong> ' + recordInfo.get('correctorInvoiceAmount') + ' €</li>';
        htmlBody += '</ul>';
        
        htmlBody += '<h3>Pedido Rectificado (Para Modificar)</h3>';
        htmlBody += '<ul>';
        htmlBody += '<li><strong>Nombre:</strong> ' + recordInfo.get('rectifiedOrderName') + '</li>';
        htmlBody += '<li><strong>Importe:</strong> ' + recordInfo.get('rectifiedOrderAmount') + ' €</li>';
        htmlBody += '</ul>';
        
        htmlBody += '<p><strong>Próximos pasos:</strong></p>';
        htmlBody += '<ol>';
        htmlBody += '<li>Modifique el pedido rectificado según sea necesario</li>';
        htmlBody += '<li>Cuando guarde el pedido rectificado, se creará automáticamente la factura rectificada correspondiente</li>';
        htmlBody += '<li>La factura correctora anulará la factura original con valores negativos</li>';
        htmlBody += '</ol>';
        
        htmlBody += '<p>Fecha: ' + Datetime.now().format('dd/MM/yyyy HH:mm') + '</p>';
        htmlBody += '</body></html>';
        
        return htmlBody;
    }
}