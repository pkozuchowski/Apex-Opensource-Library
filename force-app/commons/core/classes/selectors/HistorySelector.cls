public with sharing class HistorySelector extends Selector {
    private SObjectField parentField;

    public HistorySelector(SObjectType shareObjectType) {
        super(
                shareObjectType.getDescribe().fields.getMap().values(),
                shareObjectType
        );

        initializeParentField(shareObjectType);
    }

    /**
     * History fields do not have consistent naming convention.
     * This method checks for ParentId field.
     */
    private void initializeParentField(SObjectType shareObjectType) {
        Map<String, SObjectField> fields = shareObjectType.getDescribe().fields.getMap();

        if (fields.containsKey('ParentId')) {
            parentField = fields.get('ParentId');
        } else {
            Set<String> excluded = new Set<String>{
                    'id', 'lastmodifiedbyid', 'createdbyid'
            };

            for (String field : fields.keySet()) {
                if (!excluded.contains(field) && field.endsWith('id')) {
                    parentField = fields.get(field);
                }
            }
        }
    }


    /**
     * @param parentIds List<Id> or (Iterable<Id>) Set<Id> of records
     * @return Share records for given records
     */
    public SObject[] byParentIds(Iterable<Id> parentIds) {
        query.setWhere('' + parentField + ' IN :parentIds');
        return Database.query(query.build());
    }
}