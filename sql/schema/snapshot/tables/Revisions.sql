CREATE TABLE Revisions (
RevisionID text        not null,
ObjectIDs  text[]      not null,
Datestamp  timestamptz not null default now(),
PRIMARY KEY (RevisionID)
);
