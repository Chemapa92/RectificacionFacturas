/**
 * @description Controller para la Quick Action de clonación de pedidos
 * @author Assistant
 * @date 2025-01-27
 */
public with sharing class OrderCloneQuickActionController {
    
    /**
     * @description Clona un pedido Order y todas sus líneas OrderItem
     * @param originalOrderId ID del pedido original a clonar
     * @return Información del pedido clonado
     */
    @AuraEnabled(cacheable=false)
    public static CloneResult cloneOrderWithLines(String originalOrderId) {
        Savepoint sp = Database.setSavepoint();
        
        try {
            // Verificar permisos
            if (!Schema.sObjectType.Order.isCreateable()) {
                throw new AuraHandledException('No tiene permisos para crear pedidos');
            }
            
            // Obtener el pedido original
            Order originalOrder = getOriginalOrder(originalOrderId);
            
            // Crear el nuevo pedido
            Order clonedOrder = createClonedOrder(originalOrder);
            insert clonedOrder;
            
            // Clonar las líneas del pedido
            Integer clonedLinesCount = cloneOrderItems(originalOrderId, clonedOrder.Id);
            
            return new CloneResult(true, clonedOrder.Id, clonedLinesCount, 'Pedido clonado exitosamente');
            
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException('Error al clonar el pedido: ' + e.getMessage());
        }
    }
    
    /**
     * @description Obtiene el pedido original con todos los campos necesarios
     */
    private static Order getOriginalOrder(String orderId) {
        List<Order> orders = [
            SELECT Id, AccountId, Pricebook2Id, ContractId, Status, EffectiveDate,
                   Name, OrderNumber, Description, Type, OwnerId, OpportunityId
            FROM Order 
            WHERE Id = :orderId 
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        
        if (orders.isEmpty()) {
            throw new AuraHandledException('No se encontró el pedido especificado');
        }
        
        return orders[0];
    }
    
    /**
     * @description Crea el nuevo pedido clonado con los campos apropiados
     */
    private static Order createClonedOrder(Order original) {
        Order cloned = new Order();
        
        // Campos básicos
        cloned.AccountId = original.AccountId;
        cloned.Pricebook2Id = original.Pricebook2Id;
        cloned.ContractId = original.ContractId;
        cloned.Status = 'Draft';
        cloned.EffectiveDate = Date.today();
        cloned.Description = original.Description;
        cloned.Type = original.Type;
        cloned.OwnerId = original.OwnerId;
        cloned.OpportunityId = original.OpportunityId;
        
        // Manejo seguro de multidivisa (solo si está habilitada)
        try {
            // Intentar obtener la divisa del original
            Object currencyValue = original.get('CurrencyIsoCode');
            if (currencyValue != null) {
                cloned.put('CurrencyIsoCode', currencyValue);
            }
        } catch (Exception e) {
            System.debug('Multidivisa no está habilitada o no se pudo establecer: ' + e.getMessage());
            // Continuar sin divisa específica
        }
        
        return cloned;
    }
    
    /**
     * @description Clona todas las líneas del pedido (OrderItems)
     */
    private static Integer cloneOrderItems(String originalOrderId, String clonedOrderId) {
        List<OrderItem> originalItems = [
            SELECT Id, Product2Id, PricebookEntryId, Quantity, UnitPrice, 
                   Description, ServiceDate, EndDate, OrderItemNumber, Product2.Name
            FROM OrderItem 
            WHERE OrderId = :originalOrderId 
            WITH SECURITY_ENFORCED
            ORDER BY OrderItemNumber
        ];
        
        if (originalItems.isEmpty()) {
            System.debug('No hay líneas de pedido para clonar');
            return 0;
        }
        
        List<OrderItem> clonedItems = new List<OrderItem>();
        
        for (OrderItem originalItem : originalItems) {
            OrderItem clonedItem = new OrderItem();
            
            // Campos básicos
            clonedItem.OrderId = clonedOrderId;
            clonedItem.Product2Id = originalItem.Product2Id;
            clonedItem.PricebookEntryId = originalItem.PricebookEntryId;
            clonedItem.Quantity = originalItem.Quantity;
            clonedItem.UnitPrice = originalItem.UnitPrice;
            clonedItem.Description = originalItem.Description;
            clonedItem.ServiceDate = originalItem.ServiceDate;
            clonedItem.EndDate = originalItem.EndDate;
            
            // Manejo seguro de campos opcionales
            try {
                // Intentar clonar descuento si existe
                Object discountValue = originalItem.get('Discount');
                if (discountValue != null) {
                    clonedItem.put('Discount', discountValue);
                }
            } catch (Exception e) {
                System.debug('Campo Discount no disponible: ' + e.getMessage());
            }
            
            try {
                // Intentar clonar sort order si existe
                Object sortOrderValue = originalItem.get('SortOrder');
                if (sortOrderValue != null) {
                    clonedItem.put('SortOrder', sortOrderValue);
                }
            } catch (Exception e) {
                System.debug('Campo SortOrder no disponible: ' + e.getMessage());
            }
            
            // Manejo seguro de multidivisa para líneas
            try {
                Object currencyValue = originalItem.get('CurrencyIsoCode');
                if (currencyValue != null) {
                    clonedItem.put('CurrencyIsoCode', currencyValue);
                }
            } catch (Exception e) {
                System.debug('No se pudo establecer la divisa en línea: ' + e.getMessage());
            }
            
            clonedItems.add(clonedItem);
        }
        
        if (!clonedItems.isEmpty()) {
            insert clonedItems;
            System.debug('Clonadas ' + clonedItems.size() + ' líneas de pedido');
        }
        
        return clonedItems.size();
    }
    
    /**
     * @description Clase para encapsular el resultado de la clonación
     */
    public class CloneResult {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String clonedOrderId { get; set; }
        @AuraEnabled public Integer clonedLinesCount { get; set; }
        @AuraEnabled public String message { get; set; }
        
        public CloneResult(Boolean success, String clonedOrderId, Integer clonedLinesCount, String message) {
            this.success = success;
            this.clonedOrderId = clonedOrderId;
            this.clonedLinesCount = clonedLinesCount;
            this.message = message;
        }
    }
}