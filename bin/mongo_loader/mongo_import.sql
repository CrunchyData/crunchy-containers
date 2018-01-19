create table MONGO_COLLECTION
(
json_imported jsonb
) 
WITH (OIDS=FALSE);

COPY MONGO_COLLECTION FROM '/pgloader/mongo/MONGO_COLLECTION.json';
