#!/usr/bin/env sh
# Sample script to create some indexes.
curl \
--request PUT \
--header "Content-Type: application/json" \
--data '{
    "settings" : {},
    "mappings" : {
        "access" : {
            "_source" : { "enabled" : true },
            "properties" : {
                "timestamp": {
                    "type": "date"
                },
                "eventName": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "transactionId": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "userId": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "trackingIds": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "server": {
                    "properties": {
                        "ip": {
                            "type": "string",
                            "index": "not_analyzed"
                        },
                        "port": {
                            "type": "integer"
                        }
                    }
                },
                "client": {
                    "properties": {
                        "ip": {
                            "type": "string",
                            "index": "not_analyzed"
                        },
                        "port": {
                            "type": "integer"
                        }
                    }
                },
                "request": {
                    "properties": {
                        "protocol": {
                            "type": "string",
                            "index": "not_analyzed"
                        },
                        "operation": {
                            "type": "string",
                            "index": "not_analyzed"
                        },
                        "detail": {
                            "type" : "nested"
                        }
                    }
                },
                "http": {
                    "properties": {
                        "request": {
                            "properties": {
                                "secure": {
                                    "type": "boolean"
                                },
                                "method": {
                                    "type": "string",
                                    "index": "not_analyzed"
                                },
                                "path": {
                                    "type": "string",
                                    "index": "not_analyzed"
                                },
                                "queryParameters": {
                                    "type" : "nested"
                                },
                                "headers": {
                                    "type" : "nested"
                                },
                                "cookies": {
                                    "type" : "nested"
                                }
                            }
                        },
                        "response": {
                            "properties": {
                                "headers": {
                                    "type" : "nested"
                                }
                            }
                        }
                    }
                },
                "response": {
                    "properties": {
                        "status": {
                            "type": "string",
                            "index": "not_analyzed"
                        },
                        "statusCode": {
                            "type": "string",
                            "index": "not_analyzed"
                        },
                        "detail": {
                            "type": "string",
                            "index": "not_analyzed"
                        },
                        "elapsedTime": {
                            "type": "integer"
                        },
                        "elapsedTimeUnits": {
                            "type": "string",
                            "index": "not_analyzed"
                        }
                    }
                },
                "roles": {
                    "type": "string",
                    "index": "not_analyzed"
                }
            }
        },
        "activity" : {
            "_source" : { "enabled" : true},
            "properties" : {
                "timestamp": {
                    "type": "date"
                },
                "eventName": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "transactionId": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "userId": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "trackingIds": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "runAs": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "objectId": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "operation": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "before": {
                    "type": "object"
                },
                "after": {
                    "type": "object"
                },
                "changedFields": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "revision": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "status": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "message": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "passwordChanged": {
                    "type": "boolean"
                }
            }
        },
        "authentication" : {
            "_source" : { "enabled" : true},
            "properties" : {
                "timestamp": {
                    "type": "date"
                },
                "eventName": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "transactionId": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "userId": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "trackingIds": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "result": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "principal": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "context": {
                    "type": "nested"
                },
                "entries": {
                    "properties": {
                        "moduleId": {
                            "type": "string",
                            "index": "not_analyzed"
                        },
                        "result": {
                            "type": "string",
                            "index": "not_analyzed"
                        },
                        "info": {
                            "type": "nested"
                        }
                    }
                }
            }
        },
        "config" : {
            "_source" : { "enabled" : true},
            "properties" : {
                "timestamp": {
                    "type": "date"
                },
                "eventName": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "transactionId": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "userId": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "trackingIds": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "runAs": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "objectId": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "operation": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "before": {
                    "type": "object"
                },
                "after": {
                    "type": "object"
                },
                "changedFields": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "revision": {
                    "type": "string",
                    "index": "not_analyzed"
                }
            }
        },
        "recon" : {
            "_source" : { "enabled" : true},
            "properties" : {
                "transactionId": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "timestamp": {
                    "type": "date"
                },
                "eventName": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "userId": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "trackingIds": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "action": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "exception": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "linkQualifier": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "mapping": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "message": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "messageDetail": {
                    "type": "object"
                },
                "situation": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "sourceObjectId": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "status": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "targetObjectId": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "reconciling": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "ambiguousTargetObjectIds": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "reconAction": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "entryType": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "reconId": {
                    "type": "string",
                    "index": "not_analyzed"
                }
            }
        },
        "sync" : {
            "_source" : { "enabled" : true},
            "properties" : {
                "transactionId": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "timestamp": {
                    "type": "date"
                },
                "eventName": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "userId": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "trackingIds": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "action": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "exception": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "linkQualifier": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "mapping": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "message": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "messageDetail": {
                    "type": "object"
                },
                "situation": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "sourceObjectId": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "status": {
                    "type": "string",
                    "index": "not_analyzed"
                },
                "targetObjectId": {
                    "type": "string",
                    "index": "not_analyzed"
                }
            }
        }
    }
}' "http://localhost:9200/audit"
