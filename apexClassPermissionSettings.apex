// If using Manual List:
// search org for "@AuraEnabled"
// make note of all classes that belong to your app that compe up in the results
// add to String list varialbe "apiNamesOfClassesToAddAccessTo"

// to test:
// turn on critical update, login as user with targeted permission set and try to initiate call to AuraEnabled method.  Should receive error modal with red background colored header immediately.
// run script
// retest method call

String classNameAppPrefix = 'APPNAME';
Boolean useManualList = true;

List<String> apiNamesOfClassesToAddAccessTo = new List<String>{
        'Error_Logger',
        'SearchController'
};

List<String> permissionSetsNeedingAccess = new List<String>{
        'Tier_One_User',
        'Tier_Two_User'
};

Map<Id, PermissionSet> mapPermissionSets = new Map<Id, PermissionSet> (
    [
        Select Id, Name from PermissionSet where Name in:permissionSetsNeedingAccess
    ]
);

Map<Id, ApexClass> mapApexClasses;
if (useManualList) {
    mapApexClasses = new Map<Id, Apexclass>(
            [
                    SELECT Id, Name
                    FROM ApexClass
                    where Name in:apiNamesOfClassesToAddAccessTo
            ]
    );
} else {
    String wildCardOfAppPrefix = '%' + classNameAppPrefix + '%';
            mapApexClasses = new Map<Id, Apexclass>(
            [
                    SELECT Id, Name
                    FROM ApexClass
                    where Name LIKE :wildCardOfAppPrefix
            ]
    );
}


List<SetupEntityAccess> setupEntityAccesses = new List<SetupEntityAccess>();
for (PermissionSet permSet : mapPermissionSets.values()) {
    for (ApexClass apxClass : mapApexClasses.values()) {
            SetupEntityAccess accessSetup = new SetupEntityAccess(
                    ParentId = permSet.Id,
                    SetupEntityId = apxClass.Id
            );

            setupEntityAccesses.add(accessSetup);
    }
}

List<Database.SaveResult> saveResults = Database.insert(setupEntityAccesses, false); 
System.debug(LoggingLevel.ERROR, 'HERE IS saveResults amount: ' + saveResults.size() );

for (Integer i = 0; i < setupEntityAccesses.size(); i++) {
    Database.SaveResult saveResult = saveResults[i];
    SetupEntityAccess supAccess = setupEntityAccesses[i];
    if (!saveResult.isSuccess()) {
        System.debug(LoggingLevel.ERROR, 'HERE IS the Class and PermSet combo that failed:' + 'Apex Class - ' + mapApexClasses.get(supAccess.SetupEntityId).Name + ' : PermSet - ' + mapPermissionSets.get(supAccess.ParentId).Name  );
        for(Database.Error err : saveResult.getErrors()) {
            System.debug('Status Code: ' + err.getStatusCode() + ': Error Message' + err.getMessage());
        }
    }
}



///////////////////////////////////////////////

// for testing purposes //
/// TO DELETE ////
List<String> apiNamesOfClassesToAddAccessTo = new List<String>{
        'Error_Logger',
        'SearchController'
};

Map<Id, Apexclass> mapApexClasses = new Map<Id, Apexclass>(
    [
        Select Id, Name from Apexclass where Name in:apiNamesOfClassesToAddAccessTo
    ]
);

List<String> permissionSetsNeedingAccess = new List<String>{
        'Tier_One_User',
        'Tier_Two_User'
};
Map<Id, PermissionSet> mapPermissionSets = new Map<Id, PermissionSet> (
   [
        Select Id, Name from PermissionSet where Name in:permissionSetsNeedingAccess
   ]
);

List<SetupEntityAccess> setupEntityAccessesToDelete = [
  SELECT Id, Parent.Name, SetupEntityId
  FROM SetupEntityAccess
        WHERE ParentId IN :mapPermissionSets.keySet()
        AND SetupEntityId IN: mapApexClasses.keySet()
];

for (SetupEntityAccess access : setupEntityAccessesToDelete) {
    System.debug(LoggingLevel.ERROR, 'HERE BE access name: ' + access.Parent.Name); 
    System.debug(LoggingLevel.ERROR, 'HERE BE the clas: ' + access.SetupEntityId);
}

delete setupEntityAccessesToDelete;
 

///// END DELETE ///



////////////////////////////////////////////////////////////////////////
