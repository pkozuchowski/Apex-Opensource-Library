# Schema Constants

How to elegantly store schema constants?  
One way is, of course, through Constants class, but that might lead to lengthy and unhandy invocations and mixing in caching logic.  
A much more elegant way is to expose schema constants through small dedicated and lazily evaluated classes, 
that are named after schema in plural form:

```apex
public with sharing class Profiles {
    public static Profile SystemAdministrator { get {return resolve('System Administrator');} }
    public static Profile StandardUser { get {return resolve('Standard User');} }
    public static Profile Dealer { get {return resolve('Dealer');} }
    public static Profile SalesManager { get {return resolve('Sales Manager');} }

    private static Profile resolve(String name) {
        // lazy evaluation
        return cache.get(name);
    }

    //lazy evaluation example in static map, but Platform Cache would be much better and more performant
    private static Map<String, Profile> cache = new Map<String, Profile>();
    static {
        for (Profile p : [SELECT Id, Name FROM Profile]) {
            cache.put(p.Name, p);
        }
    }
}

public with sharing class PermissionSets {
    public static PermissionSet CommerceUser    { get {return resolve('CommerceUser');} }
    public static PermissionSet ManageOrders    { get {return resolve('ManageOrders');} }
    public static PermissionSet ManageAccounts  { get {return resolve('ManageAccounts');} }
    public static PermissionSet ManageContacts  { get {return resolve('ManageContacts');} }


    private static PermissionSet resolve(String name) {
        //lazy evaluation - see Profile example
    }
}

public with sharing class RecordTypes {
    public static RecordType ACCOUNT_SMB          { get {return resolve(Account.SObjectType, 'SMB');} }
    public static RecordType ACCOUNT_CUSTOMER     { get {return resolve(Account.SObjectType, 'Customer');} }


    private static Map<SObjectType, Map<String,  RecordType>> recordTypeCache = new Map<SObjectType, Map<String,  RecordType>>();
    private static  RecordType resolve(SObjectType sObjectType, String developerName) {
        // lazy evaluation code
    }
}
```

Then we can easily access our constants in verbose fashion:
```apex
Profiles.SystemAdministrator.Id;
if(UserInfo.getProfileId() = Profiles.SystemAdministrator.Id)

RecordTypes.Account.SMB.Id;
if(account.RecordTypeId == RecordTypes.Account.SMB.Id){}

PermissionSets.ManageOrders.Id;

Boolean hasPermission = CustomPermissions.MyPermission;


// or depending on used notion, it can follow Java Constants convention 
Profiles.SYSTEM_ADMINISTRATOR.Id;
RecordTypes.ACCOUNT_SMB.Id;
```

Instead of returning entire SObject, the classes can be simplified to return only Id, as it should suffice in most of the cases.

You can find example implementations using the Query framework that does the caching for you in the [Schema folder.](../force-app/commons/schema)
```apex
public with sharing class Profiles {
    public static Profile SYSTEM_ADMINISTRATOR  { get {return resolve('System Administrator');} }
    public static Profile STANDARD_USER         { get {return resolve('Standard User');} }

    private static Profile resolve(String name) {
        return (Profile) Query.Profiles
            .byName(name)
            .usingCache(true)
            .getFirstOrNull();
    }
}
```
