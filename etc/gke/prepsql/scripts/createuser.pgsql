


-- Creates the role (user) for this database.
create role :idmuser login password :password;
-- Grant permission to postgres so we can create the database owned by this user.
grant :idmuser to postgres;

-- Create the database. A PG instance might have many databases (dev,qa, tenant1, etc.).
create database :idmuser  encoding 'utf8' owner :idmuser;
