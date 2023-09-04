# Setup Object Constants
*How to store and reference Setup Objects*

---
## Documentation
Setup Object constants are, for example, names and ids of Profiles, Permission Sets, Custom Permissions, Record Types and other setup entities.   

How to elegantly store setup object constants?  
One way is, of course, through Constants class, but that might lead to lengthy and unhandy invocations and mixins of caching mechanisms.  
A much more elegant way is to expose schema constants through small, dedicated and lazily evaluated classes, that are named after schema in plural form.


### Profiles

```apex
public with sharing class Profiles {
    public static Profile SystemAdministrator { get {return resolve('System Administrator');} }
    public static Profile StandardUser        { get {return resolve('Standard User');} }
    public static Profile Dealer              { get {return resolve('Dealer');} }
    public static Profile SalesManager        { get {return resolve('Sales Manager');} }

    private static Profile resolve(String name) {
        // lazy evaluation
        return cache.get(name);
    }

    //example of lazy evaluation and caching in static map, but Platform Cache would be much better and more performant
    private static Map<String, Profile> cache = new Map<String, Profile>();
    static {
        for (Profile p : [SELECT Id, Name FROM Profile]) {
            cache.put(p.Name, p);
        }
    }
}
```

```apex
if (UserInfo.getProfileId() == Profiles.SystemAdministrator.Id) {
    //...
}
```

Note that we shouldn't define profile names in Constants, because `Profiles` will be the only place that should have profile name as string.  
All other classes will reference profile through this class.

<details>
    <summary>Permission Sets</summary>

```apex
public with sharing class PermissionSets {
    public static PermissionSet CommerceUser { get {return resolve('CommerceUser');} }
    public static PermissionSet ManageOrders { get {return resolve('ManageOrders');} }
    public static PermissionSet ManageAccounts { get {return resolve('ManageAccounts');} }
    public static PermissionSet ManageContacts { get {return resolve('ManageContacts');} }


    private static PermissionSet resolve(String name) {
        //lazy evaluation - see Profiles example
    }
}
```
</details>


<details>
    <summary>Record Types</summary>

Instead of returning entire SObject, the classes can be simplified to return only Record Type's Id, as it should suffice in most of the cases.

```apex
public with sharing class RecordTypes {
    public static RecordType ACCOUNT_SMB { get {return resolve(Account.SObjectType, 'SMB');} }
    public static RecordType ACCOUNT_CUSTOMER { get {return resolve(Account.SObjectType, 'Customer');} }


    private static Map<SObjectType, Map<String, RecordType>> recordTypeCache = new Map<SObjectType, Map<String, RecordType>>();
    private static RecordType resolve(SObjectType sObjectType, String developerName) {
        // lazy evaluation code
    }
}
```

```apex
if (account.RecordTypeId == RecordTypes.Account.SMB.Id) {
    //...
}
```
</details>


<details>
    <summary>Permissions</summary>

Expose Custom Permissions to your apex code, either directly through FeatureManagement class or custom feature flag framework.

```apex
public with sharing class Permissions {
    public static Boolean SeeInvoices { get {return resolve('SeeInvoices');} }
    public static Boolean ModifyInvoices { get {return resolve('ModifyInvoices');} }

    private static Boolean resolve(String customPermission) {
        return FeatureManagement.checkPermission(customPermission);
    }
}
```

```apex
if (Permissions.SeeInvoices) {
    //..
}
```
</details>


<details>
    <summary>Coexistence with Query framework</summary>

Query Framework has a configurable caching mechanism in-built and can be leveraged in Schema Constants classes.  
Cache can be configured to store values in Platform Cache (Organization/Session) or in static map during transaction.

```apex
public with sharing class Profiles {
    public static Profile SystemAdministrator  { get {return resolve('System Administrator');} }
    public static Profile StandardUser         { get {return resolve('Standard User');} }


    private static Profile resolve(String name) {
        return (Profile) Query.Profiles.byName(name).getFirstOrNull();
    }
}
```
</details>