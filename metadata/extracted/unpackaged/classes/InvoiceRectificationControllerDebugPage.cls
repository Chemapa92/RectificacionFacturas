/**
 * @description Controller para la página de rectificación de facturas con debug
 * @author Sistema de Rectificación HAFESA
 * @date 2024
 */
public with sharing class InvoiceRectificationControllerDebugPage {
    
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
            
            // Ejecutar la lógica de rectificación directamente
            String rectifiedOrderId = executeRectificationProcess(invoiceId);
            
            successMessage = 'Proceso de rectificación completado. Redirigiendo al pedido rectificado.';
            
            // Redirigir al pedido rectificado
            PageReference pageRef = new PageReference('/' + rectifiedOrderId);
            pageRef.setRedirect(true);
            return pageRef;
            
        } catch (Exception e) {
            errorMessage = 'Error en el proceso de rectificación: ' + e.getMessage();
            System.debug('Error en rectifyInvoice: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            return null;
        }
    }
    
    /**
     * @description Método @AuraEnabled para usar en Flow Builder
     * @param invoiceId ID de la factura a rectificar
     * @return String con el resultado de la rectificación
     */
    @AuraEnabled(cacheable=false)
    public static String executeRectificationFromFlow(String invoiceId) {
        try {
            // Obtener el ID del pedido desde la factura
            Invoice__c invoice = [SELECT Order__c FROM Invoice__c WHERE Id = :invoiceId LIMIT 1];
            
            if (invoice.Order__c == null) {
                throw new AuraHandledException('La factura no tiene un pedido asociado');
            }
            
            // Llamar al método que ya sabemos que funciona con el ID del pedido
            String result = executeRectificationProcess(invoice.Order__c);
            return 'SUCCESS: ' + result;
        } catch (Exception e) {
            return 'ERROR: ' + e.getMessage();
        }
    }

    /**
     * @description Ejecuta el proceso de rectificación con el código que sabemos que funciona
     */
    @AuraEnabled(cacheable=false)
    public static String executeRectificationProcess(String invoiceId) {
        try {
            System.debug('=== INICIO PROCESO RECTIFICACIÓN ===');
            System.debug('Invoice ID: ' + invoiceId);
            
            // Verificar permisos básicos
            if (!Schema.sObjectType.Order__c.isCreateable()) {
                throw new AuraHandledException('No tiene permisos para crear pedidos');
            }
            
            // Obtener la factura original
            Invoice__c originalInvoice = [
                SELECT Id, Name, Order__c, TotalAmount__c, TaxBase__c, IVA__c, IRPF__c, Requiv__c, IssueDate__c, Account__c
                FROM Invoice__c
                WHERE Id = :invoiceId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            System.debug('Factura obtenida: ' + originalInvoice.Name);
            
            // Verificar que la factura tenga un pedido asociado
            if (originalInvoice.Order__c == null) {
                throw new AuraHandledException('La factura no tiene un pedido asociado');
            }
            
            // Obtener el pedido original
            Order__c originalOrder = [
                SELECT Id, Name, FinalAmount__c, OrderDate__c, Status__c, A3Status__c, InvoiceNumber__c, Account__c
                FROM Order__c
                WHERE Id = :originalInvoice.Order__c
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            System.debug('Pedido obtenido: ' + originalOrder.Name);
            
            // 1. Crear pedido corrector
            Order__c correctorOrder = new Order__c();
            // Name field is auto-generated, don't set it
            correctorOrder.FinalAmount__c = -originalOrder.FinalAmount__c;
            correctorOrder.OrderDate__c = Date.today();
            correctorOrder.Status__c = 'Nuevo'; 
            correctorOrder.A3Status__c = null;
            correctorOrder.InvoiceNumber__c = null;
            correctorOrder.Account__c = originalOrder.Account__c;
            
            System.debug('Insertando pedido corrector...');
            insert correctorOrder;
            System.debug('Pedido corrector creado: ' + correctorOrder.Id);
            
            // 2. Crear factura correctora
            Invoice__c correctorInvoice = new Invoice__c();
            // Name field is auto-generated, don't set it
            correctorInvoice.Order__c = correctorOrder.Id;
            correctorInvoice.Account__c = originalInvoice.Account__c;
            correctorInvoice.TotalAmount__c = -originalInvoice.TotalAmount__c;
            correctorInvoice.TaxBase__c = -originalInvoice.TaxBase__c;
            correctorInvoice.IVA__c = -originalInvoice.IVA__c;
            correctorInvoice.IRPF__c = originalInvoice.IRPF__c != null ? -originalInvoice.IRPF__c : 0;
            correctorInvoice.Requiv__c = originalInvoice.Requiv__c != null ? -originalInvoice.Requiv__c : 0;
            correctorInvoice.IssueDate__c = Date.today();
            
            System.debug('Insertando factura correctora...');
            insert correctorInvoice;
            System.debug('Factura correctora creada: ' + correctorInvoice.Id);
            
            // 3. Crear pedido rectificado
            Order__c rectifiedOrder = new Order__c();
            // Name field is auto-generated, don't set it
            rectifiedOrder.FinalAmount__c = originalOrder.FinalAmount__c;
            rectifiedOrder.OrderDate__c = Date.today();
            rectifiedOrder.Status__c = 'Nuevo';
            rectifiedOrder.A3Status__c = null;
            rectifiedOrder.InvoiceNumber__c = null;
            rectifiedOrder.Account__c = originalOrder.Account__c;
            
            System.debug('Insertando pedido rectificado...');
            insert rectifiedOrder;
            System.debug('Pedido rectificado creado: ' + rectifiedOrder.Id);
            
            // 4. Clonar productos del pedido corrector (valores negativos)
            cloneOrderItems(correctorOrder.Id, originalOrder.Id, true);
            
            // 5. Clonar productos del pedido rectificado (valores positivos)
            cloneOrderItems(rectifiedOrder.Id, originalOrder.Id, false);
            
            // 6. Clonar productos de la factura correctora (valores negativos)
            cloneInvoiceItems(correctorInvoice.Id, originalInvoice.Id, true);
            
            System.debug('=== PROCESO COMPLETADO EXITOSAMENTE ===');
            System.debug('RESULTADOS:');
            System.debug('- Pedido Corrector ID: ' + correctorOrder.Id);
            System.debug('- Factura Correctora ID: ' + correctorInvoice.Id);
            System.debug('- Pedido Rectificado ID: ' + rectifiedOrder.Id);
            
            return rectifiedOrder.Id;
            
        } catch (Exception e) {
            System.debug('ERROR: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error en rectificación: ' + e.getMessage());
        }
    }
    
    /**
     * @description Clona los productos de un pedido
     */
    private static void cloneOrderItems(Id newOrderId, Id originalOrderId, Boolean isNegative) {
        try {
            List<OrderItem__c> originalItems = [
                SELECT Id, Name, Quantity__c, UnitPrice__c, ProductDescription__c
                FROM OrderItem__c
                WHERE Pedido__c = :originalOrderId
                WITH SECURITY_ENFORCED
            ];
            
            if (!originalItems.isEmpty()) {
                List<OrderItem__c> newItems = new List<OrderItem__c>();
                for (OrderItem__c item : originalItems) {
                    OrderItem__c newItem = new OrderItem__c();
                    newItem.Pedido__c = newOrderId;
                    newItem.ProductDescription__c = item.ProductDescription__c;
                    newItem.Quantity__c = isNegative ? -item.Quantity__c : item.Quantity__c;
                    newItem.UnitPrice__c = isNegative ? -item.UnitPrice__c : item.UnitPrice__c;
                    newItems.add(newItem);
                }
                insert newItems;
                System.debug('Productos de pedido clonados: ' + newItems.size() + ' items');
            }
        } catch (Exception e) {
            System.debug('Error clonando productos de pedido: ' + e.getMessage());
        }
    }
    
    /**
     * @description Clona los productos de una factura
     */
    private static void cloneInvoiceItems(Id newInvoiceId, Id originalInvoiceId, Boolean isNegative) {
        try {
            List<InvoiceItem__c> originalItems = [
                SELECT Id, Name, Quantity__c, Price__c, Product__c, Descrip__c
                FROM InvoiceItem__c
                WHERE Invoice__c = :originalInvoiceId
                WITH SECURITY_ENFORCED
            ];
            
            if (!originalItems.isEmpty()) {
                List<InvoiceItem__c> newItems = new List<InvoiceItem__c>();
                for (InvoiceItem__c item : originalItems) {
                    InvoiceItem__c newItem = new InvoiceItem__c();
                    newItem.Invoice__c = newInvoiceId;
                    newItem.Product__c = item.Product__c;
                    newItem.Descrip__c = item.Descrip__c;
                    newItem.Quantity__c = isNegative ? -item.Quantity__c : item.Quantity__c;
                    newItem.Price__c = isNegative ? -item.Price__c : item.Price__c;
                    newItems.add(newItem);
                }
                insert newItems;
                System.debug('Productos de factura clonados: ' + newItems.size() + ' items');
            }
        } catch (Exception e) {
            System.debug('Error clonando productos de factura: ' + e.getMessage());
        }
    }
}