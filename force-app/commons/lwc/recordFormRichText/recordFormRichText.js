import {api, LightningElement} from 'lwc';
import {RecordFormComponent} from "c/recordFormComponent";

const DEFAULT_FORMATS = ['font', 'size', 'bold', 'italic', 'underline', 'strike', 'list',
    'indent', 'align', 'link', 'image', 'clean', 'header', 'color'
];

export default class RecordFormRichText extends RecordFormComponent(LightningElement) {
    @api disabled;
    @api disabledCategories = '';
    @api fieldLevelHelp;
    @api formats = DEFAULT_FORMATS;
    @api label;
    @api labelVisible;
    @api messageWhenBadInput;
    @api placeholder;
    @api required;
    @api readOnly;
    @api shareWithEntityId;
    @api valid;
    @api value;
    @api variant;

    connectField({fieldInfo}) {
        super.connectField(arguments[0]);
        this.labelVisible = this.labelVisible ?? true;
        this.shareWithEntityId = this.record?.Id;
    }
}