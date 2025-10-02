trigger Lead on Lead (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    if(Trigger.isAfter && Trigger.isUpdate) {
        LeadHandler.onConverted(Trigger.newMap, Trigger.oldMap);
    }
}