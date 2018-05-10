-- -----------------------------------------------------
-- Table openidm.auditauthentication
-- -----------------------------------------------------
CREATE TABLE openidm.auditauthentication (
  objectid VARCHAR(56) NOT NULL,
  transactionid VARCHAR(255) NOT NULL,
  activitydate VARCHAR(29) NOT NULL,
  userid VARCHAR(255) DEFAULT NULL,
  eventname VARCHAR(50) DEFAULT NULL,
  provider VARCHAR(255) DEFAULT NULL,
  method VARCHAR(25) DEFAULT NULL,
  result VARCHAR(255) DEFAULT NULL,
  principals TEXT,
  context TEXT,
  entries TEXT,
  trackingids TEXT,
  PRIMARY KEY (objectid)
);

-- -----------------------------------------------------
-- Table openidm.auditaccess
-- -----------------------------------------------------

CREATE TABLE openidm.auditaccess (
  objectid VARCHAR(56) NOT NULL,
  activitydate VARCHAR(29) NOT NULL,
  eventname VARCHAR(255),
  transactionid VARCHAR(255) NOT NULL,
  userid VARCHAR(255) DEFAULT NULL,
  trackingids TEXT,
  server_ip VARCHAR(40),
  server_port VARCHAR(5),
  client_ip VARCHAR(40),
  client_port VARCHAR(5),
  request_protocol VARCHAR(255) NULL ,
  request_operation VARCHAR(255) NULL ,
  request_detail TEXT NULL ,
  http_request_secure VARCHAR(255) NULL ,
  http_request_method VARCHAR(255) NULL ,
  http_request_path VARCHAR(255) NULL ,
  http_request_queryparameters TEXT NULL ,
  http_request_headers TEXT NULL ,
  http_request_cookies TEXT NULL ,
  http_response_headers TEXT NULL ,
  response_status VARCHAR(255) NULL ,
  response_statuscode VARCHAR(255) NULL ,
  response_elapsedtime VARCHAR(255) NULL ,
  response_elapsedtimeunits VARCHAR(255) NULL ,
  response_detail TEXT NULL ,
  roles TEXT NULL ,
  PRIMARY KEY (objectid)
);

-- -----------------------------------------------------
-- Table openidm.auditconfig
-- -----------------------------------------------------

CREATE TABLE openidm.auditconfig (
  objectid VARCHAR(56) NOT NULL,
  activitydate VARCHAR(29) NOT NULL,
  eventname VARCHAR(255) DEFAULT NULL,
  transactionid VARCHAR(255) NOT NULL,
  userid VARCHAR(255) DEFAULT NULL,
  trackingids TEXT,
  runas VARCHAR(255) DEFAULT NULL,
  configobjectid VARCHAR(255) NULL ,
  operation VARCHAR(255) NULL ,
  beforeObject TEXT,
  afterObject TEXT,
  changedfields TEXT DEFAULT NULL,
  rev VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (objectid)
);

-- -----------------------------------------------------
-- Table openidm.auditactivity
-- -----------------------------------------------------

CREATE TABLE openidm.auditactivity (
  objectid VARCHAR(56) NOT NULL,
  activitydate VARCHAR(29) NOT NULL,
  eventname VARCHAR(255) DEFAULT NULL,
  transactionid VARCHAR(255) NOT NULL,
  userid VARCHAR(255) DEFAULT NULL,
  trackingids TEXT,
  runas VARCHAR(255) DEFAULT NULL,
  activityobjectid VARCHAR(255) NULL ,
  operation VARCHAR(255) NULL ,
  subjectbefore TEXT,
  subjectafter TEXT,
  changedfields TEXT DEFAULT NULL,
  subjectrev VARCHAR(255) DEFAULT NULL,
  passwordchanged VARCHAR(5) DEFAULT NULL,
  message TEXT,
  provider VARCHAR(255) DEFAULT NULL,
  context VARCHAR(25) DEFAULT NULL,
  status VARCHAR(20),
  PRIMARY KEY (objectid)
);

-- -----------------------------------------------------
-- Table openidm.auditrecon
-- -----------------------------------------------------

CREATE TABLE openidm.auditrecon (
  objectid VARCHAR(56) NOT NULL,
  transactionid VARCHAR(255) NOT NULL,
  activitydate VARCHAR(29) NOT NULL,
  eventname VARCHAR(50) DEFAULT NULL,
  userid VARCHAR(255) DEFAULT NULL,
  trackingids TEXT,
  activity VARCHAR(24) DEFAULT NULL,
  exceptiondetail TEXT,
  linkqualifier VARCHAR(255) DEFAULT NULL,
  mapping VARCHAR(511) DEFAULT NULL,
  message TEXT,
  messagedetail TEXT,
  situation VARCHAR(24) DEFAULT NULL,
  sourceobjectid VARCHAR(511) DEFAULT NULL,
  status VARCHAR(20) DEFAULT NULL,
  targetobjectid VARCHAR(511) DEFAULT NULL,
  reconciling VARCHAR(12) DEFAULT NULL,
  ambiguoustargetobjectids TEXT,
  reconaction VARCHAR(36) DEFAULT NULL,
  entrytype VARCHAR(7) DEFAULT NULL,
  reconid VARCHAR(56) DEFAULT NULL,
  PRIMARY KEY (objectid)
);

CREATE INDEX idx_auditrecon_reconid ON openidm.auditrecon (reconid);
CREATE INDEX idx_auditrecon_entrytype ON openidm.auditrecon (entrytype);

-- -----------------------------------------------------
-- Table openidm.auditsync
-- -----------------------------------------------------

CREATE TABLE openidm.auditsync (
  objectid VARCHAR(56) NOT NULL,
  transactionid VARCHAR(255) NOT NULL,
  activitydate VARCHAR(29) NOT NULL,
  eventname VARCHAR(50) DEFAULT NULL,
  userid VARCHAR(255) DEFAULT NULL,
  trackingids TEXT,
  activity VARCHAR(24) DEFAULT NULL,
  exceptiondetail TEXT,
  linkqualifier VARCHAR(255) DEFAULT NULL,
  mapping VARCHAR(511) DEFAULT NULL,
  message TEXT,
  messagedetail TEXT,
  situation VARCHAR(24) DEFAULT NULL,
  sourceobjectid VARCHAR(511) DEFAULT NULL,
  status VARCHAR(20) DEFAULT NULL,
  targetobjectid VARCHAR(511) DEFAULT NULL,
  PRIMARY KEY (objectid)
);