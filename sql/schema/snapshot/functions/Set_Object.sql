CREATE OR REPLACE FUNCTION Set_Object(_Content text[], _ObjectType text) RETURNS BIGINT AS $BODY$
DECLARE
_ObjectID bigint;
_ObjectTypeID integer;
_SHA1 char(40);
BEGIN
IF _Content IS NULL THEN
    RAISE EXCEPTION 'ERROR_SNAPSHOT_OBJECT_CONTENT_IS_NULL';
END IF;
SELECT ObjectTypeID INTO _ObjectTypeID FROM ObjectTypes WHERE Name = _ObjectType;
IF NOT FOUND THEN
    INSERT INTO ObjectTypes (Name) VALUES (_ObjectType) RETURNING ObjectTypeID INTO STRICT _ObjectTypeID;
END IF;
_SHA1 := SHA1(_Content);
SELECT ObjectID INTO _ObjectID FROM Objects WHERE SHA1 = _SHA1 AND ObjectTypeID = _ObjectTypeID;
IF FOUND THEN
    RETURN _ObjectID;
END IF;
INSERT INTO Objects (ObjectTypeID,Content,SHA1) VALUES (_ObjectTypeID,_Content,_SHA1) RETURNING ObjectID INTO STRICT _ObjectID;
RETURN _ObjectID;
END;
$BODY$ LANGUAGE plpgsql VOLATILE;
