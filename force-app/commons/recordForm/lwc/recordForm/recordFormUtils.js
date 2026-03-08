/**
 * Validates all fields using the provided validation function.
 * @param {Array} fields - Array of field components to validate
 * @param {Function} validationFn - Function that validates a single field component and returns boolean or undefined
 * @returns {Object} Validation result object containing:
 *   - valid: {boolean} Overall validation status (true if all fields are valid)
 *   - fields: {Object} Map of field names to their individual validation status
 */
export function validate(fields, validationFn) {
    const result = {valid: true, fields: {}};
    fields.forEach(component => {
        const validity = validationFn(component);
        result.valid = result.valid && (validity ?? true);
        result.fields[component.field] = validity;
    });
    return result;
}

/**
 * Filters record fields to include only those that can be created or updated based on field metadata.
 * @param {Object} record - The record object containing field values (default: empty object)
 * @param {Object} objectInfo - Object metadata containing field definitions (default: empty object)
 * @param {boolean} isCreate - Flag indicating if this is a create operation (true) or update operation (false)
 * @returns {Object} Object containing only the fields that are createable/updateable, plus the Id field
 */
export function getUpdatableFields(record = {}, objectInfo = {}, isCreate) {
    const fields = {};

    Object.keys(record).forEach(fieldName => {
        const info = objectInfo.fields[fieldName];
        if (!info) return;

        if ((isCreate && info.createable) || (!isCreate && info.updateable)) {
            fields[fieldName] = record[fieldName];
        }
    });
    fields.Id = record.Id;

    return fields;
}


/**
 * Overrides field labels in the object metadata with custom labels.
 * @param {Object} labelOverrides - Map of field API names to custom label strings
 * @param {Object} objectInfo - Object metadata containing field definitions to be modified
 * @returns {Object} The modified objectInfo with updated field labels
 */
export function overrideFieldLabels(labelOverrides, objectInfo) {
    if (labelOverrides) {
        for (const field in labelOverrides) {
            objectInfo.fields[field].label = labelOverrides[field];
        }
    }
    return objectInfo;
}

/**
 * Converts a record representation from the Lightning Data Service format to a flat record object.
 * Extracts field values from the nested fields structure and includes the record Id.
 * @param {Object} recordRepresentation - Record representation object from Lightning Data Service
 * @returns {Object} Flat record object with field names as keys and field values as values, including the Id field
 */
export function getFlatRecord(recordRepresentation) {
    const flatRecord = {};

    for (const field in recordRepresentation.fields) {
        flatRecord[field] = recordRepresentation.fields[field].value;
    }
    flatRecord.Id = recordRepresentation.id;

    return flatRecord;
}

/**
 * Retrieves the list of fields to fetch for a given field, including compound field components if applicable.
 * For compound fields (like Address or Name), this function returns both the compound field itself
 * and all its component fields.
 * @returns {Array<string>} Array of fully-qualified field names in the format "ObjectApiName.FieldApiName".
 *   Returns an empty array if field api name is not correct.
 */
export function getFieldsToRetrieve(objectInfo, fieldInfo, fieldName) {
    if (fieldInfo) {
        const fieldsToRetrieve = [`${objectInfo.apiName}.${fieldName}`];

        if (fieldInfo.compound) {
            Object.values(objectInfo.fields)
                .forEach(compoundField => {
                    if (compoundField.compoundFieldName === fieldName) {
                        fieldsToRetrieve.push(`${objectInfo.apiName}.${compoundField.apiName}`)
                    }
                });
        }
        return fieldsToRetrieve
    } else {
        console.warn(`Field ${fieldName} not found in object ${this.objectApiName}`);
        return [];
    }
}