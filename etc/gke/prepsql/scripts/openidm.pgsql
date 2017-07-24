DROP SCHEMA IF EXISTS openidm CASCADE;
CREATE SCHEMA openidm AUTHORIZATION openidm;

-- -----------------------------------------------------
-- Table openidm.objecttpyes
-- -----------------------------------------------------

CREATE TABLE openidm.objecttypes (
  id BIGSERIAL NOT NULL,
  objecttype VARCHAR(255) DEFAULT NULL,
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
-- Table openidm.relationships
-- -----------------------------------------------------

CREATE TABLE openidm.relationships (
  id BIGSERIAL NOT NULL,
  objecttypes_id BIGINT NOT NULL,
  objectid VARCHAR(255) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  fullobject JSON,
  PRIMARY KEY (id),
  CONSTRAINT fk_relationships_objecttypes FOREIGN KEY (objecttypes_id) REFERENCES openidm.objecttypes (id) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT idx_relationships_object UNIQUE (objecttypes_id, objectid)
);

CREATE INDEX idx_json_relationships_first ON openidm.relationships ( json_extract_path_text(fullobject, 'firstId'), json_extract_path_text(fullobject, 'firstPropertyName') );
CREATE INDEX idx_json_relationships_second ON openidm.relationships ( json_extract_path_text(fullobject, 'secondId'), json_extract_path_text(fullobject, 'secondPropertyName') );
CREATE INDEX idx_json_relationships ON openidm.relationships ( json_extract_path_text(fullobject, 'firstId'), json_extract_path_text(fullobject, 'firstPropertyName'), json_extract_path_text(fullobject, 'secondId'), json_extract_path_text(fullobject, 'secondPropertyName') );

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
-- Table openidm.securitykeys
-- -----------------------------------------------------

CREATE TABLE openidm.securitykeys (
  objectid VARCHAR(38) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  keypair TEXT,
  PRIMARY KEY (objectid)
);

-- -----------------------------------------------------
-- Table openidm.internaluser
-- -----------------------------------------------------

CREATE TABLE openidm.internaluser (
  objectid VARCHAR(255) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  pwd VARCHAR(510) DEFAULT NULL,
  roles VARCHAR(1024) DEFAULT NULL,
  PRIMARY KEY (objectid)
);


-- -----------------------------------------------------
-- Table openidm.internalrole
-- -----------------------------------------------------

CREATE TABLE openidm.internalrole (
  objectid VARCHAR(255) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  description VARCHAR(510) DEFAULT NULL,
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
  receiverId VARCHAR(38) NOT NULL,
  requesterId VARCHAR(38) NULL,
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
  targetid VARCHAR(255) NOT NULL,
  PRIMARY KEY (objectid)
);

CREATE INDEX idx_clusteredrecontargetids_reconid ON openidm.clusteredrecontargetids (reconid);
CREATE INDEX idx_clusteredrecontargetids_reconid_targetid ON openidm.clusteredrecontargetids (reconid, targetid);

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
-- Data for table openidm.internaluser
-- -----------------------------------------------------
START TRANSACTION;
INSERT INTO openidm.internaluser (objectid, rev, pwd, roles) VALUES ('openidm-admin', '0', 'openidm-admin', '[ { "_ref" : "repo/internal/role/openidm-admin" }, { "_ref" : "repo/internal/role/openidm-authorized" } ]');
INSERT INTO openidm.internaluser (objectid, rev, pwd, roles) VALUES ('anonymous', '0', 'anonymous', '[ { "_ref" : "repo/internal/role/openidm-reg" } ]');

INSERT INTO openidm.internalrole (objectid, rev, description)
VALUES
('openidm-authorized', '0', 'Basic minimum user'),
('openidm-admin', '0', 'Administrative access'),
('openidm-cert', '0', 'Authenticated via certificate'),
('openidm-tasks-manager', '0', 'Allowed to reassign workflow tasks'),
('openidm-reg', '0', 'Anonymous access');

COMMIT;

CREATE INDEX idx_json_clusterobjects_timestamp ON openidm.clusterobjects ( json_extract_path_text(fullobject, 'timestamp') );
CREATE INDEX idx_json_clusterobjects_state ON openidm.clusterobjects ( json_extract_path_text(fullobject, 'state') );
