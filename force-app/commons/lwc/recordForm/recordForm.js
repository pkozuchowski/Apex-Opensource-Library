// SPDX-License-Identifier: MIT
// Copyright 2026 Piotr Kożuchowski
import {api, LightningElement, track, wire} from 'lwc';
import {getObjectInfo, getPicklistValuesByRecordType} from "lightning/uiObjectInfoApi";

const MASTER_RECORD_TYPE = "012000000000000AAA";

export default class RecordForm extends LightningElement {
    @api objectName;
    @api recordType;
    @api record = {};
    /** Map<Field, Label> of label overrides*/
    @api labelOverrides;
    @api designSystem = "lightning";
    @api inputVariant = "label-stacked";
    @track
    formParams = {
        readOnly    : false,
        designSystem: "lightning",
        variant     : "label-stacked"
    };

    @api get readOnly() {
        return this.formParams.readOnly;
    }

    set readOnly(value) {
        this.formParams.readOnly = value;
    }

    loading = true;
    objectInfo;
    picklistValues;
    recordTypeId;

    @wire(getObjectInfo, {objectApiName: '$objectName'})
    describeObjectInfo({err, data}) {
        if (data) {
            this.objectInfo = JSON.parse(JSON.stringify(data));
            this.getRecordTypeId(data);
            this.overrideFieldLabels();
        } else if (err) {
            console.error('Error fetching object info', err);
        }
    };

    getRecordTypeId(data) {
        if (this.recordType) {
            const recordTypeInfos = data.recordTypeInfos;
            this.recordTypeId = Object.values(recordTypeInfos)
                .find(rti => rti.name === this.recordType)?.recordTypeId;
        }
        this.recordTypeId = this.recordTypeId || data.defaultRecordTypeId || MASTER_RECORD_TYPE;
    }

    overrideFieldLabels() {
        if (this.labelOverrides) {
            for (let field in this.labelOverrides) {
                this.objectInfo.fields[field].label = this.labelOverrides[field];
            }
        }
    }

    @wire(getPicklistValuesByRecordType, {
        objectApiName: "$objectName",
        recordTypeId : "$recordTypeId",
    })
    describePicklistValues({err, data}) {
        if (data) {
            this.picklistValues = JSON.parse(JSON.stringify(data.picklistFieldValues));
            this.loading = false;
        } else if (err) {
            console.error('Error fetching picklist values', err);
        }
    };

    onFieldConnected(ev) {
        ev.preventDefault();
        ev.stopPropagation();
        if (ev.target.connectField) {
            ev.target.record = this.record;
            ev.target.connectField(
                this.objectInfo,
                this.picklistValues,
                this.formParams
            );
        }
    }
}