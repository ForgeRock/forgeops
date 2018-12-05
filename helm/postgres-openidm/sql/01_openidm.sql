DROP SCHEMA IF EXISTS openidm CASCADE;
CREATE SCHEMA openidm AUTHORIZATION openidm;

-- -----------------------------------------------------
-- Table openidm.objecttypes
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
-- Table openidm.uinotification
-- -----------------------------------------------------
CREATE TABLE openidm.uinotification (
  objectid VARCHAR(38) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  notificationType VARCHAR(255) NOT NULL,
  createDate VARCHAR(38) NOT NULL,
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
  createDate VARCHAR(38) NOT NULL,
  PRIMARY KEY (objectid)
);
CREATE INDEX indx_syncqueue_mapping_state_createdate ON openidm.syncqueue (mapping, state, createDate);
CREATE INDEX indx_syncqueue_mapping_retries ON openidm.syncqueue (mapping, remainingRetries);


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

