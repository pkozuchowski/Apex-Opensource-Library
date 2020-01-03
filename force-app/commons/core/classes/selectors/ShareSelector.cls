/**
 * @description
 * 
 * @author 
 * @date 2020-01-01
 */

public with sharing class ShareSelector extends Selector {
    private SObjectField parentField;

    public ShareSelector(SObjectType shareObjectType) {
        super(
                shareObjectType.getDescribe().fields.getMap().values(),
                shareObjectType
        );

        initializeParentField(shareObjectType);
    }

    /**
     * Share fields do not have consistent naming convention.
     * This method checks for ParentId field.
     */
    private void initializeParentField(SObjectType shareObjectType) {
        Map<String, SObjectField> fields = shareObjectType.getDescribe().fields.getMap();

        if (fields.containsKey('ParentId')) {
            parentField = fields.get('ParentId');
        } else {
            Set<String> excluded = new Set<String>{
                    'id', 'lastmodifiedbyid', 'userorgroupid'
            };

            for (String field : fields.keySet()) {
                if (!excluded.contains(field) && field.endsWith('id')) {
                    parentField = fields.get(field);
                }
            }
        }
    }

    /**
     * @param userOrGroupIds List<Id> or (Iterable<Id>) Set<Id> of users or groups (queues)
     * @return Share records for given users
     */
    public SObject[] byUserOrGroupIds(Iterable<Id> userOrGroupIds) {
        query.setWhere('UserOrGroupId IN :userOrGroupIds');
        return Database.query(query.build());
    }

    /**
     * @param parentIds List<Id> or (Iterable<Id>) Set<Id> of records
     * @return Share records for given records
     */
    public SObject[] byParentIds(Iterable<Id> parentIds) {
        query.setWhere('' + parentField + ' IN :parentIds');
        return Database.query(query.build());
    }

    /**
     * @param parentIds List<Id> or (Iterable<Id>) Set<Id> of records
     * @param userOrGroupIds List<Id> or (Iterable<Id>) Set<Id> of users or groups (queues)
     * @return Share records for given records and users
     */
    public SObject[] byParentIdsAndUserOrGroupIds(Iterable<Id> parentIds, Iterable<Id> userOrGroupIds) {
        query.setWhere('' + parentField + ' IN :parentIds AND UserOrGroupId IN :userOrGroupIds');
        return Database.query(query.build());
    }
}