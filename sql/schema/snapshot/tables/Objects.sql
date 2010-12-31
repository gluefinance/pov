CREATE SEQUENCE seqObjects;

CREATE TABLE Objects (
ObjectID        bigint   not null default nextval('seqObjects'),
ObjectTypeID    integer  not null,
SHA1            char(40) not null,
Content         text[]   not null,
PRIMARY KEY (ObjectID),
FOREIGN KEY (ObjectTypeID) REFERENCES ObjectTypes(ObjectTypeID),
UNIQUE(ObjectTypeID,SHA1)
);
