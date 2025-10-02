public with sharing class OrderCloneAction {
    
    @InvocableMethod(label='Clonar Pedido' description='Clona un pedido y todas sus líneas de pedido')
    public static List<String> cloneOrderAction(List<String> orderIds) {
        List<String> results = new List<String>();
        
        for (String orderId : orderIds) {
            try {
                String clonedOrderId = OrderCloneController.cloneOrder(orderId);
                results.add(clonedOrderId);
            } catch (Exception e) {
                results.add('ERROR: ' + e.getMessage());
            }
        }
        
        return results;
    }
}