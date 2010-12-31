-- The ObjectTypeID determines the order of creating/dropping objects
CREATE TABLE ObjectTypes (
ObjectTypeID    integer not null,
Name            text    not null,
PRIMARY KEY (ObjectTypeID),
UNIQUE(Name)
);
