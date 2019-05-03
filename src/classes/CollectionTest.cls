/**
* MIT License
*
* Copyright (c) 2018 Piotr Kożuchowski
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
private class CollectionTest {

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
                'OwnerId' => '005' + ('' + Math.mod(i, 5)).leftPad(12, '0'),
                'Name' => 'Test Opportunity ' + i,
                'CreatedDate' => Datetime.now().addDays(-i),
                'FiscalQuarter' => Math.mod(i, 4),
                'HasOpenActivity' => Math.mod(i, 2) == 0,
                'LastActivityDate' => Date.today().addDays(-i),
                'Probability' => 1.0 * i / 10,
                'Amount' => i * 100
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
        System.assertEquals(false, Collection.of(null).isNotEmpty());
        System.assertEquals(false, Collection.of(new List<String>()).isNotEmpty());
    }


    /**
     *@description
     * Collections.isEmpty() returns "true" when list is empty or when it's null.
     */
    @IsTest
    static void testIsEmpty() {
        System.assertEquals(true, Collection.of(null).isEmpty());
        System.assertEquals(true, Collection.of(new List<String>()).isEmpty());
    }


    /**
     *@description
     * Collections.cast() changes non-covariant types through JSON serialization&deserialization.
     */
    @IsTest
    static void testCast() {
        Map<Id, Account> accountById = (Map<Id, Account>) Collection.cast(new Map<String, SObject>(), Map<Id, Account>.class);
        Set<String> stringSet = (Set<String>) Collection.cast(new Set<Object>(), Set<String>.class);
        System.assert(true);
    }


    @IsTest
    static void whenCastedCollectionIsNullThenBlankInstanceOfTargetTypeIsReturned() {
        Set<Id> expected = new Set<Id>();
        Set<Id> actual = (Set<Id>) Collection.cast(null, Set<Id>.class);

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

        Set<Id> actual2 = (Set<Id>) Collection.of(opportunities).getUniqueValues(Opportunity.AccountId);
        System.assertEquals(expected, actual2);
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

        Set<String> actual2 = (Set<String>) Collection.of(opportunities).getUniqueValues(Opportunity.Name);
        System.assertEquals(expected, actual2);
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

        Set<Integer> actual2 = (Set<Integer>) Collection.of(opportunities).getUniqueValues(Opportunity.FiscalQuarter);

        System.assertEquals(expected, actual2);
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

        Set<Decimal> actual2 = (Set<Decimal>) Collection.of(opportunities).getUniqueValues(Opportunity.Probability);
        System.assertEquals(expected, actual2);
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

        Set<Date> actual2 = (Set<Date>) Collection.of(opportunities).getUniqueValues(Opportunity.LastActivityDate);
        System.assertEquals(expected, actual2);
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

        Set<Datetime> actual2 = (Set<Datetime>) Collection.of(opportunities).getUniqueValues(Opportunity.CreatedDate);
        System.assertEquals(expected, actual2);
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

        Set<Boolean> actual = (Set<Boolean>) Collection.of(opportunities).getUniqueValues(Opportunity.HasOpenActivity);
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

        Set<String> actual = (Set<String>) Collection.of(records).getUniqueValues(String.class, 'Name');
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

        Set<Integer> actual = (Set<Integer>) Collection.of(opportunities).getUniqueValues(new OpportunitiesByYearsHalfMapper());
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

        Set<Object> actual = Collection.of(opportunities).getUniqueValues(fields);
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

        Map<Id, Opportunity> actual = (Map<Id, Opportunity>) Collection.of(opportunities).mapBy(Opportunity.Id);
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

        Map<String, Opportunity> actual = (Map<String, Opportunity>) Collection.of(opportunities).mapBy(Opportunity.Name);
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

        Map<String, SObject> actual = (Map<String, SObject>) Collection.of(records).mapBy(String.class, 'Name');
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

        Map<Decimal, Opportunity> actual = (Map<Decimal, Opportunity>) Collection.of(opportunities).mapBy(Opportunity.Probability);
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

        Map<Integer, Opportunity> actual = (Map<Integer, Opportunity>) Collection.of(opportunities).mapBy(Opportunity.FiscalQuarter);
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

        Map<Boolean, Opportunity> actual = (Map<Boolean, Opportunity>) Collection.of(opportunities).mapBy(Opportunity.HasOpenActivity);
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

        Map<Date, Opportunity> actual = (Map<Date, Opportunity>) Collection.of(opportunities).mapBy(Opportunity.LastActivityDate);
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

        Map<Datetime, Opportunity> actual = (Map<Datetime, Opportunity>) Collection.of(opportunities).mapBy(Opportunity.CreatedDate);
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

        Map<Time, Opportunity> actual = (Map<Time, Opportunity>) Collection.of(opportunities).mapBy(new MapByOpportunityCreateTime());
        System.assertEquals(expected, actual);
    }

    private class MapByOpportunityCreateTime implements Collection.KeyMapper {
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

        Map<String, Id> actual = (Map<String, Id>) Collection.of(opportunities).mapBy(new TestMapper());
        System.assertEquals(expected, actual);
    }
    private class TestMapper implements Collection.Mapper {
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

    /**
     * CollectionMappers.ByFieldPair can map junction object by both parent Ids.
     */
    @IsTest
    static void testMapByFieldPair() {
        Map<String, Opportunity> expected = new Map<String, Opportunity>();
        for (Opportunity opp : opportunities) {
            expected.put(opp.AccountId + '_' + opp.OwnerId, opp);
        }

        Map<String, Opportunity> actual = (Map<String, Opportunity>) Collection.of(opportunities)
                .mapBy(new Collection.MapByFieldPair(Opportunity.AccountId, '_', Opportunity.OwnerId));

        System.assertEquals(expected, actual);
    }

    @IsTest
    static void whenEmptyOpportunityListIsMappedThenEmptyOpportunityByStringMapIsReturned() {
        Map<String, Opportunity> expected = new Map<String, Opportunity>();
        Map<String, Opportunity> actual = (Map<String, Opportunity>) Collection.of(new List<Opportunity>()).mapBy(Opportunity.Name);
        System.assertEquals(expected, actual);
    }

    @IsTest
    static void whenEmptySObjectListIsMappedThenEmptySObjectByStringMapIsReturned() {
        Map<String, SObject> expected = new Map<String, SObject>();
        Map<String, SObject> actual = (Map<String, SObject>) Collection.of(new List<SObject>()).mapBy(Opportunity.Name);

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

        Map<String, List<Opportunity>> actual = (Map<String, List<Opportunity>>) Collection.of(opportunities).groupBy(String.class, 'NextStep');

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
        Map<String, List<Opportunity>> actual = (Map<String, List<Opportunity>>) Collection.of(opportunities).groupBy(Opportunity.NextStep);

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
        Map<Id, List<Opportunity>> actual = (Map<Id, List<Opportunity>>) Collection.of(opportunities).groupBy(Opportunity.AccountId);

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
        Map<Integer, List<Opportunity>> actual = (Map<Integer, List<Opportunity>>) Collection.of(opportunities).groupBy(Opportunity.FiscalQuarter);

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
        Map<Decimal, List<Opportunity>> actual = (Map<Decimal, List<Opportunity>>) Collection.of(opportunities).groupBy(Opportunity.Probability);

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
        Map<Date, List<Opportunity>> actual = (Map<Date, List<Opportunity>>) Collection.of(opportunities).groupBy(Opportunity.LastActivityDate);

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
        Map<Datetime, List<Opportunity>> actual = (Map<Datetime, List<Opportunity>>) Collection.of(opportunities).groupBy(Opportunity.CreatedDate);

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
        Map<Boolean, List<Opportunity>> actual = (Map<Boolean, List<Opportunity>>) Collection.of(opportunities).groupBy(Opportunity.HasOpenActivity);

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
        Map<Integer, List<Opportunity>> actual = (Map<Integer, List<Opportunity>>) Collection.of(opportunities).groupBy(new OpportunitiesByYearsHalfMapper());


        System.assertEquals(expected, actual);
    }

    private class OpportunitiesByYearsHalfMapper implements Collection.KeyMapper {
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

        Map<Integer, List<OpportunityWrapper>> actual = (Map<Integer, List<OpportunityWrapper>>) Collection.of(opportunities).groupBy(new OppWrapperByHalfYearMapper());
        System.assertEquals(JSON.serialize(expected), JSON.serialize(actual));
    }

    private class OppWrapperByHalfYearMapper implements Collection.Mapper {
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
        Map<String, List<Opportunity>> actual = (Map<String, List<Opportunity>>) Collection.of(new List<Opportunity>()).groupBy(Opportunity.Name);
        System.assertEquals(expected, actual);
    }

    @IsTest
    static void whenEmptySObjectListIsGrouppedThenEmptySObjectByStringMapIsReturned() {
        Map<String, List<SObject>> expected = new Map<String, List<SObject>>();
        Map<String, List<SObject>> actual = (Map<String, List<SObject>>) Collection.of(new List<SObject>()).groupBy(Opportunity.Name);
        System.assertEquals(expected, actual);
    }


    /**
     *@description
     * Collections.filterByFieldValue filters input records and return only those which field is the same as specified value.
     */
    @IsTest
    static void tesFiltertFilterByFieldValue() {
        List<Opportunity> hasOpenActivity = new List<Opportunity>();
        List<Opportunity> hasNotOpenActivity = new List<Opportunity>();
        List<Opportunity> fiscalQuarterEquals0 = new List<Opportunity>();
        List<Opportunity> fiscalQuarterNotEquals0 = new List<Opportunity>();
        List<Opportunity> nextStepAnalysis = new List<Opportunity>();
        List<Opportunity> nextStepNotAnalysis = new List<Opportunity>();

        for (Opportunity opp : opportunities) {
            if (opp.HasOpenActivity) {
                hasOpenActivity.add(opp);
            } else {
                hasNotOpenActivity.add(opp);
            }

            if (opp.FiscalQuarter == 0) {
                fiscalQuarterEquals0.add(opp);
            } else {
                fiscalQuarterNotEquals0.add(opp);
            }

            if (opp.NextStep == 'Analysis') {
                nextStepAnalysis.add(opp);
            } else {
                nextStepNotAnalysis.add(opp);
            }
        }

        System.assertEquals(hasOpenActivity, Collection.filter(opportunities, Opportunity.HasOpenActivity, '==', true));
        System.assertEquals(hasNotOpenActivity, Collection.filter(opportunities, Opportunity.HasOpenActivity, '!=', true));

        System.assertEquals(fiscalQuarterEquals0, Collection.filter(opportunities, new Collection.FilterByFieldValue(Opportunity.FiscalQuarter, '==', 0)));
        System.assertEquals(fiscalQuarterNotEquals0, Collection.filter(opportunities, new Collection.FilterByFieldValue(Opportunity.FiscalQuarter, '!=', 0)));

        System.assertEquals(nextStepAnalysis, Collection.of(opportunities).filter(Opportunity.NextStep, '==', 'Analysis').toList());
        System.assertEquals(nextStepNotAnalysis, Collection.of(opportunities).filter(new Collection.FilterByFieldValue(Opportunity.NextStep, '!=', 'Analysis')).toList());
    }


    /**
     * @description
     * Collections.filterByFieldValues filters input records and return only those which field is one of specified values.
     */
    @IsTest
    static void tesFiltertFilterByFieldValues() {
        Set<Object> acceptedStages = new Set<Object>{
                'Analysis', 'Deal'
        };
        List<Opportunity> expectedAcceptedOpps = new List<Opportunity>();
        List<Opportunity> expectedRejectedOpps = new List<Opportunity>();

        for (Opportunity opportunity : opportunities) {
            if (acceptedStages.contains(opportunity.StageName)) {
                expectedAcceptedOpps.add(opportunity);
            } else {
                expectedRejectedOpps.add(opportunity);
            }
        }

        List<Opportunity> actualAcceptedOpps = (List<Opportunity>) Collection.filter(opportunities, new Collection.FilterByFieldValues(Opportunity.StageName, 'IN', acceptedStages));
        List<Opportunity> actualRejectedOpps = (List<Opportunity>) Collection.filter(opportunities, new Collection.FilterByFieldValues(Opportunity.StageName, 'NOT IN', acceptedStages));

        System.assertEquals(expectedAcceptedOpps, actualAcceptedOpps);
        System.assertEquals(expectedRejectedOpps, actualRejectedOpps);
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

        List<Opportunity> actual = Collection.filter(opportunities, oldMap, new OpportunityChangedNameFilter());
        System.assertEquals(expected, actual);
    }

    @IsTest
    static void testFilterByUpdateFilterInstance() {
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

        List<Opportunity> actual = (List<Opportunity>) Collection.of(opportunities)
                .filter(oldMap, new OpportunityChangedNameFilter())
                .toList();
        System.assertEquals(expected, actual);
    }

    private class OpportunityChangedNameFilter implements Collection.UpdateFilter {
        public Boolean accepts(Object record, Object oldRecord) {
            return ((Opportunity) record).Name != ((Opportunity) oldRecord).Name;
        }
    }

    /**
     *@description
     *
     */
    @IsTest
    static void testFilterFieldChanged() {
        List<Opportunity> opps = opportunities;
        List<Opportunity> oldOpps = opps.deepClone(true);
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>(oldOpps);

        opps[0].Name = opps[1].Name = 'Henry';
        opps[2].Name = opps[3].Name = 'John';

        oldOpps[0].Name = 'Hen';
        oldOpps[1].Name = oldOpps[2].Name = 'Ken';


        System.assertEquals(new List<Opportunity>{
                opps[0], opps[1], opps[2], opps[3]
        },
                Collection.filter(opps, oldMap,
                        new Collection.FilterByFieldChanged(Opportunity.Name)
                )
        );

        System.assertEquals(new List<Opportunity>{
                opps[2], opps[3]
        },
                Collection.filter(opps, oldMap, new Collection.FilterByFieldChanged(Opportunity.Name, Collection.ANY_VALUE, 'John'))
        );

        System.assertEquals(new List<Opportunity>{
                opps[1], opps[2]
        }, Collection.filter(opps, oldMap, new Collection.FilterByFieldChanged(Opportunity.Name, 'Ken', Collection.ANY_VALUE))
        );

        System.assertEquals(new List<Opportunity>{
                opps[0]
        }, Collection.filter(opps, oldMap, new Collection.FilterByFieldChanged(Opportunity.Name, 'Hen', 'Henry'))
        );
    }


    /**
     *@description
     * CollectionsFilter.RelatedTo returns records related to given parents.
     */
    @IsTest
    static void testFilterByRelatedTo() {
        List<Account> accounts = new List<Account>{
                new Account(Id = '001000000000000'),
                new Account(Id = '001000000000001')
        };

        Set<Id> expected = new Map<Id, Opportunity>(new List<Opportunity>{
                opportunities[0], opportunities[3], opportunities[6], opportunities[9],
                opportunities[1], opportunities[4], opportunities[7]
        }).keySet();

        Set<Id> actual = (Set<Id>)
                Collection.of(opportunities)
                        .filter(new Collection.FilterRelatedTo(accounts, Opportunity.AccountId))
                        .getUniqueValues(Opportunity.Id);

        System.assertEquals(expected, actual);
    }


    /**
     *@description
     * Returns Opportunities that have the same field values as prototype
     */
    @IsTest
    static void testFilterByPrototype() {
        Opportunity prototype = new Opportunity(
                AccountId = '001000000000000'
        );

        List<Opportunity> expected = new List<Opportunity>();
        for (Opportunity opportunity : opportunities) {
            if (opportunity.AccountId == prototype.AccountId) {
                expected.add(opportunity);
            }
        }


        List<Opportunity> actual = (List<Opportunity>) Collection.of(opportunities).filter(prototype).toList();
        System.assertEquals(expected, actual);
    }


    /**
     *@description
     * Collections.reduce() reduces collection to one object or other collection using Reducer implementation.
     */
    @IsTest
    static void testReduceToIds() {
//        Set<Id> expected = new Set<Id>();
//        for (Opportunity opportunity : opportunities) {
//            expected.add(opportunity.Id);
//            expected.add(opportunity.AccountId);
//        }
//        Set<Id> actual = Collection.of(opportunities)
//                .reduce(new List<SObjectField>{
//                        Opportunity.Id,
//                        Opportunity.AccountId
//                })
//                .toSetOfIds();
//
//        System.assertEquals(expected, actual);
    }


    /**
     *@description
     * List of Opportunities is reduced to total of Amounts
     */
    @IsTest
    static void testReduceToSum() {
        Decimal expected = 0;
        for (Opportunity opportunity : opportunities) {
            expected += opportunity.Amount;
        }

        Decimal actual = Collection.of(opportunities)
                .reduce(Opportunity.Amount)
                .toSum();

        System.assertEquals(expected, actual);
    }

    /**
     *@description
     * List of Opportunities is reduced to max Amount
     */
    @IsTest
    static void testReduceToMax() {
        Decimal max = -9999;
        for (Opportunity opportunity : opportunities) {
            max = Math.max(max, opportunity.Amount);
        }

        Decimal actual = Collection.of(opportunities)
                .reduce(Opportunity.Amount)
                .toMax();

        System.assertEquals(max, actual);
        System.assertNotEquals(null, actual);
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

        List<Opportunity> actual = (List<Opportunity>) Collection.of(opportunities)
                .sort(new ReverseProbabilityComparator())
                .toList();

        System.assertEquals(actual, expected);
    }
    private class ReverseProbabilityComparator implements Collection.Comparator {
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

        List<Opportunity> sortedOpportunities = Collection.sort(opportunities, Opportunity.CreatedDate, true);
        for (Opportunity opportunity : sortedOpportunities) {
            if (previous != null) {
                System.assert(opportunity.CreatedDate >= previous.CreatedDate);
            }
            previous = opportunity;
        }
        previous = null;


        sortedOpportunities = Collection.sort(opportunities, Opportunity.Name, false);
        for (Opportunity opportunity : sortedOpportunities) {
            if (previous != null) {
                System.assertEquals(-1, opportunity.Name.compareTo(previous.Name));
            }
            previous = opportunity;
        }
        previous = null;


        sortedOpportunities = (List<Opportunity>) Collection.of(opportunities)
                .sort(Opportunity.FiscalQuarter, true)
                .toList();
        for (Opportunity opportunity : sortedOpportunities) {
            if (previous != null) {
                System.assert(opportunity.FiscalQuarter >= previous.FiscalQuarter);
            }
            previous = opportunity;
        }
        previous = null;
    }


    /**
     * @description
     * Instance wrap method wraps Collection member list with custom Wrapper class (implementing Collection.Wrapper).
     * This method can be chained with other Collection methods ex.
     * <pre>
     * Map<Id,OpportunityWrapper> ... = Collection.of(opportunities)
     *      .filter(Opportunity.StageName,'==','Analysis')
     *      .wrap(OpportunityWrapper.class)
     *      .mapBy(new WrapperByOpportunityIdMapper());
     * </pre>
     */
    @IsTest
    static void testWrap() {
        List<OpportunityWrapper2> wrappers = (List<OpportunityWrapper2>)
                Collection.of(opportunities)
                        .filter(Opportunity.NextStep, '==', 'Analysis')
                        .wrap(OpportunityWrapper2.class)
                        .toList();

        System.assertEquals(wrappers.size(), 4);
        for (Integer i = 0; i < wrappers.size(); i++) {
            System.assertEquals(wrappers[i].opportunity, opportunities[i]);
        }
    }

    public class OpportunityWrapper2 implements Collection.Wrapper {
        public Opportunity opportunity;

        public void wrap(Object item) {
            this.opportunity = (Opportunity) item;
        }

        public String getName() {
            return opportunity.Name;
        }
    }


    /**
     *@description
     * Fills in the list with number of clones of provided prototype record.
     */
    @IsTest
    static void testFill() {
        Contact contact = new Contact(LastName = 'Test');

        List<Account> accounts = (List<Account>)
                Collection.of(new List<Account>())
                        .fill(10, new Account(Name = 'Test Account', Contact__r = contact))
                        .fill(10, new Account(Name = 'Other Account', Contact__r = contact), new Collection.CloneOptions(false, false, false, false))
                        .toList();


        System.assertEquals(20, accounts.size());

        /*Test if clone is deep*/
        accounts[0].Name += '0';
        contact.LastName += '0';

        for (Account account : accounts) {
            System.debug(account.Contact__r.LastName);
        }

        for (Integer i = 1; i < 20; i++) {
            if (i < 10) {
                System.assertEquals('Test Account', accounts[i].Name);
                System.assertEquals('Test', accounts[i].Contact__r.LastName);

            } else {
                System.assertEquals('Other Account', accounts[i].Name);
                System.assertEquals('Test0', accounts[i].Contact__r.LastName);
            }
        }
    }


    /**
     *@description
     * ForEach executes action on each element in collection and can be chained using instance methods.
     */
    @IsTest
    static void testForEach() {
        List<Opportunity> opportunities = (List<Opportunity>) Collection.of(opportunities)
                .forEach(new AppendIndexToOpportunityNameWorker())
                .toList();

        for (Integer i = 0; i < opportunities.size(); i++) {
            System.assert(opportunities[i].Name.contains('' + i));
        }
    }

    private class AppendIndexToOpportunityNameWorker implements Collection.Worker {
        public void forEach(Object item, Integer index) {
            ((Opportunity) item).Name += index;
        }
    }


    /**
     *@description
     * find() returns first item accepted by ByFieldValue filter.
     */
    @IsTest
    static void testFindReturnsFirstSObjectOfGivenFieldValue() {
        Opportunity expected = opportunities[3];
        Opportunity actual = (Opportunity) Collection.of(opportunities).find(Opportunity.FiscalQuarter, '==', 3);
        System.assertEquals(expected, actual);
    }

    /**
     *@description
     * find() returns null if there's no item accepted by filter.
     */
    @IsTest
    static void testFindReturnsNullWhenThereAreNoItemsAcceptedByFilter() {
        Opportunity actual = (Opportunity) Collection.of(opportunities).find(Opportunity.Probability, '==', 1.5);
        System.assertEquals(null, actual);
    }


    @IsTest
    static void testFindByFilter() {
        Opportunity expected = opportunities[5];
        Opportunity actual = (Opportunity) Collection.of(opportunities).find(new OpportunityNameContainsFilter('5'));

        System.assertEquals(expected, actual);
    }

    private class OpportunityNameContainsFilter implements Collection.Filter {
        private String expr;

        public OpportunityNameContainsFilter(String expr) {
            this.expr = expr;
        }

        public Boolean accepts(Object item) {
            return ((Opportunity) item).Name.contains(expr);
        }
    }


    @IsTest
    static void testMethodChaining() {
        Map<Boolean, List<OpportunityWrapper2>> expected = new Map<Boolean, List<CollectionTest.OpportunityWrapper2>>{
                true => new List<OpportunityWrapper2>(),
                false => new List<OpportunityWrapper2>()
        };

        for (Integer i = 0; i < opportunities.size(); i++) {
            Opportunity opp = opportunities[i];

            if (opp.CreatedDate >= Date.today().addDays(-3)) {
                opp.Name += i;

                OpportunityWrapper2 wrapper = new OpportunityWrapper2();
                wrapper.wrap(opp);

                expected.get(opp.HasOpenActivity).add(wrapper);
            }
        }


        Map<Boolean, List<OpportunityWrapper2>> actual = (Map<Boolean, List<OpportunityWrapper2>>)
                Collection.of(opportunities)
                        .filter(Opportunity.CreatedDate, '>=', Date.today().addDays(-3))
                        .forEach(new AppendIndexToOpportunityNameWorker())
                        .wrap(OpportunityWrapper2.class)
                        .groupBy(new WrapperByOpenActivityMapper());


        System.assertEquals(JSON.serialize(expected), JSON.serialize(actual));
    }

    private class WrapperByOpenActivityMapper implements Collection.KeyMapper {
        public Object key(Object item) {
            return ((OpportunityWrapper2) item).opportunity.HasOpenActivity;
        }

        public Type keyType() {
            return Boolean.class;
        }
    }
}