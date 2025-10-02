trigger OrderTrigger on Order__c (after update) {
    if(Trigger.isAfter && Trigger.isUpdate) {
        OrderHandler.handleAfterUpdate(Trigger.newMap, Trigger.oldMap);
    }
}