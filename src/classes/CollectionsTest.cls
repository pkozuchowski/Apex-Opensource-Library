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
@IsTest(IsParallel=true)
private class CollectionsTest {

    private static List<Opportunity> opportunities = new List<Opportunity>{
            newOpportunity(0, new Map<String, Object>{
                    'NextStep' => 'Analysis'
            }),
            newOpportunity(1, new Map<String, Object>{
                    'NextStep' => 'Analysis'
            }),
            newOpportunity(2, new Map<String, Object>{
                    'NextStep' => 'Analysis'
            }),
            newOpportunity(3, new Map<String, Object>{
                    'NextStep' => 'Analysis'
            }),
            newOpportunity(4, new Map<String, Object>{
                    'NextStep' => 'Deal'
            }),
            newOpportunity(5, new Map<String, Object>{
                    'NextStep' => 'Deal'
            }),
            newOpportunity(6, new Map<String, Object>{
                    'NextStep' => 'Deal'
            }),
            newOpportunity(7, new Map<String, Object>{
                    'NextStep' => 'Support'
            }),
            newOpportunity(8, new Map<String, Object>{
                    'NextStep' => 'Support'
            }),
            newOpportunity(9, new Map<String, Object>{
                    'NextStep' => 'Support'
            })
    };

    /**
     * Creates new Opportunity with fields prefilled for testing Collections.
     * Opportunity is created through JSON.deserialize, because some fields are not writable through constructor.
     */
    private static Opportunity newOpportunity(Integer i, Map<String, Object> opp) {
        Map<String, Object> oppMap = new Map<String, Object>{
                'Id' => '006' + ('' + i).leftPad(12, '0'),
                'AccountId' => '001' + ('' + Math.mod(i, 3)).leftPad(12, '0'),
                'Name' => 'Test Opportunity ' + i,
                'CreatedDate' => Datetime.now().addDays(-i),
                'FiscalQuarter' => Math.mod(i, 4),
                'HasOpenActivity' => Math.mod(i, 2) == 0,
                'LastActivityDate' => Date.today().addDays(-i),
                'Probability' => 1.0 * i / 10
        };
        oppMap.putAll(opp);

        return (Opportunity) JSON.deserialize(JSON.serialize(oppMap), Opportunity.class);
    }


    /**
     *@description
     * Collections.isNotEmpty() returns "true" when there's any element in the list
     * and "false" when list is null or empty.
     */
    @IsTest
    static void testIsNotEmpty() {
        System.assertEquals(false, Collections.isNotEmpty(null));
        System.assertEquals(false, Collections.isNotEmpty(new List<String>()));
    }


    /**
     *@description
     * Collections.isEmpty() returns "true" when list is empty or when it's null.
     */
    @IsTest
    static void testIsEmpty() {
        System.assertEquals(true, Collections.isEmpty(null));
        System.assertEquals(true, Collections.isEmpty(new List<String>()));
    }


    /**
     *@description
     * Collections.cast() changes non-covariant types through JSON serialization&deserialization.
     */
    @IsTest
    static void testCast() {
        Map<Id, Account> accountById = (Map<Id, Account>) Collections.cast(new Map<String, SObject>(), Map<Id, Account>.class);
        Set<String> stringSet = (Set<String>) Collections.cast(new Set<Object>(), Set<String>.class);
        System.assert(true);
    }


    /**
     *@description
     * Collections.getListItemType() returns type of elements in given list
     */
    @IsTest
    static void testGetListItemType() {
        System.assertEquals(Account.class, Collections.getListItemType(new List<Account>()));

        List<SObject> records = new List<Opportunity>();
        System.assertEquals(Opportunity.class, Collections.getListItemType(records));
    }

    /**
     *@description
     * Collections.getType() returns type of collection or any given object.
     */
    @IsTest
    static void testGetType() {
        System.assertEquals(List<Account>.class, Collections.getType(new List<Account>()));

        List<SObject> records = new List<Opportunity>();
        System.assertEquals(List<Opportunity>.class, Collections.getType(records));
    }

    @IsTest
    static void whenCastedCollectionIsNullThenBlankInstanceOfTargetTypeIsReturned() {
        Set<Id> expected = new Set<Id>();
        Set<Id> actual = (Set<Id>) Collections.cast(null, Set<Id>.class);

        System.assertEquals(expected, actual);
    }


    /**
    * @description
    * Collections.getUniqueIdValues returns Set of Id values from given field.
    * */
    @IsTest
    static void testGetUniqueIdValues() {
        Set<Id> expected = new Set<Id>();
        for (Opportunity opp : opportunities) {
            expected.add(opp.AccountId);
        }

        Set<Id> actual = (Set<Id>) Collections.getUniqueValues(opportunities, Opportunity.AccountId);
        System.assertEquals(expected, actual);
    }

    /**
    * @description
    * Collections.getUniqueStringValues returns Set of String values from given field.
    * */
    @IsTest
    static void testGetUniqueStringValues() {
        Set<String> expected = new Set<String>();
        for (Opportunity opp : opportunities) {
            expected.add(opp.Name);
        }

        Set<String> actual = (Set<String>) Collections.getUniqueValues(opportunities, Opportunity.Name);
        System.assertEquals(expected, actual);
    }

    /**
    * @description
    * Collections.getUniqueIntegerValues returns Set of Integer values from given field.
    * */
    @IsTest
    static void testGetUniqueIntegerValues() {
        Set<Integer> expected = new Set<Integer>();
        for (Opportunity opp : opportunities) {
            expected.add(opp.FiscalQuarter);
        }

        Set<Integer> actual = (Set<Integer>) Collections.getUniqueValues(opportunities, Opportunity.FiscalQuarter);
        System.assertEquals(expected, actual);
    }

    /**
    * @description
    * Collections.getUniqueDecimalValues returns Set of Decimal values from given field.
    * */
    @IsTest
    static void testGetUniqueDecimalValues() {
        Set<Decimal> expected = new Set<Decimal>();
        for (Opportunity opp : opportunities) {
            expected.add(opp.Probability);
        }

        Set<Decimal> actual = (Set<Decimal>) Collections.getUniqueValues(opportunities, Opportunity.Probability);
        System.assertEquals(expected, actual);
    }

    /**
    * @description
    * Collections.getUniqueDateValues returns Set of Date values from given field.
    * */
    @IsTest
    static void testGetUniqueDateValues() {
        Set<Date> expected = new Set<Date>();
        for (Opportunity opp : opportunities) {
            expected.add(opp.LastActivityDate);
        }

        Set<Date> actual = (Set<Date>) Collections.getUniqueValues(opportunities, Opportunity.LastActivityDate);
        System.assertEquals(expected, actual);
    }

    /**
    * @description
    * Collections.getUniqueDatetimeValues returns Set of Datetime values from given field.
    * */
    @IsTest
    static void testGetUniqueDatetimeValues() {
        Set<Datetime> expected = new Set<Datetime>();
        for (Opportunity opp : opportunities) {
            expected.add(opp.CreatedDate);
        }

        Set<Datetime> actual = (Set<Datetime>) Collections.getUniqueValues(opportunities, Opportunity.CreatedDate);
        System.assertEquals(expected, actual);
    }

    /**
    * @description
    * Collections.getUniqueBooleanValues returns Set of Boolean values from given field.
    * */
    @IsTest
    static void testGetUniqueBooleanValues() {
        Set<Boolean> expected = new Set<Boolean>();
        for (Opportunity opp : opportunities) {
            expected.add(opp.HasOpenActivity);
        }

        Set<Boolean> actual = (Set<Boolean>) Collections.getUniqueValues(opportunities, Opportunity.HasOpenActivity);
        System.assertEquals(expected, actual);
    }


    /**
    * @description
    * Collections.getUniqueBooleanValues returns Set of Boolean values from given field.
    * */
    @IsTest
    static void testGetUniqueValuesByString() {
        List<SObject> records = new List<SObject>();
        records.add(new Account(Name = 'Test Account'));
        records.addAll(opportunities);

        Set<String> expected = new Set<String>();
        for (SObject record : records) {
            expected.add((String) record.get('Name'));
        }

        Set<String> actual = (Set<String>) Collections.getUniqueValues(String.class, records, 'Name');
        System.assertEquals(expected, actual);
    }


    /**
    * @description
    * Collections.getUniqueValues(KeyMapper) returns Set of Object values extracted from object by KeyMapper implementation.
    * */
    @IsTest
    static void testGetUniqueValuesKeyMapper() {
        Set<Integer> expected = new Set<Integer>{
                0, 1
        };

        Set<Integer> actual = (Set<Integer>) Collections.getUniqueValues(opportunities, new OpportunitiesByYearsHalfMapper());
        System.assertEquals(expected, actual);
    }

    /**
    * @description
    * Collections.getUniqueValues returns Set of Object values from list of given fields.
    * */
    @IsTest
    static void testGetUniqueValuesMultipleFields() {
        Set<Object> expected = new Set<Object>();
        List<SObjectField> fields = new List<SObjectField>{
                Opportunity.Probability, Opportunity.CreatedDate
        };

        for (SObjectField field : fields) {
            for (Opportunity opp : opportunities) {
                expected.add(opp.get(field));
            }
        }

        Set<Object> actual = Collections.getUniqueValues(opportunities, fields);
        System.assertEquals(
                JSON.serialize(expected),
                JSON.serialize(actual)
        );
    }


    /**
     * @description
     * Collections.mapByIdField maps SObject by given Id field.
     */
    @IsTest
    static void testMapByIdField() {
        Map<Id, Opportunity> expected = new Map<Id, Opportunity>();
        for (Opportunity opp : opportunities) {
            expected.put(opp.Id, opp);
        }

        Map<Id, Opportunity> actual = (Map<Id, Opportunity>) Collections.mapBy(opportunities, Opportunity.Id);
        System.assertEquals(expected, actual);
    }

    /**
     * @description
     * Collections.mapByStringField maps SObject by given String field.
     */
    @IsTest
    static void testMapByStringField() {
        Map<String, Opportunity> expected = new Map<String, Opportunity>();
        for (Opportunity opp : opportunities) {
            expected.put(opp.Name, opp);
        }

        Map<String, Opportunity> actual = (Map<String, Opportunity>) Collections.mapBy(opportunities, Opportunity.Name);
        System.assertEquals(expected, actual);
    }

    /**
     * @description
     * Collections.mapByStringField maps SObject by given String literal and type.
     */
    @IsTest
    static void testMapByStringLiteral() {
        List<SObject> records = new List<SObject>();
        records.add(new Account(Name = 'Test Account'));
        records.addAll(opportunities);

        Map<String, SObject> expected = new Map<String, SObject>();
        for (SObject opp : records) {
            expected.put((String) opp.get('Name'), opp);
        }

        Map<String, SObject> actual = (Map<String, SObject>) Collections.mapBy(String.class, records, 'Name');
        System.assertEquals(expected, actual);
    }

    /**
     * @description
     * Collections.mapByDecimalField maps SObject by given Decimal field.
     */
    @IsTest
    static void testMapByDecimalField() {
        Map<Decimal, Opportunity> expected = new Map<Decimal, Opportunity>();
        for (Opportunity opp : opportunities) {
            expected.put(opp.Probability, opp);
        }

        Map<Decimal, Opportunity> actual = (Map<Decimal, Opportunity>) Collections.mapBy(opportunities, Opportunity.Probability);
        System.assertEquals(expected, actual);
    }

    /**
     * @description
     * Collections.mapByIntegerField maps SObject by given Integer field.
     */
    @IsTest
    static void testMapByIntegerField() {
        Map<Integer, Opportunity> expected = new Map<Integer, Opportunity>();
        for (Opportunity opp : opportunities) {
            expected.put(opp.FiscalQuarter, opp);
        }

        Map<Integer, Opportunity> actual = (Map<Integer, Opportunity>) Collections.mapBy(opportunities, Opportunity.FiscalQuarter);
        System.assertEquals(expected, actual);
    }

    /**
     * @description
     * Collections.mapByBooleanField maps SObject by given Boolean field.
     */
    @IsTest
    static void testMapByBooleanField() {
        Map<Boolean, Opportunity> expected = new Map<Boolean, Opportunity>();
        for (Opportunity opp : opportunities) {
            expected.put(opp.HasOpenActivity, opp);
        }

        Map<Boolean, Opportunity> actual = (Map<Boolean, Opportunity>) Collections.mapBy(opportunities, Opportunity.HasOpenActivity);
        System.assertEquals(expected, actual);
    }

    /**
     * @description
     * Collections.mapByDateField maps SObject by given Date field.
     */
    @IsTest
    static void testMapByDateField() {
        Map<Date, Opportunity> expected = new Map<Date, Opportunity>();
        for (Opportunity opp : opportunities) {
            expected.put(opp.LastActivityDate, opp);
        }

        Map<Date, Opportunity> actual = (Map<Date, Opportunity>) Collections.mapBy(opportunities, Opportunity.LastActivityDate);
        System.assertEquals(expected, actual);
    }

    /**
     * @description
     * Collections.mapByDatetimeField maps SObject by given Datetime field.
     */
    @IsTest
    static void testMapByDatetimeField() {
        Map<Datetime, Opportunity> expected = new Map<Datetime, Opportunity>();
        for (Opportunity opp : opportunities) {
            expected.put(opp.CreatedDate, opp);
        }

        Map<Datetime, Opportunity> actual = (Map<Datetime, Opportunity>) Collections.mapBy(opportunities, Opportunity.CreatedDate);
        System.assertEquals(expected, actual);
    }

    /**
     * @description
     * Collections.mapBy maps SObject by KeyMapper implementation which returns Map key for each record.
     */
    @IsTest
    static void testMapByKeyMapper() {
        Map<Time, Opportunity> expected = new Map<Time, Opportunity>();
        for (Opportunity opp : opportunities) {
            expected.put(opp.CreatedDate.time(), opp);
        }

        Map<Time, Opportunity> actual = (Map<Time, Opportunity>) Collections.mapBy(opportunities, new MapByOpportunityCreateTime());
        System.assertEquals(expected, actual);
    }

    private class MapByOpportunityCreateTime implements Collections.KeyMapper {
        public Object key(Object item) {
            return ((Opportunity) item).CreatedDate.time();
        }

        public Type keyType() {
            return Time.class;
        }
    }

    /**
     * @description
     * Collections.mapBy maps collection items by Mapper implementation, which returns Map's key and value.
     */
    @IsTest
    static void testMapByMapper() {
        Map<String, Id> expected = new Map<String, Id>();
        for (Opportunity opp : opportunities) {
            expected.put('' + opp.AccountId + opp.FiscalQuarter, opp.Id);
        }

        Map<String, Id> actual = (Map<String, Id>) Collections.mapBy(opportunities, new TestMapper());
        System.assertEquals(expected, actual);
    }
    private class TestMapper implements Collections.Mapper {
        public Object key(Object item) {
            Opportunity opp = (Opportunity) item;
            return '' + opp.AccountId + opp.FiscalQuarter;
        }
        public Object value(Object item) {
            Opportunity opp = (Opportunity) item;
            return opp.Id;
        }

        public Type keyType() {
            return String.class;
        }

        public Type valueType() {
            return Id.class;
        }
    }

    @IsTest
    static void whenEmptyOpportunityListIsMappedThenEmptyOpportunityByStringMapIsReturned() {
        Map<String, Opportunity> expected = new Map<String, Opportunity>();
        Map<String, Opportunity> actual = (Map<String, Opportunity>) Collections.mapBy(new List<Opportunity>(), Opportunity.Name);
        System.assertEquals(expected, actual);
    }

    @IsTest
    static void whenEmptySObjectListIsMappedThenEmptySObjectByStringMapIsReturned() {
        Map<String, SObject> expected = new Map<String, SObject>();
        Map<String, SObject> actual = (Map<String, SObject>) Collections.mapBy(new List<SObject>(), Opportunity.Name);
        System.assertEquals(expected, actual);
    }


    /**
     * @description
     * Groups list of SObjects by given String field literal.
     * This results in Map, where keys are the field values and Map's value is a list of records
     * with the same field value.
     */
    @IsTest
    static void testGroupByStringLiteral() {
        Map<String, List<Opportunity>> expected = new Map<String, List<Opportunity>>{
                'Analysis' => new List<Opportunity>{
                        opportunities[0], opportunities[1], opportunities[2], opportunities[3]
                },
                'Deal' => new List<Opportunity>{
                        opportunities[4], opportunities[5], opportunities[6]
                },
                'Support' => new List<Opportunity>{
                        opportunities[7], opportunities[8], opportunities[9]
                }
        };
        Map<String, List<Opportunity>> actual = (Map<String, List<Opportunity>>) Collections.groupBy(String.class, opportunities, 'NextStep');

        System.assertEquals(expected, actual);
    }

    /**
     * @description
     * Groups list of SObjects by given String field.
     * This results in Map, where keys are the field values and Map's value is a list of records
     * with the same field value.
     */
    @IsTest
    static void testGroupByStringField() {
        Map<String, List<Opportunity>> expected = new Map<String, List<Opportunity>>{
                'Analysis' => new List<Opportunity>{
                        opportunities[0], opportunities[1], opportunities[2], opportunities[3]
                },
                'Deal' => new List<Opportunity>{
                        opportunities[4], opportunities[5], opportunities[6]
                },
                'Support' => new List<Opportunity>{
                        opportunities[7], opportunities[8], opportunities[9]
                }
        };
        Map<String, List<Opportunity>> actual = (Map<String, List<Opportunity>>) Collections.groupBy(opportunities, Opportunity.NextStep);

        System.assertEquals(expected, actual);
    }

    @IsTest
    static void testGroupByIdField() {
        Map<Id, List<Opportunity>> expected = new Map<Id, List<Opportunity>>{
                '001000000000000AAA' => new List<Opportunity>{
                        opportunities[0], opportunities[3], opportunities[6], opportunities[9]
                },
                '001000000000001AAA' => new List<Opportunity>{
                        opportunities[1], opportunities[4], opportunities[7]
                },
                '001000000000002AAA' => new List<Opportunity>{
                        opportunities[2], opportunities[5], opportunities[8]
                }
        };
        Map<Id, List<Opportunity>> actual = (Map<Id, List<Opportunity>>) Collections.groupBy(opportunities, Opportunity.AccountId);

        System.assertEquals(expected, actual);
    }

    @IsTest
    static void testGroupByIntegerField() {
        Map<Integer, List<Opportunity>> expected = new Map<Integer, List<Opportunity>>{
                0 => new List<Opportunity>{
                        opportunities[0], opportunities[4], opportunities[8]
                },
                1 => new List<Opportunity>{
                        opportunities[1], opportunities[5], opportunities[9]
                },
                2 => new List<Opportunity>{
                        opportunities[2], opportunities[6]
                },
                3 => new List<Opportunity>{
                        opportunities[3], opportunities[7]
                }
        };
        Map<Integer, List<Opportunity>> actual = (Map<Integer, List<Opportunity>>) Collections.groupBy(opportunities, Opportunity.FiscalQuarter);

        System.assertEquals(expected, actual);
    }

    @IsTest
    static void testGroupByDecimalField() {
        Map<Decimal, List<Opportunity>> expected = new Map<Decimal, List<Opportunity>>();
        for (Integer i = 0; i < 10; i++) {
            expected.put(1.0 * i / 10, new List<Opportunity>{
                    opportunities[i]
            });
        }
        Map<Decimal, List<Opportunity>> actual = (Map<Decimal, List<Opportunity>>) Collections.groupBy(opportunities, Opportunity.Probability);


        System.assertEquals(expected, actual);
    }

    @IsTest
    static void testGroupByDateField() {
        Map<Date, List<Opportunity>> expected = new Map<Date, List<Opportunity>>();
        for (Integer i = 0; i < 10; i++) {
            expected.put(opportunities[i].LastActivityDate, new List<Opportunity>{
                    opportunities[i]
            });
        }
        Map<Date, List<Opportunity>> actual = (Map<Date, List<Opportunity>>) Collections.groupBy(opportunities, Opportunity.LastActivityDate);


        System.assertEquals(expected, actual);
    }

    @IsTest
    static void testGroupByDatetimeField() {
        Map<Datetime, List<Opportunity>> expected = new Map<Datetime, List<Opportunity>>();
        for (Integer i = 0; i < 10; i++) {
            expected.put(opportunities[i].CreatedDate, new List<Opportunity>{
                    opportunities[i]
            });
        }
        Map<Datetime, List<Opportunity>> actual = (Map<Datetime, List<Opportunity>>) Collections.groupBy(opportunities, Opportunity.CreatedDate);


        System.assertEquals(expected, actual);
    }

    @IsTest
    static void testGroupByBooleanField() {
        Map<Boolean, List<Opportunity>> expected = new Map<Boolean, List<Opportunity>>{
                true => new List<Opportunity>{
                        opportunities[0], opportunities[2], opportunities[4], opportunities[6], opportunities[8]
                },
                false => new List<Opportunity>{
                        opportunities[1], opportunities[3], opportunities[5], opportunities[7], opportunities[9]
                }
        };
        Map<Boolean, List<Opportunity>> actual = (Map<Boolean, List<Opportunity>>) Collections.groupBy(opportunities, Opportunity.HasOpenActivity);

        System.assertEquals(expected, actual);
    }

    @IsTest
    static void testGroupByFieldByKeyMapper() {
        Map<Integer, List<Opportunity>> expected = new Map<Integer, List<Opportunity>>{
                0 => new List<Opportunity>{
                        opportunities[0], opportunities[1], opportunities[4], opportunities[5], opportunities[8], opportunities[9]
                },
                1 => new List<Opportunity>{
                        opportunities[2], opportunities[3], opportunities[6], opportunities[7]
                }
        };
        Map<Integer, List<Opportunity>> actual = (Map<Integer, List<Opportunity>>) Collections.groupBy(opportunities, new OpportunitiesByYearsHalfMapper());


        System.assertEquals(expected, actual);
    }

    private class OpportunitiesByYearsHalfMapper implements Collections.KeyMapper {
        public Object key(Object item) {
            Integer quarter = ((Opportunity) item).FiscalQuarter;
            return quarter <= 1 ? 0 : 1;
        }
        public Type keyType() {
            return Integer.class;
        }
    }


    @IsTest
    static void testGroupByFieldByMapper() {
        Map<Integer, List<OpportunityWrapper>> expected = new Map<Integer, List<OpportunityWrapper>>{
                0 => new List<OpportunityWrapper>{
                        new OpportunityWrapper(opportunities[0]),
                        new OpportunityWrapper(opportunities[1]),
                        new OpportunityWrapper(opportunities[4]),
                        new OpportunityWrapper(opportunities[5]),
                        new OpportunityWrapper(opportunities[8]),
                        new OpportunityWrapper(opportunities[9])

                },
                1 => new List<OpportunityWrapper>{
                        new OpportunityWrapper(opportunities[2]),
                        new OpportunityWrapper(opportunities[3]),
                        new OpportunityWrapper(opportunities[6]),
                        new OpportunityWrapper(opportunities[7])

                }
        };

        Map<Integer, List<OpportunityWrapper>> actual = (Map<Integer, List<OpportunityWrapper>>) Collections.groupBy(opportunities, new OppWrapperByHalfYearMapper());
    }

    private class OppWrapperByHalfYearMapper implements Collections.Mapper {
        public Type keyType() {
            return Integer.class;
        }
        public Type valueType() {
            return OpportunityWrapper.class;
        }
        public Object key(Object item) {
            Integer quarter = ((Opportunity) item).FiscalQuarter;
            return quarter <= 1 ? 0 : 1;
        }
        public Object value(Object item) {
            return new OpportunityWrapper((Opportunity) item);
        }
    }

    public class OpportunityWrapper {
        private Opportunity opportunity;

        public OpportunityWrapper(Opportunity opportunity) {
            this.opportunity = opportunity;
        }
    }

    @IsTest
    static void whenEmptyOpportunityListIsGrouppedThenEmptyOpportunityByStringMapIsReturned() {
        Map<String, List<Opportunity>> expected = new Map<String, List<Opportunity>>();
        Map<String, List<Opportunity>> actual = (Map<String, List<Opportunity>>) Collections.groupBy(new List<Opportunity>(), Opportunity.Name);
        System.assertEquals(expected, actual);
    }

    @IsTest
    static void whenEmptySObjectListIsGrouppedThenEmptySObjectByStringMapIsReturned() {
        Map<String, List<SObject>> expected = new Map<String, List<SObject>>();
        Map<String, List<SObject>> actual = (Map<String, List<SObject>>) Collections.groupBy(new List<SObject>(), Opportunity.Name);
        System.assertEquals(expected, actual);
    }


    /**
     *@description
     * Collections.filterByFieldValue filters input records and return only those which field is the same as specified value.
     */
    @IsTest
    static void testFilterByFieldValue() {
        List<Opportunity> expected = new List<Opportunity>{
                opportunities[0], opportunities[2], opportunities[4], opportunities[6], opportunities[8]
        };
        List<Opportunity> actual = Collections.filterByFieldValue(opportunities, Opportunity.HasOpenActivity, true);
        System.assertEquals(expected, actual);


        expected = new List<Opportunity>{
                opportunities[0], opportunities[4], opportunities[8]
        };
        actual = Collections.filterByFieldValue(opportunities, Opportunity.FiscalQuarter, 0);
        System.assertEquals(expected, actual);


        expected = new List<Opportunity>{
                opportunities[0], opportunities[1], opportunities[2], opportunities[3]
        };
        actual = Collections.filterByFieldValue(opportunities, Opportunity.NextStep, 'Analysis');
        System.assertEquals(expected, actual);
    }


    /**
     * @description
     * Collections.filterByFieldValues filters input records and return only those which field is one of specified values.
     */
    @IsTest
    static void testFilterByFieldValues() {
        Set<String> acceptedStages = new Set<String>{
                'Analysis', 'Deal'
        };

        List<Opportunity> expected = new List<Opportunity>();
        for (Opportunity opportunity : opportunities) {
            if (acceptedStages.contains(opportunity.StageName)) {
                expected.add(opportunity);
            }
        }

        List<Opportunity> actual = Collections.filterByFieldValues(opportunities, Opportunity.StageName, new Set<Object>{
                'Analysis', 'Deal'
        });

        System.assertEquals(expected, actual);
    }


    /**
     * @description
     * Collections.filter(UpdateFilter) takes list of Trigger.new records, trigger oldmap and UpdateFilter implementation
     * and return only these records that are accepted by Filter
     */
    @IsTest
    static void testFilterByUpdateFilter() {
        List<Opportunity> opportunities = opportunities;
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>(opportunities.deepClone(true));

        oldMap.get(opportunities[0].Id).Name += '_CHANGED';
        oldMap.get(opportunities[1].Id).Name += '_CHANGED';
        oldMap.get(opportunities[2].Id).Name += '_CHANGED';

        List<Opportunity> expected = new List<Opportunity>{
                opportunities[0],
                opportunities[1],
                opportunities[2]
        };

        List<Opportunity> actual = Collections.filter(opportunities, oldMap, new OpportunityChangedNameFilter());
        System.assertEquals(expected, actual);
    }
    private class OpportunityChangedNameFilter implements Collections.UpdateFilter {
        public Boolean accepts(Object record, Object oldRecord) {
            return ((Opportunity) record).Name != ((Opportunity) oldRecord).Name;
        }
    }


    /**
     *@description
     * Collections.reduce() reduces collection to one object or other collection using Reducer implementation.
     */
    @IsTest
    static void testReduce() {
        Set<Id> expected = new Set<Id>();
        for (Opportunity opportunity : opportunities) {
            expected.add(opportunity.Id);
            expected.add(opportunity.AccountId);
        }
        Set<Id> actual = (Set<Id>) Collections.reduce(opportunities, new ReducerToIdAndAccountId(), new Set<Id>());

        System.assertEquals(expected, actual);
    }
    private class ReducerToIdAndAccountId implements Collections.Reducer {
        public void reduce(Object aggregatedValues, Object item) {
            Set<Id> ids = (Set<Id>) aggregatedValues;
            Opportunity opp = (Opportunity) item;

            ids.add(opp.Id);
            ids.add(opp.AccountId);
        }
    }


    /**
     * @description
     * Collections.sort takes list of objects and comparator implementation.
     * Sorted list is returned as result.
     */
    @IsTest
    static void testSortByComparator() {
        List<Opportunity> expected = new List<Opportunity>();
        for (Integer i = opportunities.size() - 1; i >= 0; --i) {
            expected.add(opportunities[i]);
        }

        List<Opportunity> actual = (List<Opportunity>) Collections.sort(opportunities, new ReverseProbabilityComparator());

        System.assertEquals(actual, expected);
    }
    private class ReverseProbabilityComparator implements Collections.Comparator {
        public Integer compare(Object thisItem, Object otherItem) {
            Opportunity thisOpp = (Opportunity) thisItem;
            Opportunity otherOpp = (Opportunity) otherItem;

            if (thisOpp.Probability < otherOpp.Probability) {
                return 1;

            } else if (thisOpp.Probability > otherOpp.Probability) {
                return -1;

            } else {
                return 0;
            }
        }
    }


    /**
     * @description
     * Collections.sort sorts list of records by given field and order.
     */
    @IsTest
    static void testSortByField() {
        Opportunity previous;

        List<Opportunity> sortedOpportunities = Collections.sort(opportunities, Opportunity.CreatedDate, true);
        for (Opportunity opportunity : sortedOpportunities) {
            if (previous != null) {
                System.assert(opportunity.CreatedDate >= previous.CreatedDate);
            }
            previous = opportunity;
        }
        previous = null;


        sortedOpportunities = Collections.sort(opportunities, Opportunity.Name, false);
        for (Opportunity opportunity : sortedOpportunities) {
            if (previous != null) {
                System.assertEquals(-1, opportunity.Name.compareTo(previous.Name));
            }
            previous = opportunity;
        }
        previous = null;


        sortedOpportunities = Collections.sort(opportunities, Opportunity.FiscalQuarter, true);
        for (Opportunity opportunity : sortedOpportunities) {
            if (previous != null) {
                System.assert(opportunity.FiscalQuarter >= previous.FiscalQuarter);
            }
            previous = opportunity;
        }
        previous = null;
    }
}