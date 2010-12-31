CREATE SEQUENCE seqObjectTypes;

CREATE TABLE ObjectTypes (
ObjectTypeID    integer not null default nextval('seqObjectTypes'),
Name            text    not null,
PRIMARY KEY (ObjectTypeID),
UNIQUE(Name)
);
