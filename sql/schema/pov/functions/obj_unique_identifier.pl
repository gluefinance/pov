my $catalog = '
pg_am                                 ; amname      ;                                                           ;
pg_amop                               ;             ; amopfamily, amopopr                                       ; pg_opfamily, pg_operator
pg_amproc                             ; amprocnum   ; amprocfamily, amproclefttype, amprocrighttype             ; pg_opfamily, pg_type, pg_type
pg_cast                               ;             ; castsource, casttarget                                    ; pg_type, pg_type
pg_class                              ; relname     ; relnamespace                                              ; pg_namespace
pg_constraint                         ; conname     ; connamespace                                              ; pg_namespace
pg_conversion                         ; conname     ; connamespace                                              ; pg_namespace
pg_enum                               ; enumlabel   ; enumtypid                                                 ; pg_type
pg_foreign_data_wrapper               ; fdwname     ;                                                           ;
pg_foreign_server                     ; srvname     ;                                                           ;
pg_language                           ; lanname     ;                                                           ;
pg_namespace                          ; nspname     ;                                                           ;
pg_opclass                            ; opcname     ; opcmethod, opcnamespace                                   ; pg_am, pg_namespace
pg_operator                           ; oprname     ; oprleft, oprright, oprnamespace                           ; pg_type, pg_type, pg_namespace
pg_opfamily                           ; opfname     ; opfmethod, opfnamespace                                   ; pg_am, pg_namespace
pg_rewrite                            ; rulename    ; ev_class                                                  ; pg_class
pg_trigger                            ; tgname      ; tgrelid                                                   ; pg_class
pg_ts_config                          ; cfgname     ; cfgnamespace                                              ; pg_namespace
pg_ts_dict                            ; dictname    ; dictnamespace                                             ; pg_namespace
pg_ts_parser                          ; prsname     ; prsnamespace                                              ; pg_namespace
pg_ts_template                        ; tmplname    ; tmplnamespace                                             ; pg_namespace
pg_type                               ; typname     ; typnamespace                                              ; pg_namespace
pg_user_mapping                       ;             ; umuser, umserver                                          ; pg_authid, pg_foreign_server
pg_tablespace                         ; spcname     ;                                                           ;
pg_database                           ; datname     ;                                                           ;
pg_authid                             ; rolname     ;                                                           ;
';

$catalog =~ s/ //g;
my $struct = {};
while ($catalog =~ s/^([^;\n]+?)\s*;\s*([^;]*?)\s*;\s*([^;]*?)\s*;\s*([^;\n]*?)\s*$//m) {
    my ($regclass, $name_column, $unique_columns, $ref_regclasses) = ($1, $2, $3, $4);
    push @{$struct->{$regclass}->{name_column}}, split ',', $name_column;
    push @{$struct->{$regclass}->{unique_columns}}, split ',', $unique_columns;
    $struct->{$regclass}->{unique_columns_refs} = {};
    @{$struct->{$regclass}->{unique_columns_refs}}{split ',', $unique_columns} = split ',', $ref_regclasses;
}

print "SET check_function_bodies TO FALSE;\n";
my $len = 0;
foreach my $regclass (sort keys %{$struct}) {
    $len = length($regclass) if length($regclass) > $len;
    my $sql = "CREATE OR REPLACE FUNCTION get_unique_name_for_$regclass(oid) RETURNS TEXT AS \$\$\n";
    $sql .= '    SELECT ';
    foreach my $unique_column ( @{$struct->{$regclass}->{unique_columns}} ) {
        $sql .= 'get_unique_name_for_'
        . $struct->{$regclass}->{unique_columns_refs}->{$unique_column}
        . '(pg_catalog.'
        . $regclass
        . '.'
        . $unique_column
        . ") || '.'\n     || "
    }
    foreach my $name ( @{$struct->{$regclass}->{name_column}} ) {
        $sql .= 'pg_catalog.' . $regclass . '.' . $name . "::text || '.'\n     || ";
    }
    $sql =~ s/ \|\| '\.'\n     \|\| $//;
    $sql .= " FROM $regclass WHERE oid = \$1;\n\$\$ LANGUAGE sql STABLE;\n\n";
    print $sql;
};

print '

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_type(oid) RETURNS TEXT AS $$
    SELECT COALESCE((SELECT get_unique_name_for_pg_namespace(pg_catalog.pg_type.typnamespace) || \'.\'
     || pg_catalog.pg_type.typname::text FROM pg_type WHERE oid = $1),\'\');
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_attrdef(oid, integer) RETURNS TEXT AS $$
    SELECT get_unique_name_for_pg_class(pg_catalog.pg_attrdef.adrelid) || \'.\'
     || pg_catalog.pg_attribute.attname::text FROM pg_catalog.pg_attrdef
     JOIN pg_catalog.pg_attribute ON (pg_catalog.pg_attribute.attrelid = pg_catalog.pg_attrdef.adrelid AND pg_catalog.pg_attribute.attnum = pg_catalog.pg_attrdef.adnum)
     WHERE pg_catalog.pg_attrdef.adrelid = $1 AND pg_catalog.pg_attrdef.adnum = $2;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_attribute(oid, integer) RETURNS TEXT AS $$
    SELECT get_unique_name_for_pg_class(pg_catalog.pg_attribute.attrelid) || \'.\'
     || pg_catalog.pg_attribute.attname::text FROM pg_catalog.pg_attribute
     WHERE pg_catalog.pg_attribute.attrelid = $1 AND pg_catalog.pg_attribute.attnum = $2;
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_unique_name_for_pg_proc(oid) RETURNS TEXT AS $$
    SELECT get_unique_name_for_pg_namespace(pg_catalog.pg_proc.pronamespace) || \'.\' || pg_catalog.pg_proc.proname::text || \'(\' || pg_get_function_identity_arguments(pg_catalog.pg_proc.oid) || \')\'
    FROM pg_catalog.pg_proc WHERE pg_catalog.pg_proc.oid = $1;
$$ LANGUAGE sql STABLE;

';

$struct->{pg_proc} = 1;


print '
CREATE OR REPLACE FUNCTION obj_unique_identifier(classid oid, objectid oid, objsubid integer) RETURNS TEXT AS $BODY$
SELECT
    CASE WHEN $1 = 0 AND $2 = 0 AND $3 = 0 THEN \'-\'
    ELSE
        $1::regclass::text
        || \'.\' ||
        CASE
';

foreach my $regclass (sort keys %{$struct}) {
    my $space = (' ' x ($len - length($regclass)));
    print '            WHEN $1::regclass = \'' . $regclass . '\'::regclass' . $space . '   THEN get_unique_name_for_' . $regclass . '($2)' . "\n";
}
print '            ELSE NULL
        END
        ||
        CASE
            WHEN $3 = 0 THEN \'\'
            WHEN $1::regclass = \'pg_class\'::regclass AND $3 >= 1 THEN \'.\' || get_unique_name_for_pg_attribute($2,$3)
            ELSE NULL
        END
    END;
$BODY$ LANGUAGE sql STABLE;
';


print <<EOF

CREATE OR REPLACE FUNCTION obj_unique_identifier(oid) RETURNS TEXT AS $BODY$
SELECT obj_unique_identifier(d.classid, d.objid, d.objsubid) FROM (
    SELECT pg_depend.classid, pg_depend.objid, pg_depend.objsubid FROM pg_catalog.pg_depend
    WHERE pg_depend.objid = $1
    UNION ALL
    SELECT pg_depend.refclassid, pg_depend.refobjid, pg_depend.refobjsubid FROM pg_catalog.pg_depend
    WHERE pg_depend.refobjid = $1
    LIMIT 1
) AS d;
$BODY$ LANGUAGE sql STABLE;

EOF
;





