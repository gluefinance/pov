CREATE SEQUENCE seqSnapshots;

CREATE TABLE Snapshots (
SnapshotID  bigint      not null default nextval('seqSnapshots'),
RevisionID  text        not null,
Datestamp   timestamptz not null default now(),
Heartbeat   timestamptz not null default now(),
Active      integer     not null default 1,
PRIMARY KEY (SnapshotID),
FOREIGN KEY (RevisionID) REFERENCES Revisions(RevisionID)
);

CREATE UNIQUE INDEX Index_Snapshots_Active ON Snapshots(Active) WHERE Active = 1;
