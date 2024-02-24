# Setup Object Constants
*How to store and reference Setup Objects*

[Source](https://github.com/pkozuchowski/Apex-Opensource-Library/tree/master/force-app/commons/constants)

```bash
sf project deploy start -d force-app/commons/constants -o sfdxOrg
```

---
# Documentation
Setup Object constants are, for example, names and ids of Profiles, Permission Sets, Custom Permissions, Record Types and other setup entities.

How to elegantly store setup object constants?  
One way is, of course, through Constants class, but that might lead to lengthy and unhandy invocations and mixins of caching mechanisms.  
A better way is to expose schema constants through small, dedicated and lazily evaluated classes, that are named after schema in plural form.


## Profiles

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

	// Example of lazy evaluation and caching in static map,
	// but Platform Cache would be much better and more performant.
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

**Note:** We shouldn't define profile names additionally in Constants, because `Profiles` will be the only place that should have profile name as string.  
All other classes will reference profile through this class.

## Permission Sets

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

## Record Types
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

## Permissions

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

## Coexistence with the Query framework

Query Framework has a configurable caching mechanism in-built and can be leveraged in Schema Constants classes.  
Cache can be configured to store values in Platform Cache (Organization/Session) or in static map during transaction.

```apex
public with sharing class Profiles {
	public static Profile SystemAdministrator { get {return resolve('System Administrator');} }
	public static Profile StandardUser { get {return resolve('Standard User');} }


	private static Profile resolve(String name) {
		return (Profile) Query.Profiles.byName(name).getFirstOrNull();
	}
}
```