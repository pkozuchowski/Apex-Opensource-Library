/**
 * Created by piotr on 2018-09-18.
 */

public with sharing class CollectionMap {

    /**
     * IMap factory method which returns proper IMap implementation for given keyType parameter
     * and initializes it with empty Map of the same sObject type as given records.
     */
    public static Collection.IMap newIMap(Type keyType, Type objectType) {
        Object sfMap = Type.forName('Map<' + keyType + ',' + objectType + '>').newInstance();

        if (keyType == Id.class) return new MapById((Map<Id, Object>) sfMap);
        if (keyType == String.class) return new MapByString((Map<String, Object>) sfMap);
        if (keyType == Integer.class) return new MapByInteger((Map<Integer, Object>) sfMap);
        if (keyType == Decimal.class) return new MapByDecimal((Map<Decimal, Object>) sfMap);
        if (keyType == Date.class) return new MapByDate((Map<Date, Object>) sfMap);
        if (keyType == Datetime.class) return new MapByDatetime((Map<Datetime, Object>) sfMap);
        if (keyType == Boolean.class) return new MapByBoolean((Map<Boolean, Object>) sfMap);
        if (keyType == Time.class) return new MapByTime((Map<Time, Object>) sfMap);

        return new MapByObject((Map<Object, Object>) sfMap);
    }


    public class MapByObject implements Collection.IMap {
        private Map<Object, Object> mapInstance;

        public MapByObject(Map<Object, Object> mapInstance) {
            this.mapInstance = mapInstance;
        }
        public void put(Object key, Object value) {
            mapInstance.put(key, (Object) value);
        }
        public Boolean containsKey(Object key) {
            return mapInstance.containsKey(key);
        }
        public Object get(Object key) {
            return mapInstance.get(key);
        }
        public Object toMap() {
            return mapInstance;
        }
        public Object keySet() {
            return mapInstance.keySet();
        }
    }

    public class MapById implements Collection.IMap {
        private Map<Id, Object> mapInstance;

        public MapById(Map<Id, Object> mapInstance) {
            this.mapInstance = mapInstance;
        }
        public void put(Object key, Object value) {
            mapInstance.put((Id) key, (Object) value);
        }
        public Boolean containsKey(Object key) {
            return mapInstance.containsKey((Id) key);
        }
        public Object get(Object key) {
            return mapInstance.get((Id) key);
        }
        public Object toMap() {
            return mapInstance;
        }
        public Object keySet() {
            return mapInstance.keySet();
        }
    }

    public class MapByString implements Collection.IMap {
        private Map<String, Object> mapInstance;

        public MapByString(Map<String, Object> mapInstance) {
            this.mapInstance = mapInstance;
        }
        public void put(Object key, Object value) {
            mapInstance.put((String) key, (Object) value);
        }
        public Boolean containsKey(Object key) {
            return mapInstance.containsKey((String) key);
        }
        public Object get(Object key) {
            return mapInstance.get((String) key);
        }
        public Object toMap() {
            return mapInstance;
        }
        public Object keySet() {
            return mapInstance.keySet();
        }
    }

    public class MapByInteger implements Collection.IMap {
        private Map<Integer, Object> mapInstance;

        public MapByInteger(Map<Integer, Object> mapInstance) {
            this.mapInstance = mapInstance;
        }
        public void put(Object key, Object value) {
            mapInstance.put((Integer) key, (Object) value);
        }
        public Boolean containsKey(Object key) {
            return mapInstance.containsKey((Integer) key);
        }
        public Object get(Object key) {
            return mapInstance.get((Integer) key);
        }
        public Object toMap() {
            return mapInstance;
        }
        public Object keySet() {
            return mapInstance.keySet();
        }
    }

    public class MapByDecimal implements Collection.IMap {
        private Map<Decimal, Object> mapInstance;

        public MapByDecimal(Map<Decimal, Object> mapInstance) {
            this.mapInstance = mapInstance;
        }
        public void put(Object key, Object value) {
            mapInstance.put((Decimal) key, (Object) value);
        }
        public Boolean containsKey(Object key) {
            return mapInstance.containsKey((Decimal) key);
        }
        public Object get(Object key) {
            return mapInstance.get((Decimal) key);
        }
        public Object toMap() {
            return mapInstance;
        }
        public Object keySet() {
            return mapInstance.keySet();
        }
    }

    public class MapByDate implements Collection.IMap {
        private Map<Date, Object> mapInstance;

        public MapByDate(Map<Date, Object> mapInstance) {
            this.mapInstance = mapInstance;
        }
        public void put(Object key, Object value) {
            mapInstance.put((Date) key, (Object) value);
        }
        public Boolean containsKey(Object key) {
            return mapInstance.containsKey((Date) key);
        }
        public Object get(Object key) {
            return mapInstance.get((Date) key);
        }
        public Object toMap() {
            return mapInstance;
        }
        public Object keySet() {
            return mapInstance.keySet();
        }
    }

    public class MapByDatetime implements Collection.IMap {
        private Map<Datetime, Object> mapInstance;

        public MapByDatetime(Map<Datetime, Object> mapInstance) {
            this.mapInstance = mapInstance;
        }
        public void put(Object key, Object value) {
            mapInstance.put((Datetime) key, (Object) value);
        }
        public Boolean containsKey(Object key) {
            return mapInstance.containsKey((Datetime) key);
        }
        public Object get(Object key) {
            return mapInstance.get((Datetime) key);
        }
        public Object toMap() {
            return mapInstance;
        }
        public Object keySet() {
            return mapInstance.keySet();
        }
    }

    public class MapByBoolean implements Collection.IMap {
        private Map<Boolean, Object> mapInstance;

        public MapByBoolean(Map<Boolean, Object> mapInstance) {
            this.mapInstance = mapInstance;
        }
        public void put(Object key, Object value) {
            mapInstance.put((Boolean) key, (Object) value);
        }
        public Boolean containsKey(Object key) {
            return mapInstance.containsKey((Boolean) key);
        }
        public Object get(Object key) {
            return mapInstance.get((Boolean) key);
        }
        public Object toMap() {
            return mapInstance;
        }
        public Object keySet() {
            return mapInstance.keySet();
        }
    }

    public class MapByTime implements Collection.IMap {
        private Map<Time, Object> mapInstance;

        public MapByTime(Map<Time, Object> mapInstance) {
            this.mapInstance = mapInstance;
        }
        public void put(Object key, Object value) {
            mapInstance.put((Time) key, (Object) value);
        }
        public Boolean containsKey(Object key) {
            return mapInstance.containsKey((Time) key);
        }
        public Object get(Object key) {
            return mapInstance.get((Time) key);
        }
        public Object toMap() {
            return mapInstance;
        }
        public Object keySet() {
            return mapInstance.keySet();
        }
    }
}