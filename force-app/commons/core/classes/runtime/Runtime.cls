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
 * Utility class with methods related to dynamic/reflection aspect of Apex language
 * @see RuntimeTest
 */
public with sharing class Runtime {
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


    /**
     * Holds execution for given amount of time.
     * Counts against CPU Time governor limit.
     */
    public static void sleep(Long milliSeconds) {
        Long startTime = System.currentTimeMillis();
        Long diff = 0;

        while (diff < milliSeconds){
            diff = System.currentTimeMillis() - startTime;
        }
    }

    /**
     * @return Running type of object passed in parameter.
     * This method returns null if type is not accessible - when class is private
     * or when it's part of anonymous script. In that case, getRunningTypeName() should be used instead.
     */
    public static Type getType(Object o) {
        return getType(o, 'Invalid conversion from runtime type ', ' to Date');
    }

    /**
     * @return Name of running type of object passed in parameter.
     */
    public static String getTypeName(Object o) {
        return getTypeName(o, 'Invalid conversion from runtime type ', ' to Date');
    }


    private static Type getType(Object o, String open, String close) {
        return Type.forName(getTypeName(o, open, close));
    }

    private static String getTypeName(Object o, String open, String close) {
        if (o == null) throw new NullPointerException();

        try {
            Date d = (Date) o;
            return 'Date';
        } catch (Exception ex) {
            return ex.getMessage().substringBetween(open, close);
        }
    }


    /**
     * @return Value type of SObject field
     */
    public static Type getSObjectFieldType(SObjectField field) {
        return FIELD_TYPE_MAP.get(field.getDescribe().getSoapType());
    }

    /**
     * @return returns Type of given list single element
     * */
    public static Type getListItemType(List<Object> o) {
        return getType(o, 'List<', '>');
    }

    /**
     * @return returns Type of given iterable (list or set) single element
     * */
    public static Type getIterableItemType(Iterable<Object> o) {
        return getType(o, '<', '>');
    }


    /**
     * @return New empty list of the same SObject type as original.
     */
    public static List<Object> newListOfTheSameType(List<Object> original) {
        List<Object> clone = original.clone();
        clone.clear();

        return clone;
    }

    /**
     * @param itemType Type of single list element
     * @return New list of given item type.
     */
    public static List<Object> newListOfItemType(Type itemType) {
        return newListOfItemType(itemType, new List<Object>());
    }

    /**
     * @param itemType SObject type of list
     * @return New list of given item type (List<SObject>)
     */
    public static List<SObject> newListOfItemType(SObjectType itemType) {
        Type t = Type.forName('' + itemType);
        return (List<SObject>) newListOfItemType(t, new List<SObject>());
    }

    /**
     * @return New list with item type of SObject field.
     */
    public static List<Object> newListOfFieldType(SObjectField field) {
        return newListOfItemType(getSObjectFieldType(field), new List<Object>());
    }

    /**
     * @param itemType Type of single list element
     * @param fallback Fallback type, in case primary type is not constructible (ex. because the type is private).
     * @return New list of given item type.
     */
    public static List<Object> newListOfItemType(Type itemType, List<Object> fallback) {
        try {
            return (List<Object>) Type.forName('List<' + itemType + '>').newInstance();
        } catch (Exception ex) {
            return fallback;
        }
    }


    /**
     * @return Name of running callee class
     */
    public static String getRunningClass() {
        return getStackTrace()[0].apexClass;
    }

    /**
     * @return Name of running callee class and method where this was called in stack trace format:
     * "CalleeClass.method"
     */
    public static String getRunningMethod() {
        return getStackTrace()[0].apexClassMethod;
    }

    /**
     * @return Stack Trace Line of code where this method was called.
     */
    public static StackTraceLine getStackLocation() {
        return getStackTrace()[0];
    }

    /**
     * @return Stack Trace Lines without Apex class entry
     */
    public static StackTraceLine[] getStackTrace() {
        List<String> lines =  new DmlException('_').getStackTraceString().split('\n');

        List<StackTraceLine> stackTraceLines = new List<StackTraceLine>();
        for (Integer i = 1; i < lines.size(); i++) {
            if (!lines[i].contains('Class.' + Runtime.class + '.')) {
                stackTraceLines.add(new StackTraceLine(lines[i]));
            }
        }

        return stackTraceLines;
    }

    /**
     * @return Stack trace line of apex class which called method where Runtime.getCaller() is executed.
     */
    public static StackTraceLine getCaller() {
        List<StackTraceLine> lines = getStackTrace();
        String callerOfRuntime = lines.get(0).apexClass;

        for (StackTraceLine stackTraceLine : lines) {
            if (stackTraceLine.apexClass != callerOfRuntime) {
                return stackTraceLine;
            }
        }

        return null;
    }


    public class StackTraceLine {
        @AuraEnabled public String apexClassMethod { get; private set; }
        @AuraEnabled public String apexClass { get; private set; }
        @AuraEnabled public String method { get; private set; }
        @AuraEnabled public Integer line { get; private set; }
        @AuraEnabled public Integer column { get; private set; }

        private StackTraceLine(String line) {
            this.apexClassMethod = line.remove('Class.').substringBefore(':');
            this.apexClass = apexClassMethod.substringBeforeLast('.');
            this.method = apexClassMethod.substringAfterLast('.');
            this.line = Integer.valueOf(line.substringBetween('line ', ','));
            this.column = Integer.valueOf(line.substringAfter('column '));
        }
    }

}