CREATE OR REPLACE FUNCTION pov.tsort(OUT nodes text[], edges text, delimiter text, debug integer, algorithm text, selection text, operator text, nodes text, direction text) RETURNS TEXT[] AS $BODY$
# tsort - return a tree's nodes in topological order

# Code stolen from:
# Don Knuth (I<Art of Computer Programming, volume 1: Fundamental Algorithms>, Section 2.2.3)
#  \- Jon Bentley (I<More Programming Pearls>, pp. 20-23)
#      \- Jeffrey S. Haemer (Perl Power Tools->tcsort, http://cpansearch.perl.org/src/CWEST/ppt-0.14/html/commands/tsort/tcsort)
# Jarkko Hietaniemi (http://search.cpan.org/~jhi/Graph-0.94/)

# plperl compatible way of doing use strict; use warnings;
BEGIN {
    strict->import();
    warnings->import();
}
# read input
my ($edges_string, $delimiter, $debug, $algorithm, $selection_mode, $operator, $selection_nodes, $direction) = @_;

# set readme
my $readme = '
DESCRIPTION
tsort - return a tree\'s nodes in topological order


SYNOPSIS
tsort(edges text, delimiter text, debug integer, algorithm text,
selection text, operator text, nodes text, direction text);

OUTPUT
    nodes       text[]  Array of nodes in topologically sorted order

INPUT PARAMETERS
    Parameter   Type    Regex     Description
    ============================================================================
    edges       text    ^.+$        Node pairs, separated by [delimiter].

    delimiter   text    ^.*$        Node separator in [edges],
                                    default is \' \', i.e. single blank space.

    debug       integer             Print debug information using RAISE DEBUG:
                        0           no debug (default)
                        1           some debug
                        2           verbose debug

    algorithm   text                Sorting algorithm:
                        DFS         depth-first (default)
                                    explores as far as possible along each
                                    branch before backtracking.
                        BFS         breadth-first
                                    explores all the neighboring nodes,
                                    then for each of those nearest nodes,
                                    it explores their unexplored neighbor
                                    nodes, and so on.
                        ^sub        sort using perl subroutine.
                                    examples:
                                    # sort numerically ascending
                                    sub {$a <=> $b}
    
                                    # sort numerically descending
                                    sub {$b <=> $a}
    
                                    #sort lexically ascending
                                    sub {$a cmp $b}
    
                                    # sort lexically descending
                                    sub {$b cmp $a}
    
                                    # sort case-insensitively
                                    sub {uc($a) cmp uc($b)}
    
                                    For more examples, please goto:
                                    http://perldoc.perl.org/functions/sort.html

    The following options will not affect the order of the nodes in the result,
    they only control which nodes are included in the result:

    Parameter   Type    Regex     Description
    ============================================================================
    selection   text                Selection of nodes, used by [operator]:
                        ALL         select all nodes (default)
                        ISOLATED    select nodes without any
                                    successors nor predecessors
                        SOURCE      select nodes with successors
                                    but no predecessors
                        SINK        select nodes with predecessors
                                    but no successors
                        CONN_INCL   select nodes connected to [nodes],
                                    including [nodes]
                        CONN_EXCL   select nodes connected to [nodes],
                                    excluding [nodes]
                                    separated by [delimiter]

    operator    text                Include or exclude nodes in [selection]:
                        INCLUDE     include nodes (default)
                        EXCLUDE     exclude nodes

    The following options are only applicable if,
    [selection] is CONN_INCL or CONN_EXCL

    Parameter   Type    Regex     Description
    ============================================================================

    nodes       text                select nodes connected to [nodes]
                        NULL        not applicable (default)
                        [nodes]     the start nodes, separated by [delimiter]


    direction   text                direction to look for connected nodes
                        BOTH        traverse both successors and
                                    predecessors (default)
                        UP          only traverse predecessors
                        DOWN        only traverse successors

';

# SELECT pov.tsort(); -- shows help
if (defined $debug && $debug == -1) {
    return [$readme];
}

# declare variables
my $node;              # a node in the tree
my $left;              # left node in edge
my $right;             # right node in edge
my %pairs;             # hash, key=$left, value=hash which key=$right, i.e. $pairs{$left}{$right}
my %num_predecessors;  # hash, key=node, value=number of predecessors for node
my %num_successors;    # hash, key=node, value=number of successors for node
my %successors;        # hash, key=node, value=array of the successor nodes
my %predecessors;      # hash, key=node, value=array of the predecessor nodes
my @source_nodes;      # array of nodes with successors but no predecessors
my %source_nodes_hash; # array of nodes with successors but no predecessors
my @sink_nodes;        # array of nodes with predecessors but no successors
my @isolated_nodes;    # array of nodes without any successors nor predecessors
my @sorted_nodes;      # array of nodes in topologically sorted order (output variable)

# validate input arguments
die "edges is undefined\n\n$readme" unless defined $edges_string;
die "invalid algorithm: $algorithm\n\n$readme"      if defined $algorithm      && $algorithm      !~ '^(DFS|BFS|ISOLATED|SOURCE|SINK|sub\s+{.+})$';
die "invalid selection: $selection_mode\n\n$readme" if defined $selection_mode && $selection_mode !~ '^(ALL|ISOLATED|SOURCE|SINK|CONN_INCL|CONN_EXCL)$';
die "invalid operator: $operator\n\n$readme"        if defined $operator       && $operator       !~ '^(INCLUDE|EXCLUDE|SPLIT)$';
die "invalid direction: $direction\n\n$readme"      if defined $direction      && $direction      !~ '^(BOTH|UP|DOWN)$';

# set defaults
$algorithm       = 'DFS'     unless defined $algorithm;
$delimiter       = ' '       unless defined $delimiter;
$debug           = 0         unless defined $debug;
$selection_mode  = 'ALL'     unless defined $selection_mode;
$operator        = 'INCLUDE' unless defined $operator;
$direction       = 'BOTH'    unless defined $direction;

# A. PARSE STRING OF NODES

# create edges array, e.g. 'a b a c' -> ('a','b','a','c')
my @edges = split $delimiter, $edges_string;

# check balance
die "input edges contains an odd number of nodes\n\n$readme" unless @edges % 2 == 0;

# B. CREATE DATA STRUCTURES

$debug > 0 && elog(DEBUG, "1. build data structures pairs, successors, predecessors");
foreach $node (@edges) {
    unless( defined $left ) {
        $left = $node;
        next;
    }
    $right = $node;
    $pairs{$left}{$right}++;
    $debug > 1 && elog(DEBUG, '    1.1. ' . $pairs{$left}{$right} . ' $left=' . $left . ' $right=' . $right);
    # for every unique pair (first time seen):
    if ($pairs{$left}{$right} == 1) {
        $num_predecessors{$left} = 0 unless exists $num_predecessors{$left};
        $num_successors{$right}  = 0 unless exists $num_successors{$right};
        ++$num_successors{$left};
        ++$num_predecessors{$right};
        push @{$successors{$left}}, $right;
        push @{$predecessors{$right}}, $left;
    }
    undef $left;
    undef $right;
}

# C. SPECIAL SORTING, PHASE 1

# if algorithm begins with "sub", compile sort algorithm
my $sort_sub;
if ($algorithm =~ /^sub/) {
    $sort_sub = eval "$algorithm";
}

# sort successors
$debug > 0 && elog(DEBUG,"2. sort successors and predecessors");
if ($sort_sub) {
    foreach $node (keys %successors) {
        $debug > 1 && elog(DEBUG,"    2.1. sorting successor node $node");
        @{$successors{$node}} = sort $sort_sub @{$successors{$node}};
        $debug > 1 && elog(DEBUG,"    2.2. sorted successors for node $node: " . join($delimiter,@{$successors{$node}}) );
    }
}

# sort predecessors
if ($sort_sub) {
    foreach $node (keys %predecessors) {
        $debug > 1 && elog(DEBUG,"    2.3. sorting predecessor node $node");
        @{$predecessors{$node}} = sort $sort_sub @{$predecessors{$node}};
        $debug > 1 && elog(DEBUG,"    2.4. sorted predecessors for node $node: " . join($delimiter,@{$predecessors{$node}}) );
    }
}

# D. FIND ISOLATED, SOURCE AND SINK NODES

$debug > 0 && elog(DEBUG, "3. find isolated, source and sink nodes");
# the hashes %num_predecessors and %num_successors both contain all the nodes,
# we could use any of them to get the isolated nodes
@isolated_nodes = grep {!$num_predecessors{$_} && !$num_successors{$_}}   keys %num_predecessors;
# find source nodes
@source_nodes   = grep {!$num_predecessors{$_}}                           keys %num_predecessors;
@source_nodes_hash{@source_nodes} = @source_nodes;
# find sink nodes
@sink_nodes     = grep {!$num_successors{$_}}                             keys %num_successors;

# E. SPECIAL SORTING, PHASE 2

# should we sort?
$debug > 0 && elog(DEBUG, "4. check if we sort sort isolated, source and sink arrays");
if ($sort_sub) {
    @isolated_nodes  = sort $sort_sub @isolated_nodes;
    @source_nodes    = sort $sort_sub @source_nodes;
    @sink_nodes      = sort $sort_sub @sink_nodes;
}

################################################################################
# F. <--- RETURN #1, ISOLATED, SOURCE OR SINK NODES                            #
################################################################################
$debug > 0 && elog(DEBUG, "5. return if algorithm is ISOLATED, SOURCE or SINK");
return \@isolated_nodes if $selection_mode eq 'ISOLATED' && $operator eq 'INCLUDE';
return \@source_nodes   if $selection_mode eq 'SOURCE'   && $operator eq 'INCLUDE';
return \@sink_nodes     if $selection_mode eq 'SINK'     && $operator eq 'INCLUDE';
################################################################################

# G. EXECUTE TOPOLOGICAL SORT ALGORITHM

$debug > 0 && elog(DEBUG, "6. start search at source nodes");
my @nodes = @source_nodes;

while (@nodes) {
    if ($sort_sub) {
        $debug > 1 && elog(DEBUG, "    6.1. unsorted nodes: " . join($delimiter,@nodes));
        # Sort nodes, then pick the first one
        @nodes = sort $sort_sub @nodes;
        $debug > 1 && elog(DEBUG, "    6.2. sorted nodes: " . join($delimiter,@nodes));
        $node = shift @nodes;
        $debug > 1 && elog(DEBUG, "    6.3. shifted node: $node");
    } else {
        # No extra sorting
        $node = pop @nodes;
        $debug > 1 && elog(DEBUG, "    6.4. pop node: $node");
    }

    $debug > 1 && elog(DEBUG, "    6.5. for each child to $node");
    if ($operator eq 'SPLIT' && $source_nodes_hash{$node}) {
        push @sorted_nodes, undef;
    }
    push @sorted_nodes, $node;
    foreach my $child (@{$successors{$node}}) {
        if ($algorithm eq 'BFS') {
            $debug > 1 && elog(DEBUG, "        6.5.1. unshift child $child");
            unshift @nodes, $child unless --$num_predecessors{$child};
        } elsif ($algorithm eq 'DFS' || defined $sort_sub) {
            $debug > 1 && elog(DEBUG, "        6.5.2. push child $child");
            push @nodes, $child unless --$num_predecessors{$child};
        } else {
            die "invalid algorithm";
        }
    }
}

$debug > 1 && elog(DEBUG, "7. Debug:");
# H. COMPOSE DEBUG MESSAGE
$debug > 1 && elog(DEBUG, "    7.1. edges:");
foreach $left (sort %pairs) {
    foreach $right (sort keys %{ $pairs{$left} }) {
        $debug > 1 && elog(DEBUG, "        7.1.1. $left$delimiter$right$delimiter$pairs{$left}{$right}");
    }
}
$debug > 1 && elog(DEBUG, "    7.2. num_successors:");
foreach $node (sort keys %num_successors) {
    $debug > 1 && elog(DEBUG, "        7.2.1. $node$delimiter$num_successors{$node}");
}
$debug > 1 && elog(DEBUG, "    7.3. num_predecessors:");
foreach $node (sort keys %num_predecessors) {
    $debug > 1 && elog(DEBUG, "        7.3.1. $node$delimiter$num_predecessors{$node}");
}
$debug > 1 && elog(DEBUG, "    7.4. successors:");
foreach $left (sort keys %successors) {
    my $tmp = "$left";
    foreach $right ( @{ $successors{$left} }) {
        $tmp .= "$delimiter$right";
    }
    $debug > 1 && elog(DEBUG, "        7.4.1. $tmp");
}
$debug > 1 && elog(DEBUG, "    7.5. predecessors:");
foreach $right (sort keys %predecessors) {
    my $tmp = "$right";
    foreach $left ( @{ $predecessors{$right} }) {
        $tmp .= "$delimiter$left";
    }
    $debug > 1 && elog(DEBUG, "        7.5.1. $tmp");
}
$debug > 1 && elog(DEBUG, "    7.6. sorted_nodes:");
foreach $node (@sorted_nodes) {
    $debug > 1 && elog(DEBUG, "        7.6.1 $node");
}

# I. DETECT CYCLE
if (grep {$num_predecessors{$_}} keys %num_predecessors) {
    die "cycle detected";
}

################################################################################
# J. RETURN #2, ALL SORTED NODES                                               #
################################################################################
return \@sorted_nodes if $selection_mode eq 'ALL';
################################################################################

# K. FILTER OUTPUT BASED ON NODES

my @filter_nodes;

return \@isolated_nodes if $selection_mode eq 'ISOLATED' && $operator eq 'INCLUDE';
return \@source_nodes   if $selection_mode eq 'SOURCE'   && $operator eq 'INCLUDE';
return \@sink_nodes     if $selection_mode eq 'SINK'     && $operator eq 'INCLUDE';


die "nodes is undefined or empty string" unless defined $selection_nodes && $selection_nodes ne '';

# create nodes array, e.g. 'a b a c' -> ('a','b','a','c')
my @init = split $delimiter, $selection_nodes;
my %selection_nodes;
@selection_nodes{@init} = @init;

# find successors recursively (stolen from Graph::_all_successors)
my $traverse = sub {
    my ($init, $neighbours, $pairs) = @_;
    my %todo;
    @todo{@$init} = @$init;
    my %found;
    my %init = %todo;
    my %self;
    while (keys %todo) {
        my @todo = values %todo;
        for my $node (@todo) {
            $found{$node} = delete $todo{$node};
            foreach my $child (@{$neighbours->{$node}}) {
                $self{$child} = $child if     exists $init{$child};
                $todo{$child} = $child unless exists $found{$child};
            }
        }
    }
    for my $node (@$init) {
      delete $found{$node} unless exists $pairs->{$node}{$node} || $self{$node};
    }
    return \%found;
};

$debug > 0 && elog(DEBUG, "8. find nodes connected to: " . join($delimiter,@init));
my $nodes_successors   = &$traverse(\@init, \%successors,   \%pairs);
my $nodes_predecessors = &$traverse(\@init, \%predecessors, \%pairs);
$debug > 0 && elog(DEBUG, "    8.1. successors  : " . join($delimiter,sort keys %$nodes_successors));
$debug > 0 && elog(DEBUG, "    8.2. predecessors: " . join($delimiter,sort keys %$nodes_predecessors));

$debug > 0 && elog(DEBUG, "9. filter nodes:");

my %special_nodes;
if ($selection_mode eq 'ISOLATED') {
    @special_nodes{@isolated_nodes} = @isolated_nodes;
} elsif ($selection_mode eq 'SOURCE') {
    @special_nodes{@source_nodes} = @source_nodes;
} elsif ($selection_mode eq 'SINK') {
    @special_nodes{@sink_nodes} = @sink_nodes;
}

$debug > 0 && elog(DEBUG, "        9.1. special nodes: " . join $delimiter, keys %special_nodes );

foreach $node (@sorted_nodes) {
    my $is_in_selection = 0;
    if ($selection_mode eq 'CONN_INCL' || $selection_mode eq 'CONN_EXCL') {
        if ($direction eq 'UP') {
            $is_in_selection = exists $nodes_predecessors->{$node};
        } elsif ($direction eq 'DOWN') {
            $is_in_selection = exists $nodes_successors->{$node};
        } elsif ($direction eq 'BOTH') {
            $is_in_selection = exists $nodes_predecessors->{$node} || exists $nodes_successors->{$node};
        } else {
            die "invalid direction option: $direction";
        }
    } elsif (keys %special_nodes > 0) {
        $is_in_selection = exists $special_nodes{$node};
    }
    $is_in_selection = 1 if $selection_mode eq 'CONN_INCL' && exists $selection_nodes{$node};

    $debug > 1 && elog(DEBUG, "        9.2. node $node in selection: " . ($is_in_selection ? 'yes' : 'no'));

    if ($operator eq 'INCLUDE' || $operator eq 'SPLIT') {
        # $is_in_selection = $is_in_selection;
    } elsif ($operator eq 'EXCLUDE') {
        $is_in_selection = !$is_in_selection;
    } else {
        die "invalid operator option: $operator";
    }
    if ($is_in_selection ) {
        $debug > 1 && elog(DEBUG, "        9.3. including $node");
        push @filter_nodes, $node;
    }
}
return \@filter_nodes;
$BODY$ LANGUAGE plperl IMMUTABLE;

CREATE OR REPLACE FUNCTION pov.tsort(OUT nodes text[], edges text, delimiter text, debug integer, algorithm text, selection text, nodes text, operator text) RETURNS TEXT[] AS $BODY$
SELECT pov.tsort($1,$2,$3,$4,$5,$6,$7,NULL);
$BODY$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION pov.tsort(OUT nodes text[], edges text, delimiter text, debug integer, algorithm text, selection text, nodes text) RETURNS TEXT[] AS $BODY$
SELECT pov.tsort($1,$2,$3,$4,$5,$6,NULL,NULL);
$BODY$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION pov.tsort(OUT nodes text[], edges text, delimiter text, debug integer, algorithm text, selection text) RETURNS TEXT[] AS $BODY$
SELECT pov.tsort($1,$2,$3,$4,$5,NULL,NULL,NULL);
$BODY$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION pov.tsort(OUT nodes text[], edges text, delimiter text, debug integer, algorithm text) RETURNS TEXT[] AS $BODY$
SELECT pov.tsort($1,$2,$3,$4,NULL,NULL,NULL,NULL);
$BODY$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION pov.tsort(OUT nodes text[], edges text, delimiter text, debug integer) RETURNS TEXT[] AS $BODY$
SELECT pov.tsort($1,$2,$3,NULL,NULL,NULL,NULL,NULL);
$BODY$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION pov.tsort(OUT nodes text[], edges text, delimiter text) RETURNS TEXT[] AS $BODY$
SELECT pov.tsort($1,$2,NULL,NULL,NULL,NULL,NULL,NULL);
$BODY$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION pov.tsort(OUT nodes text[], edges text) RETURNS TEXT[] AS $BODY$
SELECT pov.tsort($1,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
$BODY$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION pov.tsort(OUT help text) RETURNS TEXT AS $BODY$
SELECT (pov.tsort(NULL,NULL,-1,NULL,NULL,NULL,NULL,NULL))[1];
$BODY$ LANGUAGE sql IMMUTABLE;
