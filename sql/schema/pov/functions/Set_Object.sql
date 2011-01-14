CREATE OR REPLACE FUNCTION Set_Object(_Content text[], _ObjectType text) RETURNS TEXT AS $BODY$
DECLARE
_ObjectID text;
_ObjectTypeContent text[];
BEGIN
IF _Content IS NULL THEN
    RAISE EXCEPTION 'ERROR_POV_OBJECT_CONTENT_IS_NULL';
END IF;

-- Append the ObjectType to beginning of the Content
_ObjectTypeContent := array_cat(ARRAY[_ObjectType], _Content);

_ObjectID := Hash(_ObjectTypeContent);

PERFORM 1 FROM Objects WHERE ObjectID = _ObjectID;
IF FOUND THEN
    RETURN _ObjectID;
END IF;
INSERT INTO Objects (ObjectID,Content) VALUES (_ObjectID,_ObjectTypeContent) RETURNING ObjectID INTO STRICT _ObjectID;
RETURN _ObjectID;
END;
$BODY$ LANGUAGE plpgsql VOLATILE;
