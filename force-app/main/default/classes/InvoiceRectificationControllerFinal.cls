/**
 * @description Controller para manejar la rectificación de facturas
 * @author Sistema de Rectificación HAFESA
 * @date 2024
 */
public with sharing class InvoiceRectificationControllerFinal {
    
    /**
     * @description Método principal para iniciar el proceso de rectificación
     * @param invoiceId ID de la factura original a rectificar
     * @return String ID del pedido rectificado para que el usuario lo edite
     */
    @AuraEnabled(cacheable=false)
    public static String startRectificationProcess(String invoiceId) {
        try {
            // Verificar permisos
            if (!Schema.sObjectType.Order__c.isCreateable() || 
                !Schema.sObjectType.Invoice__c.isCreateable()) {
                throw new AuraHandledException('No tiene permisos para crear pedidos o facturas');
            }
            
            // Obtener la factura original con su pedido
            Invoice__c originalInvoice = getInvoiceWithOrder(invoiceId);
            Order__c originalOrder = getOrderWithItems(originalInvoice.Order__c);
            
            // 1. Crear pedido corrector (con valores negativos)
            Order__c correctorOrder = createCorrectorOrder(originalOrder);
            
            // 2. Crear factura correctora (con valores negativos)
            Invoice__c correctorInvoice = createCorrectorInvoice(originalInvoice, correctorOrder);
            insert correctorInvoice;
            
            // 3. Crear pedido rectificado (para que el usuario lo edite)
            Order__c rectifiedOrder = createRectifiedOrder(originalOrder);
            insert rectifiedOrder;
            
            // 4. Clonar líneas del pedido rectificado
            cloneOrderItems(originalOrder.Id, rectifiedOrder.Id);
            
            // 5. Enviar notificación por email
            sendNotificationEmail(originalInvoice, correctorOrder, correctorInvoice, rectifiedOrder);
            
            return rectifiedOrder.Id;
            
        } catch (Exception e) {
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
     * @description Crea el pedido corrector con valores negativos
     */
    private static Order__c createCorrectorOrder(Order__c originalOrder) {
        // Obtener RecordType para Corrector
        Id correctorRecordTypeId = getRecordTypeId('Order__c', 'Corrector');
        
        Order__c correctorOrder = originalOrder.clone(false, true, false, false);
        // Name field is auto-generated, don't set it
        correctorOrder.RecordTypeId = correctorRecordTypeId;
        correctorOrder.FinalAmount__c = -originalOrder.FinalAmount__c;
        correctorOrder.OrderDate__c = Date.today();
        correctorOrder.Status__c = 'Rectificado'; // Estado que permite crear factura
        correctorOrder.A3Status__c = null;
        correctorOrder.InvoiceNumber__c = null;
        
        insert correctorOrder;
        
        // Clonar líneas del pedido con valores negativos
        cloneOrderItemsWithNegativeValues(originalOrder.Id, correctorOrder.Id);
        
        return correctorOrder;
    }
    
    /**
     * @description Crea la factura correctora con valores negativos
     */
    private static Invoice__c createCorrectorInvoice(Invoice__c originalInvoice, Order__c correctorOrder) {
        // Obtener RecordType para Correctora
        Id correctorRecordTypeId = getRecordTypeId('Invoice__c', 'Correctora');
        
        Invoice__c correctorInvoice = originalInvoice.clone(false, true, false, false);
        // Name field is auto-generated, don't set it
        correctorInvoice.RecordTypeId = correctorRecordTypeId;
        // correctorInvoice.FacturaOriginal__c = originalInvoice.Id; // Field will be available after manual creation
        correctorInvoice.Order__c = correctorOrder.Id;
        correctorInvoice.TotalAmount__c = -originalInvoice.TotalAmount__c;
        correctorInvoice.TaxBase__c = -originalInvoice.TaxBase__c;
        correctorInvoice.IVA__c = -originalInvoice.IVA__c;
        correctorInvoice.IRPF__c = -originalInvoice.IRPF__c;
        correctorInvoice.Requiv__c = -originalInvoice.Requiv__c;
        correctorInvoice.IssueDate__c = Date.today();
        
        return correctorInvoice;
    }
    
    /**
     * @description Crea el pedido rectificado para que el usuario lo edite
     */
    private static Order__c createRectifiedOrder(Order__c originalOrder) {
        // Obtener RecordType para Rectificado
        Id rectifiedRecordTypeId = getRecordTypeId('Order__c', 'Rectificado');
        
        Order__c rectifiedOrder = originalOrder.clone(false, true, false, false);
        // Name field is auto-generated, don't set it
        rectifiedOrder.RecordTypeId = rectifiedRecordTypeId;
        rectifiedOrder.OrderDate__c = Date.today();
        rectifiedOrder.Status__c = 'Rectificado';
        rectifiedOrder.A3Status__c = null;
        rectifiedOrder.InvoiceNumber__c = null;
        
        return rectifiedOrder;
    }
    
    /**
     * @description Clona las líneas del pedido con valores negativos
     */
    private static void cloneOrderItemsWithNegativeValues(Id originalOrderId, Id newOrderId) {
        List<OrderItem__c> originalItems = [
            SELECT Id, Name, Quantity__c, UnitPrice__c, TotalAmount__c, BasePrice__c, Pedido__c
            FROM OrderItem__c
            WHERE Pedido__c = :originalOrderId
            WITH SECURITY_ENFORCED
        ];
        
        List<OrderItem__c> newItems = new List<OrderItem__c>();
        for (OrderItem__c item : originalItems) {
            OrderItem__c newItem = item.clone(false, true, false, false);
            newItem.Pedido__c = newOrderId;
            newItem.Quantity__c = -item.Quantity__c;
            newItem.UnitPrice__c = -item.UnitPrice__c;
            // TotalAmount__c and BasePrice__c are calculated fields, not editable
            newItems.add(newItem);
        }
        
        if (!newItems.isEmpty()) {
            insert newItems;
        }
    }
    
    /**
     * @description Clona las líneas del pedido para el pedido rectificado
     */
    private static void cloneOrderItems(Id originalOrderId, Id newOrderId) {
        List<OrderItem__c> originalItems = [
            SELECT Id, Name, Quantity__c, UnitPrice__c, TotalAmount__c, BasePrice__c, Pedido__c
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
     * @description Obtiene el ID del RecordType por nombre
     */
    private static Id getRecordTypeId(String objectType, String recordTypeName) {
        List<RecordType> recordTypes = [
            SELECT Id 
            FROM RecordType 
            WHERE SobjectType = :objectType 
            AND DeveloperName = :recordTypeName 
            WITH SECURITY_ENFORCED 
            LIMIT 1
        ];
        
        if (recordTypes.isEmpty()) {
            throw new AuraHandledException('RecordType "' + recordTypeName + '" no encontrado para ' + objectType);
        }
        
        return recordTypes[0].Id;
    }
    
    /**
     * @description Envía notificación por email
     */
    private static void sendNotificationEmail(Invoice__c originalInvoice, Order__c correctorOrder, 
                                            Invoice__c correctorInvoice, Order__c rectifiedOrder) {
        try {
            Map<String, Object> rectificationData = new Map<String, Object>();
            rectificationData.put('originalInvoiceId', originalInvoice.Id);
            rectificationData.put('correctorOrderId', correctorOrder.Id);
            rectificationData.put('correctorInvoiceId', correctorInvoice.Id);
            rectificationData.put('rectifiedOrderId', rectifiedOrder.Id);
            
            InvoiceRectificationEmailService.sendNotification(rectificationData);
        } catch (Exception e) {
            System.debug('Error enviando email de notificación: ' + e.getMessage());
            // No lanzar excepción para no interrumpir el proceso principal
        }
    }
}