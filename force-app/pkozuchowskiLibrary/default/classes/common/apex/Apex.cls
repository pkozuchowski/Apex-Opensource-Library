/**
 * Utility class with methods concerning Apex programming language.
 */
public with sharing class Apex {


    /*
     * @return returns Type of given list single element
     * */
    public static Type getListItemType(List<Object> o) {
        return getRunningType(o, 'Invalid conversion from runtime type List<', '> to Date');
    }

    /**
     * @return Running type of object passed in parameter.
     * This method returns null if type is not accessible - when class is private
     * or when it's part of anonymous script. In that case, getRunningTypeName() should be used instead.
     */
    public static Type getRunningType(Object o) {
        return getRunningType(o, 'Invalid conversion from runtime type ', ' to Date');
    }

    /**
     * @return Name of running type of object passed in parameter.
     */
    public static String getRunningTypeName(Object o) {
        return getRunningTypeName(o, 'Invalid conversion from runtime type ', ' to Date');
    }


    private static Type getRunningType(Object o, String open, String close) {
        return Type.forName(getRunningTypeName(o, open, close));
    }

    private static String getRunningTypeName(Object o, String open, String close) {
        try {
            Date d = (Date) o;
            return 'Date';
        } catch (Exception ex) {
            return ex.getMessage().substringBetween(open, close);
        }
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
     * @param itemType Type of single list element
     * @param fallbackItemType Fallback type, in case primary type is not constructible (ex. because the type is private).
     * @return New list of given item type.
     */
    public static List<Object> newListOfItemType(Type itemType, List<Object> fallback) {
        try {
            return (List<Object>) Type.forName('List<' + itemType + '>').newInstance();
        } catch (Exception ex) {
            return null;
        }
    }
}