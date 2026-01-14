import {api} from "lwc";

function RecordFormComponent(lightningComponent) {
    return class extends lightningComponent {
        static renderMode = 'light';

        @api field;
        @api record;
        @api formParams;
        @api fieldLevelHelp;
        @api readOnly;
        @api disabled;
        @api required;
        @api validity;
        @api formReadOnly;
        @api formVariant;
        @api designSystem;
        controllerName;

        connectedCallback() {
            this.dispatchEvent(new CustomEvent('fieldconnected', {
                detail : this.hostElement,
                bubbles: true, composed: true
            }));
        }

        @api
        connectField({fieldInfo}) {
            try {
                this.fieldLevelHelp = fieldInfo.inlineHelpText;
                this.label = this.label ?? fieldInfo.label;
                this.readOnly = this.readOnly ?? fieldInfo.readOnly;
                this.controllerName = fieldInfo.controllerName;
            } catch (e) {
                console.log(e.message, e.stack);
            }
        }

        @api
        reportValidity() {
            return this.refs.input.reportValidity?.() ?? true;
        }

        @api
        setCustomValidity(message) {
            return this.refs.input.setCustomValidity?.(message);
        }

        @api
        checkValidity() {
            return this.refs.input.checkValidity?.() ?? true;
        }

        handleFieldChange(event) {
            try {
                event.preventDefault();
                event.stopPropagation();
                this.dispatchEvent(new CustomEvent('change', {
                    detail : {
                        value: this.getEventValue(event)
                    },
                    bubbles: true,
                }));
            } catch (e) {
                console.error('RecordFormField.handleChange', e.message);
            }
        }

        getEventValue(event) {
            return ({[this.field]: event.detail.value});
        }

        get isReadOnly() {
            return this.readOnly || this.formReadOnly;
        }

        get fieldValue() {
            return this.getField(this.field);
        }

        get controllerValue() {
            return this.getField(this.controllerName);
        }

        getField(field) {
            return this.record?.[field];
        }

        get inputVariant() {
            return this.formVariant;
        }
    };
}

export {RecordFormComponent}