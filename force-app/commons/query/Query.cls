/**
* MIT License
*
* Copyright (c) 2019 Piotr Kożuchowski
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
 * Main interface of the Query framework.
 * Use this class to create Queries without concrete selector class, mock queries or construct Query wrapper.
 */
@SuppressWarnings('PMD')
@JsonAccess(Serializable='never' Deserializable='never')
public inherited sharing virtual class Query {

    /**
     * @return Query instance for generic SObjectType
     * @deprecated Use {@link Query#of(SObjectType)} instead.
     */
    public static QueryObject fromSObject(SObjectType sObjectType) {
        return new QueryObject(sObjectType);
    }


    /**
     * @return Query instance for generic SObjectType
     */
    public static QueryObject of(SObjectType sObjectType) {
        return new QueryObject(sObjectType);
    }

    /**
     * This method takes the query directly, but returns mock if needed.
     * It's more realistic than full mocking, since access can be validated and limits are more realistic.
     */
    public static QueryResults of(List<SObject> results) {
        return new QueryResults(results);
    }

    /**
     * Mocks query result using either mockId or client's class name and method.

     * In unit tests:
     * <pre>
     *     Query.mock(AccountQuotingService.class, 'generateQuotes', new List<Account>{...});
     * </pre>
    */
    public static void mock(Type className, String methodName, List<SObject> result) {
        mock(className.getName() + '.' + methodName, result);
    }

    /**
     * Mocks query result using either mockId or client's class name and method.
    */
    public static void mock(String mockIdOrClientName, List<SObject> result) {
        if (result.getSObjectType() == null) {
            QueryResults.mock(mockIdOrClientName, result);
        } else {
            mock(result.getSObjectType(), mockIdOrClientName, result);
        }
    }

    /**
     * Mocks Aggregated Results using either mockId or client's class name and method.
     * Important! This is intended to use with QueryObject.getAggregateResult() method,
     * which returns List<Query.AggregateResult>;
     */
    public static void mock(String mockIdOrClientName, List<Query.AggregateResult> result) {
        QueryResults.mock(Schema.AggregateResult.SObjectType, mockIdOrClientName, result);
    }


    /**
     * Mocks query result using client's class name and method.
    */
    public static void mock(SObjectType sobjType, Type className, String methodName, Object result) {
        mock(sobjType, className.getName() + '.' + methodName, result);
    }

    /**
     * Mocks query result using either mockId or client's class name and method.
    */
    public static void mock(SObjectType sobjType, String mockIdOrClientName, Object result) {
        QueryResults.mock(sobjType, mockIdOrClientName, result);
    }

    /**
     * Wrapper for Schema.AggregateResult to allow mocking and value setting.
     */
    public with sharing virtual class AggregateResult {
        private Schema.AggregateResult result;
        private Map<String, Object> values = new Map<String, Object>();

        public AggregateResult() {}

        public AggregateResult(Map<String, Object> values) {
            this.values = values;
        }

        public AggregateResult(Schema.AggregateResult result) {
            this.result = result;
        }

        public virtual Object get(String fieldName) {
            return values?.get(fieldName) ?? result?.get(fieldName);
        }

        public Query.AggregateResult put(String fieldName, Object value) {
            values = values ?? new Map<String, Object>();
            values.put(fieldName, value);
            return this;
        }
    }


    /**
     * Use this class to mock subqueries and read-only fields,
     * such as system fields, formula fields or relationship fields.
     */
    public class MockSObject {
        private SObjectType sObjectType;
        private Map<String, Object> fields = new Map<String, Object>();

        public MockSObject(SObject record) {
            this.sObjectType = record.getSObjectType();
            this.fields = record.getPopulatedFieldsAsMap().clone();
        }

        public MockSObject put(String fieldName, Object value) {
            fields.put(fieldName, value);
            return this;
        }

        public MockSObject put(String fieldName, List<SObject> value) {
            fields.put(fieldName, new Map<String, Object>{
                'done' => true,
                'size' => value.size(),
                'records' => value
            });
            return this;
        }

        public SObject build() {
            return (SObject) JSON.deserialize(
                JSON.serialize(fields),
                Type.forName('' + sObjectType)
            );
        }
    }
}