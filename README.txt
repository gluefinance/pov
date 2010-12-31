DESCRIPTION

Take a snapshot or rollback all your stored procedures in your PostgreSQL database.



RATIONALE

Before reading any further, ask yourselves the following questions.

1.  Have you ever,
    a)  modified stored procedures in your production database and
    b)  thought it went OK because all your tests passed and
    c)  later on realized "something is wrong" and
    d)  not being able to find nor fix the bug immediately
        leaving you no other option than to do a revert?
    If so, go to step 2.
    If not, go to step 4.

2.  During the minutes/hours while your malfunctional patch made a mess
    in the production database, was there any user activity causing important
    writes to the database?
    If so, go to step 3.
    If not, go to step 4.

3.  Did you enjoy the revert experience in step 1?
    If so, go to step 4.
    If not, go to step 5.

4. Are any of the following statements TRUE?
    a) your application is not very database centric.
    b) your users won't stop using your service if you lose their data.
    c) your application is read-only.
    d) your application does not have a lot of user traffic.
    If so, lucky you!
    If not, you probably have a good solution to my problem already,
            I would highly appreciate if you wanted to share it with me,
            please contact me at joel@gluefinance.com.

5.  This proposed solution might be interesting for you.
    I would highly appreciate your feedback on how to improve it,
    please contact me at joel@gluefinance.com.



INTRODUCTION

snapshot can take a snapshot of all your database functions and objects
depending on them, such as constraints and views using functions.

snapshot can rollback to a previous snapshot without modifying any of your
data or tables. It will only execute the minimum set of drop/create commands
to carry out the rollback.

snapshot will use SHA1 if the pgcrypto contrib package is available,
otherwise MD5 will be used as the hash algorithm.



TERMINOLOGY

object type     objects of the same type are created and dropped the same way,
                i.e. they use the same functions to build proper create and
                drop SQL-commands.

object          is of an object type and has a hash of its content
                consisting of two SQL-commands, one to create and another to
                drop the object.

revision        has a timestamp when it was created and a list of objects

snapshot        has a timestamp when it was taken and has a revision

active snapshot the last snapshot taken

take snapshot   create a new revision of all objects currently live in the
                database and then create a new snapshot if the revision
                is different compared to the active snapshot.

rollback        restores a previously taken snapshot



SYNOPSIS

-- 1. Take a snapshot.

    postgres=# SELECT * FROM snapshot();
     _snapshotid |               _revisionid                
    -------------+------------------------------------------
               1 | 871ff0b837436ea1357814cdaa35a2013c63bd44
    (1 row)


-- 2. Take a snapshot.

    postgres=# SELECT * FROM snapshot();
     _snapshotid |               _revisionid                
    -------------+------------------------------------------
               1 | 871ff0b837436ea1357814cdaa35a2013c63bd44
    (1 row)


-- 3. We notice nothing changed between step 1 and 2.


-- 4. Modify your functions.

    postgres=# CREATE FUNCTION myfunc() RETURNS VOID AS $$ $$ LANGUAGE sql;
    CREATE FUNCTION
    glue=# \df myfunc
                             List of functions
     Schema |  Name  | Result data type | Argument data types |  Type  
    --------+--------+------------------+---------------------+--------
     public | myfunc | void             |                     | normal
    (1 row)


-- 5. Take a snapshot.

    postgres=# SELECT * FROM snapshot();
     _snapshotid |               _revisionid                
    -------------+------------------------------------------
               2 | 1e96cbf3da6aa5d648c837e6e910dfbe7f3eae18
    (1 row)


-- 4. Rollback to snapshot 1.

    postgres=# SELECT * FROM snapshot(1);
     _snapshotid |               _revisionid                
    -------------+------------------------------------------
     3           | 871ff0b837436ea1357814cdaa35a2013c63bd44
    (1 row)


-- 5. We notice the function we created in step 4 has been dropped.

    postgres=# \df myfunc
                           List of functions
     Schema | Name | Result data type | Argument data types | Type 
    --------+------+------------------+---------------------+------
    (0 rows)


-- 6. Rollback to snapshot 2.

    postgres=# SELECT * FROM snapshot(2);
     _snapshotid |               _revisionid                
    -------------+------------------------------------------
               4 | 1e96cbf3da6aa5d648c837e6e910dfbe7f3eae18
    (1 row)


-- 7. We notice the function we created in step 4 has been created.

    postgres=# \df myfunc
                             List of functions
     Schema |  Name  | Result data type | Argument data types |  Type  
    --------+--------+------------------+---------------------+--------
     public | myfunc | void             |                     | normal
    (1 row)

