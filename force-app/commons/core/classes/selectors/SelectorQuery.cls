public with sharing class SelectorQuery {
    private static String
            SYNTAX_SELECT = 'SELECT',
            SYNTAX_FROM = 'FROM',
            SYNTAX_WHERE = 'WHERE',
            SYNTAX_GROUP_BY = 'GROUP BY',
            SYNTAX_HAVING = 'HAVING',
            SYNTAX_ORDER_BY = 'ORDER BY',
            SYNTAX_LIMIT = 'LIMIT',
            SYNTAX_OFFSET = 'OFFSET';

    private Set<String> fields;
    private String fromObject = '';
    private String orderBy = '';
    private String groupBy = '';
    private String havingConditions = '';
    private String whereConditions = '';
    private String limitQueryPart = '';
    private String offsetQueryPart = '';


    public SelectorQuery() {
        this.fields = new Set<String>{};
    }

    public String build() {
        String fieldsQueryPart = SYNTAX_SELECT + ' ' + String.join(new List<String>(fields), ', ');

        String[] query = new String[]{
                fieldsQueryPart,
                fromObject,
                whereConditions,
                groupBy,
                havingConditions,
                orderBy,
                limitQueryPart,
                offsetQueryPart
        };


        return String.join(query, ' ').trim();
    }


    public SelectorQuery selectField(SObjectField field) {
        this.fields.add('' + field);
        return this;
    }

    public SelectorQuery selectField(String field) {
        this.fields.add(field);
        return this;
    }

    public SelectorQuery selectFields(SObjectField[] fields) {
        for (SObjectField sObjectField : fields) {
            this.fields.add('' + sObjectField);
        }
        return this;
    }

    public SelectorQuery selectFields(String[] fields) {
        this.fields.addAll(fields);
        return this;
    }


    public SelectorQuery addSubquery(SelectorQuery subqueryBuilder) {
        String subQuery = String.join(
                new String[]{
                        '(', subqueryBuilder.build(), ')'
                }, ' ');

        this.fields.add(subQuery);
        return this;
    }

    public SelectorQuery addChildFields(List<SObjectField> fields, String relationshipField) {
        return addSubquery(new SelectorQuery()
                .selectFields(fields)
                .fromObject(relationshipField)
        );
    }

    public SelectorQuery addParentFields(List<SObjectField> fields, SObjectField relationshipField) {
        String relation = relationshipField.getDescribe().getRelationshipName() + '.';

        for (SObjectField field : fields) {
            selectField(relation + field);
        }

        return this;
    }

    public SelectorQuery fromObject(SObjectType fromObject) {
        return fromObject('' + fromObject);
    }

    public SelectorQuery fromObject(String fromObject) {
        this.fromObject = SYNTAX_FROM + ' ' + fromObject;
        return this;
    }


    public SelectorQuery setWhere(String condition) {
        this.whereConditions = SYNTAX_WHERE + ' ' + condition;
        return this;
    }

    public SelectorQuery setGroupBy(String groupBy) {
        this.groupBy = SYNTAX_GROUP_BY + ' ' + groupBy;
        return this;
    }

    public SelectorQuery setHaving(String havingConditionExpression) {
        this.havingConditions = SYNTAX_HAVING + ' ' + havingConditionExpression;
        return this;
    }

    public SelectorQuery setOrderBy(String orderBy) {
        this.orderBy = SYNTAX_ORDER_BY + ' ' + orderBy;
        return this;
    }

    public SelectorQuery setLimit(Integer limitOf) {
        this.limitQueryPart = SYNTAX_LIMIT + ' ' + String.valueOf(limitOf);
        return this;
    }

    public SelectorQuery setOffset(Integer offsetOf) {
        this.offsetQueryPart = SYNTAX_OFFSET + ' ' + String.valueOf(offsetOf);
        return this;
    }
}