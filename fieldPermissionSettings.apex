
/**  SET FIELDS TO TRUE/FALSE **/

/** 
* If Object and field combo is plugged in and settings for both read and write are false you will receive a misleading error message along the lines of, "...permission set read is required.."
* This doesn't make sense because we are trying to set the permissions for both write and read to false.  From the inital trial and error in reproducing this error I believe it shows up when there isn't any read or write permission on the field to begin with
* Below is a SOQL query to confirm whether or not there are any current permissions on the custom field that can be run before and after to see what the results were and if a false/false permission setting is necessary
*        SELECT SobjectType, 
*    Field, ParentId, 
*    Parent.Label, 
*    Parent.Name, 
*    PermissionsRead, 
*    PermissionsEdit 
*    FROM FieldPermissions 
*    WHERE Field = 'Account.Custom_Field__c' 
*      AND Parent.Name = 'OFFICE_MANAGER'
**/

List<String> permissionSetNamesToAdjustFieldsFor = new List<String>{
        'OFFICE_MANAGER',
        'REGIONAL_DIRECTOR',
        'CLIENT_SERVICES',
        'SALES'
};

Map<String, Map<String, Boolean>> fieldsToBeAdjustedMap = new Map<String, Map<String, Boolean>> {

        'Account.Custom_Field__c' =>  new Map<String, Boolean> {
                'READ' => true,
                'WRITE' => true
        }
};


List<PermissionSet> permissionSetsToGetUpdated =  [SELECT Label, PermissionsTransferAnyLead, Id,
(SELECT SobjectType, PermissionsRead FROM ObjectPerms),
(SELECT SobjectType, Field, ParentId, PermissionsRead, PermissionsEdit FROM FieldPerms WHERE Field IN: fieldsToBeAdjustedMap.keySet()),
(SELECT AssigneeId,Assignee.Name FROM Assignments)
FROM PermissionSet WHERE Name in : permissionSetNamesToAdjustFieldsFor];


List<FieldPermissions> fieldPermissionsToUpdate = new List<FieldPermissions>();

for (PermissionSet perm : permissionSetsToGetUpdated) {
    fieldPermissionsToUpdate.addAll(adjustPermissionByFlag(perm.FieldPerms, fieldsToBeAdjustedMap, perm));
}

upsert fieldPermissionsToUpdate;


/////////////////////////////
private List<FieldPermissions> adjustPermissionByFlag(List<FieldPermissions> fieldPermsToClone, Map<String, Map<String, Boolean>> fieldsToBeAdjustedMap, PermissionSet permSet) {
    
    List<FieldPermissions> fieldPermissionsToUpdate = new List<FieldPermissions>();

    for (String newFieldToReceivePerm : fieldsToBeAdjustedMap.keySet()) {

        List<String> existingPermissionsModified = new List<String>();
        if (fieldPermsToClone.size() > 0 ) {
            
            for (FieldPermissions fieldPermission : fieldPermsToClone) {
                
                Boolean readValue = fieldsToBeAdjustedMap.get(fieldPermission.Field).get('READ');
                Boolean writeValue = fieldsToBeAdjustedMap.get(fieldPermission.Field).get('WRITE');

                if (fieldsToBeAdjustedMap.get(fieldPermission.Field) != NULL) {

                    fieldPermission.PermissionsRead = readValue;
                    fieldPermission.PermissionsEdit = writeValue;
                    existingPermissionsModified.add(newFieldToReceivePerm);
                    fieldPermissionsToUpdate.add(fieldPermission);
                }


            }
        }

        for (String fieldToUpsertPermission : fieldsToBeAdjustedMap.keySet()) {
            
            if (!existingPermissionsModified.contains(fieldToUpsertPermission) ) {
                fieldPermissionsToUpdate.add(createNewFieldPermissionByPermissionSetAndField(permSet, fieldToUpsertPermission, fieldsToBeAdjustedMap.get(fieldToUpsertPermission) ));
            }
            
        }

       
    }

    return fieldPermissionsToUpdate;
}



public FieldPermissions createNewFieldPermissionByPermissionSetAndField(PermissionSet permSet, String fieldToCreateNewPermissionsFor, Map<String, Boolean> readWriteSettingToValueMap) {

    Boolean readValue = readWriteSettingToValueMap.get('READ');
    Boolean writeValue = readWriteSettingToValueMap.get('WRITE');
    
    String expectedDelimiter = '.';
    String newsobjectTypeOfField = fieldToCreateNewPermissionsFor.substringBefore(expectedDelimiter); 

    FieldPermissions newfp = new FieldPermissions();
    newfp.ParentId = permSet.Id;
    newfp.Field = fieldToCreateNewPermissionsFor;
    newfp.SobjectType = newsobjectTypeOfField;
    newfp.PermissionsRead = readValue;
    newfp.PermissionsEdit = writeValue;
    
    return newfp;

}

