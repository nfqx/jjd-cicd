import { LightningElement, api } from "lwc";

const OUTPUT_TYPE_NAME = "U__records";
const DEFAULT_MAX_ROWS = 2000;

const BIND_DEFINITIONS = [
    {
        name: "recordId",
        dataType: "String",
        label: "recordId (ID)",
        placeholder: "{!$Record.Id}",
        helpText: "Im SOQL als :recordId verwenden."
    },
    {
        name: "textValue1",
        dataType: "String",
        label: "textValue1 (Text)",
        placeholder: "Kunde oder {!varText}",
        helpText: "Im SOQL als :textValue1 verwenden."
    },
    {
        name: "textValue2",
        dataType: "String",
        label: "textValue2 (Text)",
        placeholder: "DE oder {!varText2}",
        helpText: "Im SOQL als :textValue2 verwenden."
    },
    {
        name: "numberValue1",
        dataType: "Number",
        label: "numberValue1 (Zahl)",
        placeholder: "100 oder {!varNumber}",
        helpText: "Im SOQL als :numberValue1 verwenden."
    },
    {
        name: "dateValue1",
        dataType: "Date",
        label: "dateValue1 (Datum)",
        placeholder: "2026-09-02 oder {!varDate}",
        helpText: "ISO-Datum YYYY-MM-DD; im SOQL als :dateValue1 verwenden."
    },
    {
        name: "dateTimeValue1",
        dataType: "DateTime",
        label: "dateTimeValue1 (Datum/Uhrzeit)",
        placeholder: "2026-09-02T12:00:00Z oder {!varDateTime}",
        helpText: "ISO-Datum/Uhrzeit; im SOQL als :dateTimeValue1 verwenden."
    },
    {
        name: "booleanValue1",
        dataType: "Boolean",
        label: "booleanValue1 (Boolean)",
        placeholder: "true, false oder {!varBoolean}",
        helpText: "Im SOQL als :booleanValue1 verwenden."
    }
];

export default class SoqlGetRecordsEditor extends LightningElement {
    _inputVariables = [];
    _genericTypeMappings = [];
    _builderContext = {};
    _automaticOutputVariables = {};
    _draftValues = {};
    validationMessage = "";

    @api
    get inputVariables() {
        return this._inputVariables;
    }

    set inputVariables(value) {
        this._inputVariables = value || [];
        const nextDraftValues = {};
        this._inputVariables.forEach((variable) => {
            nextDraftValues[variable.name] = this.toEditorValue(variable);
        });
        this._draftValues = nextDraftValues;
    }

    @api
    get genericTypeMappings() {
        return this._genericTypeMappings;
    }

    set genericTypeMappings(value) {
        this._genericTypeMappings = value || [];
    }

    @api
    get builderContext() {
        return this._builderContext;
    }

    set builderContext(value) {
        this._builderContext = value || {};
    }

    @api
    get automaticOutputVariables() {
        return this._automaticOutputVariables;
    }

    set automaticOutputVariables(value) {
        this._automaticOutputVariables = value || {};
    }

    get outputObjectApiName() {
        return this.readValue("outputObjectApiName");
    }

    get soqlQuery() {
        return this.readValue("soqlQuery");
    }

    get maxRows() {
        const value = this.readValue("maxRows");
        return value === "" || value === null || value === undefined
            ? DEFAULT_MAX_ROWS
            : value;
    }

    get outputType() {
        const mapping = this._genericTypeMappings.find(
            (item) => (item.typeName || item.name) === OUTPUT_TYPE_NAME
        );
        return mapping ? mapping.typeValue || mapping.value || "" : "";
    }

    get flowRecordIdExample() {
        return "{!$Record.Id}";
    }

    get bindFields() {
        return BIND_DEFINITIONS.map((definition) => ({
            ...definition,
            value: this.readValue(definition.name)
        }));
    }

    readValue(name) {
        return Object.prototype.hasOwnProperty.call(this._draftValues, name)
            ? this._draftValues[name]
            : "";
    }

    toEditorValue(variable) {
        if (!variable || variable.value === null || variable.value === undefined) {
            return "";
        }
        if (variable.valueDataType === "reference") {
            const reference = String(variable.value);
            return reference.startsWith("{!") ? reference : `{!${reference}}`;
        }
        return variable.value;
    }

    handleObjectChange(event) {
        const value = event.target.value.trim();
        this.setDraftValue("outputObjectApiName", value);
        this.reportInputChange("outputObjectApiName", value, "String");
        this.reportGenericTypeChange(value);
        this.clearValidationMessage();
    }

    handleStringChange(event) {
        const name = event.target.dataset.name;
        const value = event.target.value;
        this.setDraftValue(name, value);
        this.reportInputChange(name, value, "String");
        this.clearValidationMessage();
    }

    handleNumberChange(event) {
        const rawValue = event.target.value;
        this.setDraftValue("maxRows", rawValue);
        if (rawValue === "" || rawValue === null || rawValue === undefined) {
            this.reportInputDelete("maxRows");
        } else {
            this.reportInputChange("maxRows", Number(rawValue), "Number");
        }
        this.clearValidationMessage();
    }

    handleBindChange(event) {
        const name = event.target.dataset.name;
        const dataType = event.target.dataset.dataType;
        const rawValue = event.target.value.trim();
        this.setDraftValue(name, rawValue);

        if (!rawValue) {
            this.reportInputDelete(name);
            this.clearValidationMessage();
            return;
        }

        if (this.isFlowReference(rawValue)) {
            this.reportInputChange(name, rawValue, "reference");
            this.clearValidationMessage();
            return;
        }

        const literalError = this.validateLiteral(rawValue, dataType);
        if (literalError) {
            this.reportInputDelete(name);
            this.validationMessage = literalError;
            return;
        }

        const literalValue = this.convertLiteral(rawValue, dataType);
        this.reportInputChange(name, literalValue, dataType);
        this.clearValidationMessage();
    }

    convertLiteral(rawValue, dataType) {
        if (dataType === "Number") {
            return Number(rawValue);
        }
        if (dataType === "Boolean") {
            return rawValue.toLowerCase() === "true";
        }
        return rawValue;
    }

    isFlowReference(value) {
        return /^\{![^{}]+\}$/.test(value);
    }

    setDraftValue(name, value) {
        this._draftValues = { ...this._draftValues, [name]: value };
    }

    reportInputChange(name, newValue, newValueDataType) {
        if (newValue === "" || newValue === null || newValue === undefined) {
            this.reportInputDelete(name);
            return;
        }
        this.dispatchEvent(
            new CustomEvent("configuration_editor_input_value_changed", {
                bubbles: true,
                composed: true,
                detail: { name, newValue, newValueDataType }
            })
        );
    }

    reportInputDelete(name) {
        this.dispatchEvent(
            new CustomEvent("configuration_editor_input_value_deleted", {
                bubbles: true,
                composed: true,
                detail: { name }
            })
        );
    }

    reportGenericTypeChange(typeValue) {
        this.dispatchEvent(
            new CustomEvent(
                "configuration_editor_generic_type_mapping_changed",
                {
                    bubbles: true,
                    composed: true,
                    detail: {
                        typeName: OUTPUT_TYPE_NAME,
                        typeValue
                    }
                }
            )
        );
    }

    clearValidationMessage() {
        this.validationMessage = "";
    }

    @api
    validate() {
        const errors = [];
        const objectName = String(this.outputObjectApiName || "").trim();
        const query = String(this.soqlQuery || "").trim();
        const maxRows = Number(this.maxRows);

        if (!objectName) {
            errors.push({
                key: "outputObjectApiName",
                errorString: "Ausgabeobjekt (API-Name) ist erforderlich."
            });
        } else if (!/^[A-Za-z][A-Za-z0-9_]*$/.test(objectName)) {
            errors.push({
                key: "outputObjectApiName",
                errorString: "Der Objekt-API-Name ist ungültig."
            });
        }

        if (!query) {
            errors.push({
                key: "soqlQuery",
                errorString: "SOQL-Abfrage ist erforderlich."
            });
        } else if (!/^SELECT\b/i.test(query)) {
            errors.push({
                key: "soqlQuery",
                errorString: "Die Abfrage muss mit SELECT beginnen."
            });
        } else if (this.hasSemicolonOutsideString(query)) {
            errors.push({
                key: "soqlQuery",
                errorString: "Semikolons und mehrere Anweisungen sind nicht erlaubt."
            });
        }

        if (!Number.isInteger(maxRows) || maxRows < 1 || maxRows > 10000) {
            errors.push({
                key: "maxRows",
                errorString: "Maximale Datensatzanzahl muss zwischen 1 und 10.000 liegen."
            });
        }

        BIND_DEFINITIONS.forEach((definition) => {
            const value = String(this.readValue(definition.name) || "").trim();
            if (!value || this.isFlowReference(value)) {
                return;
            }
            const errorString = this.validateLiteral(value, definition.dataType);
            if (errorString) {
                errors.push({ key: definition.name, errorString });
            }
        });

        if (
            objectName &&
            String(this.outputType || "").toLowerCase() !== objectName.toLowerCase()
        ) {
            errors.push({
                key: "recordsType",
                errorString:
                    "Der Output records muss auf denselben Objekttyp wie das Ausgabeobjekt gemappt sein. Ändere das Ausgabeobjekt einmal erneut, damit Flow Builder die Zuordnung speichert."
            });
        }

        this.validationMessage = errors.map((error) => error.errorString).join(" ");
        return errors;
    }

    validateLiteral(value, dataType) {
        if (dataType === "Number" && !Number.isFinite(Number(value))) {
            return "numberValue1 muss eine Zahl oder eine Flow-Referenz sein.";
        }
        if (dataType === "Boolean" && !/^(true|false)$/i.test(value)) {
            return "booleanValue1 muss true, false oder eine Flow-Referenz sein.";
        }
        if (dataType === "Date") {
            const datePatternMatches = /^\d{4}-\d{2}-\d{2}$/.test(value);
            const parsedDate = datePatternMatches
                ? new Date(`${value}T00:00:00Z`)
                : null;
            if (
                !parsedDate ||
                Number.isNaN(parsedDate.getTime()) ||
                parsedDate.toISOString().slice(0, 10) !== value
            ) {
                return "dateValue1 muss ein gültiges Datum im Format YYYY-MM-DD oder eine Flow-Referenz sein.";
            }
        }
        if (
            dataType === "DateTime" &&
            (!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,3})?(?:Z|[+-]\d{2}:\d{2})$/.test(value) ||
                Number.isNaN(Date.parse(value)))
        ) {
            return "dateTimeValue1 muss ein ISO-DateTime oder eine Flow-Referenz sein.";
        }
        return "";
    }

    hasSemicolonOutsideString(source) {
        let insideString = false;
        for (let index = 0; index < source.length; index += 1) {
            const current = source[index];
            if (insideString) {
                if (current === "\\" && index + 1 < source.length) {
                    index += 1;
                } else if (current === "'") {
                    insideString = false;
                }
            } else if (current === "'") {
                insideString = true;
            } else if (current === ";") {
                return true;
            }
        }
        return false;
    }
}