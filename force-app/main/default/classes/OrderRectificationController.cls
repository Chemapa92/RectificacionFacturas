public class OrderRectificationController {
    @AuraEnabled
    public static String createRectifyingOrder(Id invoiceId) {
        System.enqueueJob(new OrderRectificationService(invoiceId));
        return 'OK';
    }
}
