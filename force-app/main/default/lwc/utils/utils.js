function objectKeysToLowerCase (input) {
    if (typeof input !== 'object') return input;
    if (Array.isArray(input)) return input.map(objectKeysToLowerCase);
    return Object.keys(input).reduce(function (newObj, key) {
        let val = input[key];
        let newVal = (typeof val === 'object') && val !== null ? objectKeysToLowerCase(val) : val;
        newObj[key.toLowerCase()] = newVal;
        return newObj;
    }, {});
};

export default objectKeysToLowerCase;