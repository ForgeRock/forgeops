const _ = require('lodash');
const fs = require("fs");
const data = fs.readFileSync(0, "utf-8");


// originally implemented here:
// https://stash.forgerock.org/projects/COMMONS/repos/forgerock-ui/browse/forgerock-ui-commons/src/main/js/org/forgerock/commons/ui/common/util/ObjectUtil.js

    var obj = {};

    /**
     * Translates an arbitrarily-complex object into a flat one composed of JSONPointer key-value pairs.
     * Example:
     *   toJSONPointerMap({"c": 2, "a": {"b": ['x','y','z',true]}}) returns:
     *   {/c: 2, /a/b/0: "x", /a/b/1: "y", /a/b/2: "z", /a/b/3: true}
     * @param {object} originalObject - the object to convert to a flat map of JSONPointer values
     */
    obj.toJSONPointerMap = function (originalObject) {
        var pointerList;
        pointerList = function (obj) {
            return _.chain(obj)
                .toPairs()
                .filter(function (p) {
                    return p[1] !== undefined;
                })
                .map(function (p) {
                    if (_.indexOf(["string","boolean","number"], (typeof p[1])) !== -1 ||
                        _.isEmpty(p[1]) ||
                        _.isArray(p[1])) {
                        return { "pointer": "/" + p[0], "value": p[1]};
                    } else {
                        return _.map(pointerList(p[1]), function (child) {
                            return {"pointer": "/" + p[0] + child.pointer, "value": child.value };
                        });
                    }
                })
                .flatten(true)
                .value();
        };

        return _.reduce(pointerList(originalObject), function (map, entry) {
            map[entry.pointer] = entry.value;
            return map;
        }, {});
    };

    /**
     * Uses a JSONPointer string to find a value within a provided object
     * Examples:
     *   getValueFromPointer({test:["apple", {"foo":"bar", "hello": "world"}]}, "/test/0") returns: "apple"
     *   getValueFromPointer({test:["apple", {"foo":"bar", "hello": "world"}]}, "/test/1/foo") returns: "bar"
     *   getValueFromPointer({test:["apple", {"foo":"bar", "hello": "world"}]}, "/test/1") returns:
     *      {"foo":"bar", "hello": "world"}
     *   getValueFromPointer({test:["apple", {"foo":"bar", "hello": "world"}]}, "/test2") returns: undefined
     *   getValueFromPointer({test:["apple", {"foo":"bar", "hello": "world"}]}, "/") returns:
            {test:["apple", {"foo":"bar", "hello": "world"}]}
     *
     * @param {object} object - the object to search within
     * @param {string} pointer - the JSONPointer to use to find the value within the object
     */
    obj.getValueFromPointer = function (object, pointer) {
        var pathParts = pointer.split("/");
        // remove first item which came from the leading slash
        pathParts.shift(1);
        if (pathParts[0] === "") { // the case when pointer is just "/"
            return object;
        }

        return _.reduce(pathParts, function (result, path) {
            if (_.isObject(result)) {
                return result[path];
            } else {
                return result;
            }
        }, object);
    };

    /**
     * Look through the provided object to see how far it can be traversed using a given JSONPointer string
     * Halts at the first undefined entry, or when it has reached the end of the pointer path.
     * Returns a JSONPointer that represents the point at which it was unable to go further
     * Examples:
     *   walkDefinedPath({test:["apple", {"foo":"bar", "hello": "world"}]}, "/test/0") returns: "/test/0"
     *   walkDefinedPath({test:["apple", {"foo":"bar", "hello": "world"}]}, "/test/3/foo") returns: "/test/3"
     *   walkDefinedPath({test:["apple", {"foo":"bar", "hello": "world"}]}, "/missing") returns: "/missing"
     *   walkDefinedPath({test:["apple", {"foo":"bar", "hello": "world"}]}, "/missing/bar") returns: "/missing"
     *
     * @param {object} object - the object to walk through
     * @param {string} pointer - the JSONPointer to use to walk through the object
     */
    obj.walkDefinedPath = function (object, pointer) {
        var finalPath = "",
            node = object,
            currentPathPart,
            pathParts = pointer.split("/");

        // remove first item which came from the leading slash
        pathParts.shift(1);

        // walk through the path, stopping when hitting undefined
        while (node !== undefined && node !== null && pathParts.length) {
            currentPathPart = pathParts.shift(1);
            finalPath += ("/" + currentPathPart);
            node = node[currentPathPart];
        }

        // if the whole object needs to be added....
        if (finalPath === "") {
            finalPath = "/";
        }
        return finalPath;
    };

    /**
     * Compare to Array values, interpeted as sets, to see if they contain the same values.
     * Important distinctive behavior of sets - order doesn't matter for equality.
     * @param {Array} set1 - an set of any values. Nested Arrays will also be interpreted as sets.
     * @param {Array} set2 - an set of any values. Nested Arrays will also be interpreted as sets.
     * Examples:
     *  isEqualSet([1], [1]) -> true
     *  isEqualSet([1], [1,3]) -> false
     *  isEqualSet([3,1], [1,3]) -> true
     *  isEqualSet([3,{a:1},1], [1,3,{a:1}]) -> true
     *  isEqualSet([3,{a:1},1], [1,3,{a:2}]) -> false
     *  isEqualSet([3,{a:1},['b','a'],1], [1,3,{a:1},['a','b']]) -> true
     */
    obj.isEqualSet = function (set1, set2) {
        var traverseSet = function (targetSet, result, sourceItem) {
            if (_.isArray(sourceItem)) {
                return result && _.find(targetSet, function (targetItem) {
                    return obj.isEqualSet(sourceItem,targetItem);
                }) !== undefined;
            } else if (_.isObject(sourceItem)) {
                return result && _.find(targetSet, sourceItem) !== undefined;
            } else {
                return result && _.indexOf(targetSet, sourceItem) !== -1;
            }
        };

        return _.reduce(set1, _.curry(traverseSet)(set2), true) &&
                _.reduce(set2, _.curry(traverseSet)(set1), true);
    };

    /**
     * Given a first set, return a subset containing all items which are not
     * present in the second set.
     * @param {Array} original set
     * @param {Array} secondary to intersect with
     * Examples:
     *  findItemsNotInSet([1,2,3],[2,3]) -> [1]
     *  findItemsNotInSet([1,2,3],[2,3,1]) -> []
     *  findItemsNotInSet([1,{a:1},3],[3,1,{a:2}]) -> [{a:1}]
     */
    obj.findItemsNotInSet = function (set1, set2) {
        return _.filter(set1, function (item1) {
            return !_.find(set2, function (item2) {
                return _.isEqual(item1,item2);
            });
        });
    };

    /**
     * Compares two objects and generates a patchset necessary to convert the second object to match the first
     * Examples:
     *   generatePatchSet({"a": 1, "b": 2}, {"a": 1}) returns:
     *   [{"operation":"add","field":"/b","value":2}]
     *
     *   generatePatchSet({"a": 1, "b": 2}, {"c": 1}) returns:
     *   [
     *     {"operation":"add","field":"/a","value":1},
     *     {"operation":"add","field":"/b","value":2},
     *     {"operation":"remove","field":"/c"}
     *   ]
     *
     *   generatePatchSet({"a": [1,2]}, {"a": [1,3]}) returns:
     *   [
     *     {"operation":"add","field":"/a/-","value":2},
     *     {"operation":"remove","field":"/a","value":3}
     *   ]
     *
     * @param {object} newObject - the object to build up to
     * @param {object} oldObject - the object to start from
     */
    obj.generatePatchSet = function (newObject, oldObject) {
        var newObjectClosure = newObject, // needed to have access to newObject within _ functions
            oldObjectClosure = oldObject, // needed to have access to oldObject within _ functions
            newPointerMap = obj.toJSONPointerMap(newObject),
            previousPointerMap = obj.toJSONPointerMap(oldObject),
            newValues = _.chain(newPointerMap)
                .toPairs()
                .filter(function (p) {
                    if (_.isArray(previousPointerMap[p[0]]) && _.isArray(p[1])) {
                        return !obj.isEqualSet(previousPointerMap[p[0]], p[1]);
                    } else {
                        return !_.isEqual(previousPointerMap[p[0]], p[1]);
                    }
                })
                .map(function (p) {
                    var finalPathToAdd = obj.walkDefinedPath(oldObjectClosure, p[0]),
                        newValueAtFinalPath = obj.getValueFromPointer(newObjectClosure, finalPathToAdd),
                        oldValueAtFinalPath = obj.getValueFromPointer(oldObjectClosure, finalPathToAdd),
                        setToPatchOperation = function (set, operation, path) {
                            return _.map(set, function (item) {
                                return {
                                    "operation": operation,
                                    "field": path,
                                    "value": item
                                };
                            });
                        };
                    if (_.isArray(newValueAtFinalPath) && _.isArray(oldValueAtFinalPath)) {
                        return setToPatchOperation(
                                obj.findItemsNotInSet(newValueAtFinalPath, oldValueAtFinalPath),
                                "add",
                                finalPathToAdd + "/-" // add to set syntax
                            ).concat(setToPatchOperation(
                                obj.findItemsNotInSet(oldValueAtFinalPath, newValueAtFinalPath),
                                "remove",
                                finalPathToAdd
                            ));
                    } else if (newValueAtFinalPath === null) {
                        return {
                            "operation": "remove",
                            "field": finalPathToAdd
                        };
                    } else {
                        return {
                            "operation": (oldValueAtFinalPath === undefined) ? "add" : "replace",
                            "field": finalPathToAdd,
                            "value": newValueAtFinalPath
                        };
                    }
                })
                .flatten()
                // Filter out duplicates which might result from adding whole containers
                // Have to stringify the patch operations to do object comparisons with uniq
                .uniq(JSON.stringify)
                .value(),
            removedValues = _.chain(previousPointerMap)
                .toPairs()
                .filter(function (p) {
                    return obj.getValueFromPointer(newObjectClosure, p[0]) === undefined;
                })
                .map(function (p) {
                    var finalPathToRemove = obj.walkDefinedPath(newObjectClosure, p[0]);
                    return { "operation": "remove", "field": finalPathToRemove };
                })
                // Filter out duplicates which might result from deleting whole containers
                // Have to stringify the patch operations to do object comparisons with uniq
                .uniq(JSON.stringify)
                .value();

        return newValues.concat(removedValues);
    };


const [oldObject, newObject] = data.split("=====").map(JSON.parse);

console.log(JSON.stringify(obj.generatePatchSet(newObject, oldObject), null, 4));
