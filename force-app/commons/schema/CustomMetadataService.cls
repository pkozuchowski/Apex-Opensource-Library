/**
* MIT License
*
* Copyright (c) 2020 Piotr Kożuchowski
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

/**
* Utility class which deploys custom metadata records to org.
*/
public with sharing class CustomMetadataService {

    /**
    * Deploys list of Custom Metadata records to org.
    * This method can be copy-pasted into Anonymous Apex script and used without deploying this class
    *
    * Example:
    * <pre>
    *     CustomMetadataDeployer.deploy(new List<SomeMapping__mdt>{
    *           new SomeMapping__mdt(DeveloperName='X', Label='X', Field__c='X),
    *           new SomeMapping__mdt(DeveloperName='Y', Label='Y', Field__c='Y),
    *     });
    * </pre>
    *
    * @param customMetadataRecords List of Custom Metadata records. DeveloperName and Label fields are required.
    * @return ID of deployment request.
    */
    public static Id deploy(List<SObject> customMetadataRecords) {
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();

        for (SObject record : customMetadataRecords) {
            Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
            customMetadata.fullName = ('' + record.getSObjectType()).remove('__mdt') + '.' + record.get('DeveloperName');
            customMetadata.label = (String) record.get('Label');

            Map<String, Object> populatedFields = record.getPopulatedFieldsAsMap().clone();
            populatedFields.remove('Id');
            populatedFields.remove('Label');
            populatedFields.remove('DeveloperName');

            for (String field : populatedFields.keySet()) {
                Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
                customField.field = field;
                customField.value = populatedFields.get(field);

                customMetadata.values.add(customField);
            }

            mdContainer.addMetadata(customMetadata);
        }

        return Metadata.Operations.enqueueDeployment(mdContainer, null);
    }
}