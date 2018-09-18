public class CollectionMapper {
    private final static Map<Schema.SoapType, Type> FIELD_TYPE_MAP = new Map<SoapType, Type>{
            Schema.SoapType.ID => Id.class,
            Schema.SoapType.INTEGER => Integer.class,
            Schema.SoapType.BOOLEAN => Boolean.class,
            Schema.SoapType.DATE => Date.class,
            Schema.SoapType.DATETIME => Datetime.class,
            Schema.SoapType.DOUBLE => Decimal.class,
            Schema.SoapType.STRING => String.class,
            Schema.SoapType.TIME => Time.class
    };

    public static Type getSObjectFieldType(SObjectField field) {
        return FIELD_TYPE_MAP.get(field.getDescribe().getSoapType());
    }


    /**
      * Key mapper where key is SObject field.
      */
    public virtual class SObjectFieldKeyMapper implements Collection.KeyMapper {
        private String field;
        private Type keyType;

        public SObjectFieldKeyMapper(Type keyType, String field) {
            this.keyType = keyType;
            this.field = field;
        }

        public SObjectFieldKeyMapper(SObjectField field) {
            this.keyType = getSObjectFieldType(field);
            this.field = '' + field;
        }

        public Object key(Object item) {
            return ((SObject) item).get(field);
        }

        public Type keyType() {
            return keyType;
        }
    }


    public class MapperWithKeyMapper implements Collection.Mapper {
        private Collection.KeyMapper keyMapper;
        private Type valueType;

        public MapperWithKeyMapper(Collection.KeyMapper keyMapper, Type valueType) {
            this.keyMapper = keyMapper;
            this.valueType = valueType;
        }

        public Type keyType() {
            return keyMapper.keyType();
        }

        public Type valueType() {
            return valueType;
        }

        public Object key(Object item) {
            return keyMapper.key(item);
        }

        public Object value(Object item) {
            return item;
        }
    }
}