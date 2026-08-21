/**
* Helper method collection for String operations not available in JS as native functions.
*
*/

/**
 * Treats the first argument as a pattern with incrementing placeholders in the {num} format, with num being the index value of the current element in the formattingArguments array.
 * Returns a string using the second argument for substitution and formatting. 
 * Non-string types in the second argument’s List are implicitly converted to strings.
 * Excess on both ends (formatting arguments as well as string to format) will be ignored. 
 * Documentation of original Apex String method: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_methods_system_string.htm
 * @param {String} stringToFormat - a String containing numbered merge fields starting with {0}. The number of merge fields should ideally correspond to the number of items in formattingArguments
 * @param {Array} formattingArguments - an Array containing any elements. These are converted to String, and replace the numbered merge fields in order.
 * @return {String} Formatted string - every merge field in stringToFormat with a corresponding element in formattingArguments replaced with the latter
 */
const stringFormat = ( stringToFormat, formattingArguments ) => {
    if(typeof stringToFormat === 'string' && stringToFormat !== null && stringToFormat !== ''){
        let stringToFormatCopy = stringToFormat;
        if(Array.isArray(formattingArguments) && formattingArguments.length > 0){
            // stringToFormat is a String and formattingArguments is an Array
            for(let formattingArgumentIndex in formattingArguments){
                // Perform replacement by calling String.replaceAll and replacing all occurrences of {formattingArgumentIndex}.
                // No error handling required as String.replaceAll returns original String if search parameter is not found.
                stringToFormatCopy = stringToFormatCopy.replaceAll('{' + formattingArgumentIndex + '}', formattingArguments[formattingArgumentIndex].toString());
            }
        }
        // formattingArguments is a non-empty Array: Return the modified String.
        // formattingArguments is either not an Array or an empty Array: Return the original String.
        return stringToFormatCopy;
    } else {
        // If stringToFormat not a String, a null value or an empty String, return an empty String
        return '';
    }
};

const stringIsNotBlank = ( stringToCheck ) => {
    // If String is empty, blank, null, or undefined
    if(!stringToCheck || 0 === stringToCheck.length || /^\s*$/.test(stringToCheck)){
        return false;
    }
    return true;
};

export { stringFormat, stringIsNotBlank };