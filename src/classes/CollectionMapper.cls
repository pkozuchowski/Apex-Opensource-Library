/**
* MIT License
*
* Copyright (c) 2018 Piotr Kożuchowski <piotr.b.kozuchowski@gmail.com>
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
    * Maps SObject collection by SObject field.
    * */
    public virtual class ByField implements Collection.KeyMapper {
        private String field;
        private Type keyType;

        public ByField(Type keyType, String field) {
            this.keyType = keyType;
            this.field = field;
        }

        public ByField(SObjectField field) {
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


    /**
    * Maps collection by pair of fields and separator. ex.
    * Junction object by both parent fields.
    * This mapper will always map by String key.
    *
    * @example
    * <pre>
    *       Map<String, JunctionObject> junctionRecordsByParents =
    *           Collection.mapBy(junctionRecords,
    *               new CollectionMapper.ByFieldPair(JunctionObject.ParentId1, '_', JunctionObject.ParentId2)
    *           );
    * </pre>
    * */
    public virtual class ByFieldPair implements Collection.KeyMapper {
        private String fieldLeft;
        private String fieldRight;
        private String separator = '';

        public ByFieldPair(SObjectField fieldLeft, String separator, SObjectField fieldRight) {
            this('' + fieldLeft, separator, '' + fieldRight);
        }

        public ByFieldPair(String fieldLeft, String separator, String fieldRight) {
            this.separator = separator;
            this.fieldLeft = fieldLeft;
            this.fieldRight = fieldRight;
        }

        public Object key(Object item) {
            return ((SObject) item).get(fieldLeft) + separator + ((SObject) item).get(fieldRight);
        }

        public Type keyType() {
            return String.class;
        }
    }


    /**
    * Mapper implementation which uses given KeyMapper for producing key,
    * and returns collection item as mapped value.
    * */
    public class ByKeyMapper implements Collection.Mapper {
        private Collection.KeyMapper keyMapper;
        private Type valueType;

        public ByKeyMapper(Collection.KeyMapper keyMapper, Type valueType) {
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