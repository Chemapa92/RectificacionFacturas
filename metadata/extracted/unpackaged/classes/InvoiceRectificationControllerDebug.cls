/**
 * @description Controller de debug para rectificación de facturas
 * @author Sistema de Rectificación HAFESA
 * @date 2024
 */
public with sharing class InvoiceRectificationControllerDebug {
    
    /**
     * @description Método principal para iniciar el proceso de rectificación con debug
     * @param invoiceId ID de la factura original a rectificar
     * @return String ID del pedido rectificado para que el usuario lo edite
     */
    @AuraEnabled(cacheable=false)
    public static String startRectificationProcess(String invoiceId) {
        try {
            System.debug('=== INICIO PROCESO DE RECTIFICACIÓN ===');
            System.debug('Invoice ID: ' + invoiceId);
            
            // Verificar permisos
            if (!Schema.sObjectType.Order__c.isCreateable() || 
                !Schema.sObjectType.Invoice__c.isCreateable()) {
                throw new AuraHandledException('No tiene permisos para crear pedidos o facturas');
            }
            
            // Obtener la factura original
            Invoice__c originalInvoice = getInvoiceWithOrder(invoiceId);
            System.debug('Factura original obtenida: ' + originalInvoice.Name);
            
            // Verificar que la factura tenga un pedido asociado
            if (originalInvoice.Order__c == null) {
                throw new AuraHandledException('La factura no tiene un pedido asociado. No se puede proceder con la rectificación.');
            }
            
            // Obtener el pedido original
            Order__c originalOrder = getOrderWithItems(originalInvoice.Order__c);
            System.debug('Pedido original obtenido: ' + originalOrder.Name);
            
            // Verificar Record Types disponibles
            List<RecordType> orderRecordTypes = [SELECT Id, DeveloperName, Name FROM RecordType WHERE SobjectType = 'Order__c' WITH SECURITY_ENFORCED];
            System.debug('Record Types disponibles para Order__c: ' + orderRecordTypes);
            
            List<RecordType> invoiceRecordTypes = [SELECT Id, DeveloperName, Name FROM RecordType WHERE SobjectType = 'Invoice__c' WITH SECURITY_ENFORCED];
            System.debug('Record Types disponibles para Invoice__c: ' + invoiceRecordTypes);
            
            // 1. Crear pedido corrector (sin Record Type por ahora)
            Order__c correctorOrder = originalOrder.clone(false, true, false, false);
            correctorOrder.FinalAmount__c = -originalOrder.FinalAmount__c;
            correctorOrder.OrderDate__c = Date.today();
            correctorOrder.Status__c = 'Nuevo';
            correctorOrder.A3Status__c = null;
            correctorOrder.InvoiceNumber__c = null;
            
            System.debug('Insertando pedido corrector...');
            insert correctorOrder;
            System.debug('Pedido corrector creado: ' + correctorOrder.Id);
            
            // 2. Crear factura correctora (sin Record Type por ahora)
            Invoice__c correctorInvoice = originalInvoice.clone(false, true, false, false);
            correctorInvoice.Order__c = correctorOrder.Id;
            correctorInvoice.TotalAmount__c = -originalInvoice.TotalAmount__c;
            correctorInvoice.TaxBase__c = -originalInvoice.TaxBase__c;
            correctorInvoice.IVA__c = -originalInvoice.IVA__c;
            correctorInvoice.IRPF__c = -originalInvoice.IRPF__c;
            correctorInvoice.Requiv__c = -originalInvoice.Requiv__c;
            correctorInvoice.IssueDate__c = Date.today();
            
            System.debug('Insertando factura correctora...');
            insert correctorInvoice;
            System.debug('Factura correctora creada: ' + correctorInvoice.Id);
            
            // 3. Crear pedido rectificado
            Order__c rectifiedOrder = originalOrder.clone(false, true, false, false);
            rectifiedOrder.OrderDate__c = Date.today();
            rectifiedOrder.Status__c = 'Nuevo';
            rectifiedOrder.A3Status__c = null;
            rectifiedOrder.InvoiceNumber__c = null;
            
            System.debug('Insertando pedido rectificado...');
            insert rectifiedOrder;
            System.debug('Pedido rectificado creado: ' + rectifiedOrder.Id);
            
            // 4. Clonar líneas del pedido rectificado
            System.debug('Clonando líneas del pedido...');
            cloneOrderItems(originalOrder.Id, rectifiedOrder.Id);
            
            // 5. Enviar notificación por email
            System.debug('Enviando notificación por email...');
            sendNotificationEmail(originalInvoice, correctorOrder, correctorInvoice, rectifiedOrder);
            
            System.debug('=== PROCESO COMPLETADO EXITOSAMENTE ===');
            return rectifiedOrder.Id;
            
        } catch (Exception e) {
            System.debug('=== ERROR EN PROCESO DE RECTIFICACIÓN ===');
            System.debug('Error: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error en el proceso de rectificación: ' + e.getMessage());
        }
    }
    
    /**
     * @description Obtiene la factura original con su pedido asociado
     */
    private static Invoice__c getInvoiceWithOrder(String invoiceId) {
        List<Invoice__c> invoices = [
            SELECT Id, Name, Order__c, TotalAmount__c, TaxBase__c, IVA__c, IRPF__c, Requiv__c, IssueDate__c, Account__c
            FROM Invoice__c 
            WHERE Id = :invoiceId 
            WITH SECURITY_ENFORCED 
            LIMIT 1
        ];
        
        if (invoices.isEmpty()) {
            throw new AuraHandledException('Factura no encontrada');
        }
        
        return invoices[0];
    }
    
    /**
     * @description Obtiene el pedido con sus líneas
     */
    private static Order__c getOrderWithItems(String orderId) {
        List<Order__c> orders = [
            SELECT Id, Name, FinalAmount__c, OrderDate__c, Status__c, A3Status__c, InvoiceNumber__c, Account__c
            FROM Order__c 
            WHERE Id = :orderId 
            WITH SECURITY_ENFORCED 
            LIMIT 1
        ];
        
        if (orders.isEmpty()) {
            throw new AuraHandledException('Pedido no encontrado');
        }
        
        return orders[0];
    }
    
    /**
     * @description Clona las líneas de pedido
     */
    private static void cloneOrderItems(Id originalOrderId, Id newOrderId) {
        List<OrderItem__c> originalItems = [
            SELECT Id, Name, Quantity__c, UnitPrice__c, Pedido__c
            FROM OrderItem__c
            WHERE Pedido__c = :originalOrderId
            WITH SECURITY_ENFORCED
        ];
        
        List<OrderItem__c> newItems = new List<OrderItem__c>();
        for (OrderItem__c item : originalItems) {
            OrderItem__c newItem = item.clone(false, true, false, false);
            newItem.Pedido__c = newOrderId;
            newItems.add(newItem);
        }
        
        if (!newItems.isEmpty()) {
            insert newItems;
        }
    }
    
    /**
     * @description Envía notificación por email
     */
    private static void sendNotificationEmail(Invoice__c originalInvoice, Order__c correctorOrder, 
                                            Invoice__c correctorInvoice, Order__c rectifiedOrder) {
        try {
            // Crear el email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            
            // Establecer destinatario
            email.setToAddresses(new List<String>{'jose.porras@grupohafesa.com'});
            
            // Establecer remitente
            email.setSenderDisplayName('Sistema de Rectificación de Facturas');
            
            // Asunto del email
            email.setSubject('Notificación de Rectificación de Factura: ' + originalInvoice.Name);
            
            // Cuerpo del email
            String emailBody = 'Se ha completado el proceso de rectificación para la factura original: ' + originalInvoice.Name + ' (ID: ' + originalInvoice.Id + ').\n\n' +
                               'Detalles de los registros generados:\n' +
                               '  - Pedido Corrector: ' + correctorOrder.Name + ' (ID: ' + correctorOrder.Id + ')\n' +
                               '  - Factura Correctora: ' + correctorInvoice.Name + ' (ID: ' + correctorInvoice.Id + ')\n' +
                               '  - Pedido Rectificado (para su edición): ' + rectifiedOrder.Name + ' (ID: ' + rectifiedOrder.Id + ')\n\n' +
                               'Puede acceder al pedido rectificado para realizar las modificaciones necesarias.\n\n' +
                               'Saludos,\n' +
                               'Su equipo de Salesforce';
            
            email.setPlainTextBody(emailBody);
            
            // Enviar el email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
            
        } catch (Exception e) {
            System.debug('Error enviando email de notificación: ' + e.getMessage());
            // No lanzar excepción para no interrumpir el proceso principal
        }
    }
}