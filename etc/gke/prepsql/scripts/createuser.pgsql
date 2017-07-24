
-- This user will already exist.
-- create user openidm with password 'openidm';

-- The openidm role needs to be granted to postgres to create the database.
grant openidm to postgres;

drop database openidm;

create database openidm encoding 'utf8' owner openidm;

-- openidm user will already have these privileges.
-- grant all privileges on database openidm to openidm;
