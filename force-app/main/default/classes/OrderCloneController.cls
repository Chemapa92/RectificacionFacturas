/**
 * @description Controller para clonar pedidos (Order__c)
 * @author José María Porras
 * @date 2025-09-30
 */
public with sharing class OrderCloneController {
    
    /**
     * @description Clona un pedido existente con los campos especificados y sus líneas
     * @param originalOrderId ID del pedido original a clonar
     * @return ID del nuevo pedido clonado
     */
    @AuraEnabled(cacheable=false)
    public static String cloneOrder(String originalOrderId) {
        try {
            // Verificar que el usuario tenga permisos para crear pedidos
            if (!Schema.sObjectType.Order__c.isCreateable()) {
                throw new AuraHandledException('No tiene permisos para crear pedidos');
            }
            
            // Obtener el pedido original con todos los campos necesarios
            Order__c originalOrder = [
                SELECT Id, Name, OrderNumber__c, OrderDate__c, Account__c, 
                       Business__c, Store__c, Platform__c, PaymentMethod__c,
                       FinalAmount__c, TaxBase__c, Margin__c, Status__c,
                       Carrier__c, FreightDate__c, DeliveryNoteNumber__c,
                       InvoiceNumber__c, Proforma__c, Serie__c, A3Status__c,
                       PlantStatus__c, Sale15__c
                FROM Order__c 
                WHERE Id = :originalOrderId 
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            // Crear el nuevo pedido clonado
            Order__c clonedOrder = originalOrder.clone(false, true, false, false);
            
            // Modificar campos específicos para el pedido clonado
            clonedOrder.OrderNumber__c = null; // Se generará automáticamente
            clonedOrder.OrderDate__c = Date.today();
            clonedOrder.Status__c = 'Nuevo'; // Estado inicial
            clonedOrder.A3Status__c = null;
            clonedOrder.PlantStatus__c = null;
            clonedOrder.DeliveryNoteNumber__c = null;
            clonedOrder.InvoiceNumber__c = null;
            clonedOrder.FreightDate__c = null;
            
            // Insertar el nuevo pedido
            insert clonedOrder;
            
            // Buscar y clonar las líneas de pedido relacionadas
            cloneOrderLines(originalOrderId, clonedOrder.Id);
            
            return clonedOrder.Id;
            
        } catch (QueryException e) {
            throw new AuraHandledException('Error al obtener el pedido: ' + e.getMessage());
        } catch (DmlException e) {
            throw new AuraHandledException('Error al crear el pedido clonado: ' + e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Error inesperado: ' + e.getMessage());
        }
    }
    
    /**
     * @description Clona las líneas de pedido relacionadas
     * @param originalOrderId ID del pedido original
     * @param clonedOrderId ID del pedido clonado
     */
    private static void cloneOrderLines(String originalOrderId, String clonedOrderId) {
        try {
            System.debug('=== INICIANDO CLONACIÓN DE LÍNEAS DE PEDIDO ===');
            System.debug('Order ID original: ' + originalOrderId);
            System.debug('Order ID clonado: ' + clonedOrderId);
            
            // Usar el objeto correcto: OrderItem__c con el campo Pedido__c
            List<OrderItem__c> originalLines = [
                SELECT Id, Pedido__c, Name, ProductCode__c, ProductDescription__c, 
                       Quantity__c, UnitPrice__c, TotalAmount__c, BasePrice__c, 
                       BaseTotal__c, Margin__c, MinimalPrice__c, MinimalTotal__c
                FROM OrderItem__c 
                WHERE Pedido__c = :originalOrderId 
                WITH SECURITY_ENFORCED
            ];
            
            System.debug('Líneas encontradas: ' + originalLines.size());
            
            if (!originalLines.isEmpty()) {
                List<OrderItem__c> clonedLines = new List<OrderItem__c>();
                
                for (OrderItem__c originalLine : originalLines) {
                    OrderItem__c clonedLine = originalLine.clone(false, true, false, false);
                    clonedLine.Pedido__c = clonedOrderId;
                    clonedLines.add(clonedLine);
                    
                    System.debug('Clonando línea: ' + originalLine.Name + ' -> ' + clonedLine.Name);
                }
                
                insert clonedLines;
                System.debug('✅ Líneas clonadas exitosamente: ' + clonedLines.size());
            } else {
                System.debug('ℹ️  No hay líneas de pedido para clonar');
            }
            
            System.debug('=== FIN DE CLONACIÓN DE LÍNEAS ===');
        } catch (Exception e) {
            System.debug('❌ Error clonando líneas de pedido: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error al clonar las líneas de pedido: ' + e.getMessage());
        }
    }
    
    
    /**
     * @description Obtiene los detalles de un pedido para mostrar en el modal de confirmación
     * @param orderId ID del pedido
     * @return Objeto Order__c con los campos necesarios
     */
    @AuraEnabled(cacheable=true)
    public static Order__c getOrderDetails(String orderId) {
        try {
            return [
                SELECT Id, Name, OrderNumber__c, OrderDate__c, Account__c, 
                       Business__c, Store__c, Platform__c, PaymentMethod__c,
                       FinalAmount__c, Status__c, CreatedDate
                FROM Order__c 
                WHERE Id = :orderId 
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error al obtener detalles del pedido: ' + e.getMessage());
        }
    }
    
    // Variables para la página Visualforce
    public String loadingMessage { get; set; }
    public String errorMessage { get; set; }
    
    /**
     * @description Constructor para la página Visualforce
     */
    public OrderCloneController() {
        // Constructor vacío
    }
    
    /**
     * @description Método de acción para la página Visualforce
     */
    public PageReference cloneOrder() {
        try {
            String originalOrderId = ApexPages.currentPage().getParameters().get('recordId');
            
            if (String.isBlank(originalOrderId)) {
                errorMessage = 'No se encontró el ID del pedido a clonar';
                return null;
            }
            
            loadingMessage = 'Clonando pedido...';
            
            // Ejecutar la clonación
            String clonedOrderId = cloneOrder(originalOrderId);
            
            if (String.isNotBlank(clonedOrderId)) {
                // Redirigir al pedido clonado
                PageReference pageRef = new PageReference('/' + clonedOrderId);
                pageRef.setRedirect(true);
                return pageRef;
            } else {
                errorMessage = 'No se pudo crear el pedido clonado';
                return null;
            }
            
        } catch (Exception e) {
            errorMessage = 'Error al clonar el pedido: ' + e.getMessage();
            return null;
        }
    }
    
    /**
     * @description Método de diagnóstico que devuelve información sobre las líneas de pedido
     * @param orderId ID del pedido a diagnosticar
     * @return Información del diagnóstico
     */
    @AuraEnabled(cacheable=false)
    public static String diagnoseOrderLines(String orderId) {
        try {
            String result = '=== DIAGNÓSTICO AVANZADO DE LÍNEAS DE PEDIDO ===\n';
            result += 'Order ID: ' + orderId + '\n\n';
            
            // Probar directamente con el objeto correcto: OrderItem__c
            result += '🔍 BUSCANDO LÍNEAS DE PEDIDO...\n';
            result += 'Probando con el objeto correcto: OrderItem__c\n\n';
            
            boolean found = false;
            
            try {
                // Contar registros
                String countQuery = 'SELECT COUNT() FROM OrderItem__c WHERE Pedido__c = :orderId';
                Integer totalCount = Database.countQuery(countQuery);
                
                if (totalCount > 0) {
                    result += '✅ ¡ENCONTRADO! Objeto "OrderItem__c" con campo "Pedido__c"\n';
                    result += '   Total de registros: ' + totalCount + '\n\n';
                    
                    // Obtener detalles de los primeros registros
                    List<OrderItem__c> detailResults = [
                        SELECT Id, Name, ProductCode__c, ProductDescription__c, 
                               Quantity__c, UnitPrice__c, TotalAmount__c
                        FROM OrderItem__c 
                        WHERE Pedido__c = :orderId 
                        LIMIT 5
                    ];
                    
                    result += '   Detalles de los primeros registros:\n';
                    for (OrderItem__c record : detailResults) {
                        result += '   - ID: ' + record.Id + ', Name: ' + record.Name + '\n';
                        result += '     Producto: ' + record.ProductDescription__c + '\n';
                        result += '     Cantidad: ' + record.Quantity__c + ', Precio: ' + record.UnitPrice__c + '\n';
                    }
                    found = true;
                } else {
                    result += 'ℹ️  No se encontraron líneas de pedido en OrderItem__c\n';
                }
                
            } catch (Exception e) {
                result += '❌ Error consultando OrderItem__c: ' + e.getMessage() + '\n';
            }
            
            if (!found) {
                result += '❌ NO SE ENCONTRARON LÍNEAS DE PEDIDO\n';
                result += 'Posibles causas:\n';
                result += '1. No hay líneas de pedido en este pedido específico\n';
                result += '2. No hay permisos para acceder a las líneas\n';
                result += '3. El pedido aún no tiene líneas asociadas\n';
            }
            
            result += '\n=== FIN DEL DIAGNÓSTICO ===';
            return result;
            
        } catch (Exception e) {
            return 'Error en diagnóstico: ' + e.getMessage();
        }
    }

    @InvocableMethod(label='Clonar Pedido' description='Clona un pedido y todas sus líneas de pedido relacionadas.')
    public static List<String> cloneOrderInvocable(List<String> orderIds) {
        List<String> results = new List<String>();
        for (String orderId : orderIds) {
            try {
                String clonedOrderId = cloneOrder(orderId);
                results.add(clonedOrderId);
            } catch (Exception e) {
                results.add('ERROR: ' + e.getMessage());
            }
        }
        return results;
    }
}