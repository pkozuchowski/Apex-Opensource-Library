# Secure Auth. Provider Secrets
*How to store secrets securely in custom Auth. Providers*


---
# Article

In this article, I will try to explain how Auth. Provider secrets can be stored securely in Salesforce.

## The Problem
When we create and configure custom Auth. Provider, according to Salesforce documentation, we will create a new custom metadata to store all parameters.
Typically, these parameters would like this:
- Authorization Endpoint Url
- Token Endpoint Url
- Consumer Key / Client ID
- Consumer Secret / Client Secret
- Scope

The result of such configuration will be Auth Provider page, which will look like this:
![img_1.png](/img/auth-provider-1.png)

Now, the problem is that all the above fields are text fields - Custom Metadata does not have a concept of secret field.  
Any Salesforce Admin or anyone
with `Customize Application` permission can look up Client Id
and Client Secret and use them for malicious purposes. Even worse if that person leaves the company knowing these secrets. There's no telling who knows these
secrets.

## Solution
To circumvent this situation, we will move these secrets to different storage: External Credential.

### External Credential
First, we will create an External Credential with Custom authentication protocol. This will be our safe storage for secrets - what's stored here is not
visible to anyone.

Our Secrets go to Principals -> Authentication Parameters. We can define many secrets this way.  
Note down parameter name, we will need it in a moment.
![img_2.png](/img/auth-provider-2.png)

### Note!
Running User must have assigned Permission Set with External Credential Principal enabled and Read permission to UserExternalCredential object.

### Named Credential
Secondly, we will create a Named Credential connected to External Credential. It is essential to check `Allow Formulas in HTTP Body`. We don't
need `Generate Authorization Header` though.
![img_3.png](/img/auth-provider-3.png)

### Auth. Provider
Thirdly, we will change Auth. Provider to use Named Credential. Secrets use special merge field that will be replaced by Named
Credential - `{!$Credential.Microsoft.ClientSecret}`.
- `.Microsoft.` is Developer Name of External Credential. It has to be External Credential linked to our Named Credential
- `.ClientSecret` is the name Authentication Parameter on our Principal
  ![img_4.png](/img/auth-provider-4.png)
  *Note: I left Authorization Endpoint Url, because it is returned to the browser. *

And we are done!

Our Http Request body should now look like this:
```
code=CODE
&grant_type=authorization_code
&redirect_uri=REDIRECT_URI
&client_id=CLIENT_ID
&client_secret={!$Credential.Microsoft.ClientSecret}
```

## Auth. Provider Tips
At last, just a few pointers for deploying Auth. Providers. This type of metadata usually has different configurations on different sandboxes, so it requires
some flexibility.


#### 1. Don't deploy fields you don't want to overwrite
If you don't want to have your values overwritten on deployment, just remove them from the repository. You can deploy blank Auth. Provider to org, fill the
details once and never touch it again. Or don't include metadata record at all.

The tip inside a tip here is to not make any of the fields required. Just save yourself trouble.

No substitutions, no CI/CD environments, no trouble.
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>MyAuthProvider</label>
    <protected>false</protected>
    <values>
        <field>Authorization_Endpoint_Url__c</field>
        <value xsi:type="xsd:string">https://login.microsoftonline.com/693ad9ee-7efd-43d0-a0ab-2fd666808a42/oauth2/v2.0/authorize</value>
    </values>
    <!--These fields will not be overwritten-->
    <!--    <values>-->
    <!--        <field>Client_Id__c</field>-->
    <!--        <value xsi:type="xsd:string">cfd291af-99e7-48b9-abd1-7616368b2a1c</value>-->
    <!--    </values>-->
    <!--    <values>-->
    <!--        <field>Client_Secret__c</field>-->
    <!--        <value xsi:type="xsd:string">{!$Credential.Microsoft.ClientSecret}</value>-->
    <!--    </values>-->
    <values>
        <field>Scope__c</field>
        <value xsi:type="xsd:string">openid offline_access</value>
    </values>
    <values>
        <field>Token_Endpoint_Url__c</field>
        <value xsi:type="xsd:string">callout:MicrosoftLogin/693ad9ee-7efd-43d0-a0ab-2fd666808a42/oauth2/v2.0/token</value>
    </values>
</CustomMetadata>
```

#### 2. SFDX Substitutions
You may find it useful to use substitutions, which are now inbuilt in SF CLI. In that case, you set environment variable in CI/CD runner for each environment.

In our example, we can set `AAD_TENANT_ID` as global variable in GitHub and have it replaced in Auth. Provider metadata:

```xml

<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <values>
        <field>Authorization_Endpoint_Url__c</field>
        <value xsi:type="xsd:string">https://login.microsoftonline.com/AAD_TENANT_ID/oauth2/v2.0/authorize</value>
    </values>
    <values>
        <field>Token_Endpoint_Url__c</field>
        <value xsi:type="xsd:string">callout:MicrosoftLogin/AAD_TENANT_ID/oauth2/v2.0/token</value>
    </values>
</CustomMetadata>
```

sfdx-project.json:
```json
  {
    "replacements": [
        {
            "filename": "force-app/main/default/customMetadata/MicrosoftAuthProvider.MyAuthProvider.md-meta.xml",
            "stringToReplace": "AAD_TENANT_ID",
            "replaceWithEnv": "AAD_TENANT_ID"
        }
    ]
}
```

[Link to Documentation](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_ws_string_replace.htm)


#### 3. Automatic Key Rotation
External Credential parameters can be updated
through [Connect REST API](https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_resources_named_credentials_external_credentials.htm).

In that case, there's no work required on the Salesforce side. [This article](https://learn.microsoft.com/en-us/azure/key-vault/secrets/tutorial-rotation) shows
an example implementation on Azure.
