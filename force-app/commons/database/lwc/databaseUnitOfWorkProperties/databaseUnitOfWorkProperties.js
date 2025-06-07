import {api, LightningElement, wire} from 'lwc';
import {getObjectInfo} from "lightning/uiObjectInfoApi";

const EVT_TYPE_CHANGE = "configuration_editor_generic_type_mapping_changed";
const EVT_VALUE_CHANGE = "configuration_editor_input_value_changed";
const EVT_VALUE_DELETE = "configuration_editor_input_value_deleted";

export default class DatabaseUnitOfWorkProperties extends LightningElement {
    @api inputVariables;

    @api
    genericTypeMappings;

    @api
    builderContext;

    operations = [
        {label: "Insert", value: "insert"},
        {label: "Update", value: "update"},
        {label: "Upsert", value: "upsert"},
        {label: "Delete", value: "delete"},
        {label: "Commit Work", value: "commit"}
    ];

    runInModes = [
        {label: "User Mode", value: "userMode"},
        {label: "System With Sharing", value: "systemModeWithSharing"},
        {label: "System Without Sharing", value: "systemModeWithoutSharing"},
    ];

    get operation() {return this.inputValue("operationType");}

    get upsertField() {return this.inputValue("upsertField");}

    get runInMode() {return this.inputValue("runInMode");}

    get record() {return this.inputValue("record");}

    get recordType() {return this.genericTypeMappings.find(mapping => mapping.typeName === "T__record")?.typeValue;}

    get isUpsert() {return this.operation === "upsert";}

    get isCommit() {return this.operation === "commit";}

    inputValue(name) {
        return this.inputVariables?.find(param => param.name === name)?.value;
    }

    get recordOptions() {
        return this.builderContext.variables.map(variable => {
            if (variable.dataType === "SObject" && variable.isCollection === false) {
                return {
                    label: variable.name,
                    value: variable.name
                }
            }
        });
    }

    @wire(getObjectInfo, {objectApiName: '$recordType'})
    objectInfo;

    get upsertFieldOptions() {
        const upsertFields = [];
        Object.values(this.objectInfo?.data?.fields || [])
            .forEach(field => {
                if (field.externalId || field.nameField || (field.apiName === 'Id')) {
                    upsertFields.push({
                        label: field.label,
                        value: field.apiName
                    });
                }
            });

        return upsertFields;
    }


    handleOperationChange(event) {
        const newValue = event.detail.value;
        this.changeValue("operationType", newValue);

        if (newValue === "upsert") {
            this.changeValue("upsertField", "Id");

        } else {
            this.deleteValue("upsertField");
            this.deleteValue("upsertField");
        }

        if (newValue === "commit") {
            this.changeValue("runInMode", this.runInModes[0].value);
            this.deleteValue("record");
        } else {
            this.deleteValue("runInMode");
        }
    }

    handleRecordChange(event) {
        const newValue = event.detail.value;
        const typeValue = this.builderContext.variables
            .find(variable => variable.name === newValue).objectType;

        this.changeValueType("T__record", typeValue);
        this.changeValue("record", newValue, "reference");

        if (this.isUpsert) {
            this.changeValue("upsertField", "Id");
        }
    }

    handleValueChange(event) {
        const newValue = event.detail.value;
        const name = event.target.name;
        const type = event.target.dataset?.type;
        this.changeValue(name, newValue, type);
    }


    changeValueType(typeName, typeValue) {
        this.dispatchEvents(EVT_TYPE_CHANGE, {name, typeName, typeValue});
    }

    changeValue(name, newValue, valueType) {
        let newValueDataType = valueType || "String";
        this.dispatchEvents(EVT_VALUE_CHANGE, {name, newValue, newValueDataType});
    }

    deleteValue(name) {
        this.dispatchEvents(EVT_VALUE_DELETE, {name});
    }

    dispatchEvents(name, detail) {
        this.dispatchEvent(new CustomEvent(name, {
            bubbles   : true,
            cancelable: false,
            composed  : true,
            detail    : detail
        }));
    }
}