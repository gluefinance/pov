CREATE SEQUENCE seqRevisions;
CREATE TABLE Revisions (
RevisionID bigint not null default nextval('seqRevisions'),
ObjectIDs bigint[] not null,
Datestamp timestamptz not null default now(),
PRIMARY KEY (RevisionID)
);
