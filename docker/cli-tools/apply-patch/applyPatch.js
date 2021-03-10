const _ = require('lodash');
const fs = require("fs");
const data = fs.readFileSync(0, "utf-8");

/**
 * Given a JSON object and a jsonPath, this function returns a structure like so:
 * {
        obj: object reference,
        field: key usable for referring to entry in the above object reference
    }

    The point of this function is to allow the caller to make changes to the provided object
    indirectly, via reference. For example, if you have an object like so:

        var myObj = {
            "entries": [
                {
                    "name": "foo"
                },
                {
                    "name": "bar"
                }
            ]
        };

    You can use a JSON Path such as "/entries/0/name" and be able to make changes to that base object
    with the return value. To continue the above example, if you call getTargetObjRef like so:

        var targetRef = getTargetObjRef(myObj, "/entries/0/name");

    You can then change the value found at the path like so:

        targetRef.obj[targetRef.field] = "blah";

    Because JS preserves references within objects, this change will result in the original object being changed as well:

        myObj.entries[0].name === "blah" // true, thanks to the change made previously
 */
var getTargetObjRef = (obj, jsonPath) => {
    var pathElements = jsonPath.replace(/(^\/)|(\/$)/g, "").split("/"),
        lastPathElement = pathElements.pop(),
        targetObjRef = pathElements.reduce((currentPointer, pathElement, index) => {
            if (typeof currentPointer[pathElement] === "undefined" || currentPointer[pathElement] === null) {
                if (lastPathElement === "-" && index === pathElements.length-1) {
                    currentPointer[pathElement] = [];
                } else {
                    currentPointer[pathElement] = {};
                }
            }

            if (typeof currentPointer[pathElement] === "object") {
                return currentPointer[pathElement];
            } else {
                throw "Cannot reference jsonPath " + jsonPath + " for given obj " + JSON.stringify(obj);
            }
        }, obj);

    return {
        obj: targetObjRef,
        field: lastPathElement
    };
}

var applyPatchset = (sourceObj, patchSet) => patchSet.reduce((result, patchCmd) => {
    switch (patchCmd.operation) {
        case "add":
            var targetRef = getTargetObjRef(result, patchCmd.field);
            if (targetRef.field === "-") {
                targetRef.obj.push(patchCmd.value)
            } else {
                targetRef.obj[targetRef.field] = patchCmd.value;
            }
        break;
        case "remove":
            var targetRef = getTargetObjRef(result, patchCmd.field);
            if (typeof patchCmd.value === "undefined") {
                // special case handling for removing an array element specified like /path/to/array/1
                if (Array.isArray(targetRef.obj) && !isNaN(parseInt(targetRef.field))) {
                    var targetArrayRef = getTargetObjRef(result, patchCmd.field.replace(/\/\d+$/, ""));
                    targetArrayRef.obj[targetArrayRef.field] = targetArrayRef.obj[targetArrayRef.field].filter((val,index) => {
                        return index !== parseInt(targetRef.field);
                    });
                } else {
                    delete targetRef.obj[targetRef.field];
                }
            } else if (Array.isArray(targetRef.obj[targetRef.field])) {
                targetRef.obj[targetRef.field] = targetRef.obj[targetRef.field].filter((existingValue) => {
                    return !_.isEqual(existingValue, patchCmd.value);
                });
            } else {
                throw "Cannot remove value from non-array " + patchCmd.field;
            }
        break;
        case "replace":
            var targetRef = getTargetObjRef(result, patchCmd.field);
            targetRef.obj[targetRef.field] = patchCmd.value;
        break;
        case "copy":
            var targetRef = getTargetObjRef(result, patchCmd.field),
                fromRef = getTargetObjRef(result, patchCmd.from);
            targetRef.obj[targetRef.field] = _.cloneDeep(fromRef.obj[fromRef.field]);
        break;
        case "move":
            var targetRef = getTargetObjRef(result, patchCmd.field),
                fromRef = getTargetObjRef(result, patchCmd.from);
            targetRef.obj[targetRef.field] = _.cloneDeep(fromRef.obj[fromRef.field]);
            delete fromRef.obj[fromRef.field];
        break;
        case "increment":
            var targetRef = getTargetObjRef(result, patchCmd.field),
                numberValue = parseFloat(targetRef.obj[targetRef.field]);
            if (isNaN(numberValue)) {
                throw "Unable to increment field at " + patchCmd.field;
            }
            if (typeof patchCmd.value === "undefined") {
                targetRef.obj[targetRef.field] = numberValue+1;
            } else {
                targetRef.obj[targetRef.field] = numberValue+parseFloat(patchCmd.value);
            }
        break;
        default:
            throw "Unrecognized operation " + patchCmd.operation;
    }
    return result;
}, _.cloneDeep(sourceObj));


const [source, patchSet] = data.split("=====").map(JSON.parse);

console.log(JSON.stringify(applyPatchset(source, patchSet), null, 4));
