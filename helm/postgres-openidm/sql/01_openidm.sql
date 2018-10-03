DROP SCHEMA IF EXISTS openidm CASCADE;
CREATE SCHEMA openidm AUTHORIZATION openidm;

-- -----------------------------------------------------
-- Table openidm.objecttpyes
-- -----------------------------------------------------

CREATE TABLE openidm.objecttypes (
  id BIGSERIAL NOT NULL,
  objecttype VARCHAR(255) NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT idx_objecttypes_objecttype UNIQUE (objecttype)
);



-- -----------------------------------------------------
-- Table openidm.genericobjects
-- -----------------------------------------------------

CREATE TABLE openidm.genericobjects (
  id BIGSERIAL NOT NULL,
  objecttypes_id BIGINT NOT NULL,
  objectid VARCHAR(255) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  fullobject JSON,
  PRIMARY KEY (id),
  CONSTRAINT fk_genericobjects_objecttypes FOREIGN KEY (objecttypes_id) REFERENCES openidm.objecttypes (id) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT idx_genericobjects_object UNIQUE (objecttypes_id, objectid)
);
CREATE INDEX idx_genericobjects_reconid on openidm.genericobjects (json_extract_path_text(fullobject, 'reconId'), objecttypes_id);


-- -----------------------------------------------------
-- Table openidm.genericobjectproperties
-- -----------------------------------------------------

CREATE TABLE openidm.genericobjectproperties (
  genericobjects_id BIGINT NOT NULL,
  propkey VARCHAR(255) NOT NULL,
  proptype VARCHAR(32) DEFAULT NULL,
  propvalue TEXT,
  PRIMARY KEY (genericobjects_id, propkey),
  CONSTRAINT fk_genericobjectproperties_genericobjects FOREIGN KEY (genericobjects_id) REFERENCES openidm.genericobjects (id) ON DELETE CASCADE ON UPDATE NO ACTION
);
CREATE INDEX fk_genericobjectproperties_genericobjects ON openidm.genericobjectproperties (genericobjects_id);
CREATE INDEX idx_genericobjectproperties_prop ON openidm.genericobjectproperties (propkey,propvalue);


-- -----------------------------------------------------
-- Table openidm.managedobjects
-- -----------------------------------------------------

CREATE TABLE openidm.managedobjects (
  id BIGSERIAL NOT NULL,
  objecttypes_id BIGINT NOT NULL,
  objectid VARCHAR(255) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  fullobject JSON,
  PRIMARY KEY (id),
  CONSTRAINT fk_managedobjects_objectypes FOREIGN KEY (objecttypes_id) REFERENCES openidm.objecttypes (id) ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE UNIQUE INDEX idx_managedobjects_object ON openidm.managedobjects (objecttypes_id,objectid);
-- Note that the next two indices apply only to role objects, as only role objects have a condition or temporalConstraints
CREATE INDEX idx_json_managedobjects_roleCondition ON openidm.managedobjects
    ( json_extract_path_text(fullobject, 'condition') );
CREATE INDEX idx_json_managedobjects_roleTemporalConstraints ON openidm.managedobjects
    ( json_extract_path_text(fullobject, 'temporalConstraints') );


-- -----------------------------------------------------
-- Table openidm.managedobjectproperties
-- -----------------------------------------------------

CREATE TABLE openidm.managedobjectproperties (
  managedobjects_id BIGINT NOT NULL,
  propkey VARCHAR(255) NOT NULL,
  proptype VARCHAR(32) DEFAULT NULL,
  propvalue TEXT,
  PRIMARY KEY (managedobjects_id, propkey),
  CONSTRAINT fk_managedobjectproperties_managedobjects FOREIGN KEY (managedobjects_id) REFERENCES openidm.managedobjects (id) ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE INDEX fk_managedobjectproperties_managedobjects ON openidm.managedobjectproperties (managedobjects_id);
CREATE INDEX idx_managedobjectproperties_prop ON openidm.managedobjectproperties (propkey,propvalue);



-- -----------------------------------------------------
-- Table openidm.configobjects
-- -----------------------------------------------------

CREATE TABLE openidm.configobjects (
  id BIGSERIAL NOT NULL,
  objecttypes_id BIGINT NOT NULL,
  objectid VARCHAR(255) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  fullobject JSON,
  PRIMARY KEY (id),
  CONSTRAINT fk_configobjects_objecttypes FOREIGN KEY (objecttypes_id) REFERENCES openidm.objecttypes (id) ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE UNIQUE INDEX idx_configobjects_object ON openidm.configobjects (objecttypes_id,objectid);
CREATE INDEX fk_configobjects_objecttypes ON openidm.configobjects (objecttypes_id);


-- -----------------------------------------------------
-- Table openidm.configobjectproperties
-- -----------------------------------------------------

CREATE TABLE openidm.configobjectproperties (
  configobjects_id BIGINT NOT NULL,
  propkey VARCHAR(255) NOT NULL,
  proptype VARCHAR(255) DEFAULT NULL,
  propvalue TEXT,
  PRIMARY KEY (configobjects_id, propkey),
  CONSTRAINT fk_configobjectproperties_configobjects FOREIGN KEY (configobjects_id) REFERENCES openidm.configobjects (id) ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE INDEX fk_configobjectproperties_configobjects ON openidm.configobjectproperties (configobjects_id);
CREATE INDEX idx_configobjectproperties_prop ON openidm.configobjectproperties (propkey,propvalue);


-- -----------------------------------------------------
-- Table openidm.notificationobjects
-- -----------------------------------------------------

CREATE TABLE openidm.notificationobjects (
  id BIGSERIAL NOT NULL,
  objecttypes_id BIGINT NOT NULL,
  objectid VARCHAR(255) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  fullobject JSON,
  PRIMARY KEY (id),
  CONSTRAINT fk_notificationobjects_objecttypes FOREIGN KEY (objecttypes_id) REFERENCES openidm.objecttypes (id) ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE UNIQUE INDEX idx_notificationobjects_object ON openidm.notificationobjects (objecttypes_id,objectid);
CREATE INDEX fk_notificationobjects_objecttypes ON openidm.notificationobjects (objecttypes_id);


-- -----------------------------------------------------
-- Table openidm.notificationobjectproperties
-- -----------------------------------------------------

CREATE TABLE openidm.notificationobjectproperties (
  notificationobjects_id BIGINT NOT NULL,
  propkey VARCHAR(255) NOT NULL,
  proptype VARCHAR(255) DEFAULT NULL,
  propvalue TEXT,
  PRIMARY KEY (notificationobjects_id, propkey),
  CONSTRAINT fk_notificationobjectproperties_notificationobjects FOREIGN KEY (notificationobjects_id) REFERENCES openidm.notificationobjects (id) ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE INDEX fk_notificationobjectproperties_notificationobjects ON openidm.notificationobjectproperties (notificationobjects_id);
CREATE INDEX idx_notificationobjectproperties_prop ON openidm.notificationobjectproperties (propkey,propvalue);


-- -----------------------------------------------------
-- Table openidm.relationships
-- -----------------------------------------------------

CREATE TABLE openidm.relationships (
  id BIGSERIAL NOT NULL,
  objecttypes_id BIGINT NOT NULL,
  objectid VARCHAR(255) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  fullobject JSON,
  firstresourcecollection VARCHAR(255),
  firstresourceid VARCHAR(56),
  firstpropertyname VARCHAR(100),
  secondresourcecollection VARCHAR(255),
  secondresourceid VARCHAR(56),
  secondpropertyname VARCHAR(100),
  properties JSON,
  PRIMARY KEY (id),
  CONSTRAINT fk_relationships_objecttypes FOREIGN KEY (objecttypes_id) REFERENCES openidm.objecttypes (id) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT idx_relationships_object UNIQUE (objecttypes_id, objectid)
);
CREATE INDEX idx_json_relationships ON openidm.relationships ( json_extract_path_text(fullobject, 'firstResourceCollection'), json_extract_path_text(fullobject, 'firstResourceId'), json_extract_path_text(fullobject, 'firstPropertyName'), json_extract_path_text(fullobject, 'secondResourceCollection'), json_extract_path_text(fullobject, 'secondResourceId'), json_extract_path_text(fullobject, 'secondPropertyName') );
CREATE INDEX idx_json_relationships_first_object ON openidm.relationships ( firstresourcecollection, firstresourceid, firstpropertyname );
CREATE INDEX idx_json_relationships_second_object ON openidm.relationships ( secondresourcecollection, secondresourceid, secondpropertyname );

-- -----------------------------------------------------
-- Table openidm.relationshipproperties (not used in postgres)
-- -----------------------------------------------------

CREATE TABLE openidm.relationshipproperties (
  relationships_id BIGINT NOT NULL,
  propkey VARCHAR(255) NOT NULL,
  proptype VARCHAR(32) DEFAULT NULL,
  propvalue TEXT,
  PRIMARY KEY (relationships_id, propkey),
  CONSTRAINT fk_relationshipproperties_relationships FOREIGN KEY (relationships_id) REFERENCES openidm.relationships (id) ON DELETE CASCADE ON UPDATE NO ACTION
);
CREATE INDEX fk_relationshipproperties_relationships ON openidm.relationshipproperties (relationships_id);
CREATE INDEX idx_relationshipproperties_prop ON openidm.relationshipproperties (propkey,propvalue);


-- -----------------------------------------------------
-- Table openidm.links
-- -----------------------------------------------------

CREATE TABLE openidm.links (
  objectid VARCHAR(38) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  linktype VARCHAR(50) NOT NULL,
  linkqualifier VARCHAR(50) NOT NULL,
  firstid VARCHAR(255) NOT NULL,
  secondid VARCHAR(255) NOT NULL,
  PRIMARY KEY (objectid)
);

CREATE UNIQUE INDEX idx_links_first ON openidm.links (linktype, linkqualifier, firstid);
CREATE UNIQUE INDEX idx_links_second ON openidm.links (linktype, linkqualifier, secondid);


-- -----------------------------------------------------
-- Table openidm.internaluser
-- -----------------------------------------------------

CREATE TABLE openidm.internaluser (
  objectid VARCHAR(255) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  pwd VARCHAR(510) DEFAULT NULL,
  PRIMARY KEY (objectid)
);


-- -----------------------------------------------------
-- Table openidm.internalrole
-- -----------------------------------------------------

CREATE TABLE openidm.internalrole (
  objectid VARCHAR(255) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  name VARCHAR(64) DEFAULT NULL,
  description VARCHAR(510) DEFAULT NULL,
  temporalConstraints VARCHAR(1024) DEFAULT NULL,
  condition VARCHAR(1024) DEFAULT NULL,
  PRIMARY KEY (objectid)
);


-- -----------------------------------------------------
-- Table openidm.internalprivilege
-- -----------------------------------------------------

CREATE TABLE openidm.internalprivilege (
  objectid VARCHAR(255) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  name VARCHAR(64) DEFAULT NULL,
  description VARCHAR(510) DEFAULT NULL,
  path VARCHAR(1024) NOT NULL,
  permissions VARCHAR(1024) NOT NULL,
  actions VARCHAR(1024) DEFAULT NULL,
  filter VARCHAR(1024) DEFAULT NULL,
  accessflags TEXT DEFAULT NULL,
  PRIMARY KEY (objectid)
);


-- -----------------------------------------------------
-- Table openidm.schedulerobjects
-- -----------------------------------------------------
CREATE TABLE openidm.schedulerobjects (
  id BIGSERIAL NOT NULL,
  objecttypes_id BIGINT NOT NULL,
  objectid VARCHAR(255) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  fullobject JSON,
  PRIMARY KEY (id),
  CONSTRAINT fk_schedulerobjects_objectypes FOREIGN KEY (objecttypes_id) REFERENCES openidm.objecttypes (id) ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE UNIQUE INDEX idx_schedulerobjects_object ON openidm.schedulerobjects (objecttypes_id,objectid);
CREATE INDEX fk_schedulerobjects_objectypes ON openidm.schedulerobjects (objecttypes_id);


-- -----------------------------------------------------
-- Table openidm.schedulerobjectproperties
-- -----------------------------------------------------
CREATE TABLE openidm.schedulerobjectproperties (
  schedulerobjects_id BIGINT NOT NULL,
  propkey VARCHAR(255) NOT NULL,
  proptype VARCHAR(32) DEFAULT NULL,
  propvalue TEXT,
  PRIMARY KEY (schedulerobjects_id, propkey),
  CONSTRAINT fk_schedulerobjectproperties_schedulerobjects FOREIGN KEY (schedulerobjects_id) REFERENCES openidm.schedulerobjects (id) ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE INDEX fk_schedulerobjectproperties_schedulerobjects ON openidm.schedulerobjectproperties (schedulerobjects_id);
CREATE INDEX idx_schedulerobjectproperties_prop ON openidm.schedulerobjectproperties (propkey,propvalue);


-- -----------------------------------------------------
-- Table openidm.uinotification
-- -----------------------------------------------------
CREATE TABLE openidm.uinotification (
  objectid VARCHAR(38) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  notificationType VARCHAR(255) NOT NULL,
  createDate VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  requester VARCHAR(255) NULL,
  receiverId VARCHAR(255) NOT NULL,
  requesterId VARCHAR(255) NULL,
  notificationSubtype VARCHAR(255) NULL,
  PRIMARY KEY (objectid)
);
CREATE INDEX idx_uinotification_receiverId ON openidm.uinotification (receiverId);


-- -----------------------------------------------------
-- Table openidm.clusterobjects
-- -----------------------------------------------------
CREATE TABLE openidm.clusterobjects (
  id BIGSERIAL NOT NULL,
  objecttypes_id BIGINT NOT NULL,
  objectid VARCHAR(255) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  fullobject JSON,
  PRIMARY KEY (id),
  CONSTRAINT fk_clusterobjects_objectypes FOREIGN KEY (objecttypes_id) REFERENCES openidm.objecttypes (id) ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE UNIQUE INDEX idx_clusterobjects_object ON openidm.clusterobjects (objecttypes_id,objectid);
CREATE INDEX fk_clusterobjects_objectypes ON openidm.clusterobjects (objecttypes_id);

CREATE INDEX idx_json_clusterobjects_timestamp ON openidm.clusterobjects ( json_extract_path_text(fullobject, 'timestamp') );
CREATE INDEX idx_json_clusterobjects_state ON openidm.clusterobjects ( json_extract_path_text(fullobject, 'state') );
CREATE INDEX idx_json_clusterobjects_event_instanceid ON openidm.clusterobjects ( json_extract_path_text(fullobject, 'type'), json_extract_path_text(fullobject, 'instanceId') );

-- -----------------------------------------------------
-- Table openidm.clusterobjectproperties
-- -----------------------------------------------------
CREATE TABLE openidm.clusterobjectproperties (
  clusterobjects_id BIGINT NOT NULL,
  propkey VARCHAR(255) NOT NULL,
  proptype VARCHAR(32) DEFAULT NULL,
  propvalue TEXT,
  PRIMARY KEY (clusterobjects_id, propkey),
  CONSTRAINT fk_clusterobjectproperties_clusterobjects FOREIGN KEY (clusterobjects_id) REFERENCES openidm.clusterobjects (id) ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE INDEX fk_clusterobjectproperties_clusterobjects ON openidm.clusterobjectproperties (clusterobjects_id);
CREATE INDEX idx_clusterobjectproperties_prop ON openidm.clusterobjectproperties (propkey,propvalue);

-- -----------------------------------------------------
-- Table openidm.clusteredrecontargetids
-- -----------------------------------------------------

CREATE TABLE openidm.clusteredrecontargetids (
  objectid VARCHAR(38) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  reconid VARCHAR(255) NOT NULL,
  targetids JSON NOT NULL,
  PRIMARY KEY (objectid)
);

CREATE INDEX idx_clusteredrecontargetids_reconid ON openidm.clusteredrecontargetids (reconid);

-- -----------------------------------------------------
-- Table openidm.updateobjects
-- -----------------------------------------------------

CREATE TABLE openidm.updateobjects (
  id BIGSERIAL NOT NULL,
  objecttypes_id BIGINT NOT NULL,
  objectid VARCHAR(255) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  fullobject JSON,
  PRIMARY KEY (id),
  CONSTRAINT fk_updateobjects_objecttypes FOREIGN KEY (objecttypes_id) REFERENCES openidm.objecttypes (id) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT idx_updateobjects_object UNIQUE (objecttypes_id, objectid)
);



-- -----------------------------------------------------
-- Table openidm.updateobjectproperties
-- -----------------------------------------------------

CREATE TABLE openidm.updateobjectproperties (
  updateobjects_id BIGINT NOT NULL,
  propkey VARCHAR(255) NOT NULL,
  proptype VARCHAR(32) DEFAULT NULL,
  propvalue TEXT,
  PRIMARY KEY (updateobjects_id, propkey),
  CONSTRAINT fk_updateobjectproperties_updateobjects FOREIGN KEY (updateobjects_id) REFERENCES openidm.updateobjects (id) ON DELETE CASCADE ON UPDATE NO ACTION
);
CREATE INDEX fk_updateobjectproperties_updateobjects ON openidm.updateobjectproperties (updateobjects_id);
CREATE INDEX idx_updateobjectproperties_prop ON openidm.updateobjectproperties (propkey,propvalue);

-- -----------------------------------------------------
-- Table openidm.syncqueue
-- -----------------------------------------------------
CREATE TABLE openidm.syncqueue (
  objectid VARCHAR(38) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  syncAction VARCHAR(38) NOT NULL,
  resourceCollection VARCHAR(38) NOT NULL,
  resourceId VARCHAR(255) NOT NULL,
  mapping VARCHAR(255) NOT NULL,
  objectRev VARCHAR(38) DEFAULT NULL,
  oldObject JSON,
  newObject JSON,
  context JSON,
  state VARCHAR(38) NOT NULL,
  nodeId VARCHAR(255) DEFAULT NULL,
  remainingRetries VARCHAR(38) NOT NULL,
  createDate VARCHAR(255) NOT NULL,
  PRIMARY KEY (objectid)
);
CREATE INDEX indx_syncqueue_mapping_state_createdate ON openidm.syncqueue (mapping, state, createDate);
CREATE INDEX indx_syncqueue_mapping_retries ON openidm.syncqueue (mapping, remainingRetries);
CREATE INDEX indx_syncqueue_mapping_resourceid ON openidm.syncqueue (mapping, resourceId);


-- -----------------------------------------------------
-- Table openidm.locks
-- -----------------------------------------------------

CREATE TABLE openidm.locks (
  objectid VARCHAR(38) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  nodeid VARCHAR(255),
  PRIMARY KEY (objectid)
);

CREATE INDEX idx_locks_nodeid ON openidm.locks (nodeid);


-- -----------------------------------------------------
-- Table openidm.files
-- -----------------------------------------------------

CREATE TABLE openidm.files (
  objectid VARCHAR(38) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  content TEXT,
  PRIMARY KEY (objectid)
);

