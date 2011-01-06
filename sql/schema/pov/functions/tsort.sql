CREATE OR REPLACE FUNCTION tsort(OUT nodes text[], edges text) RETURNS TEXT[] AS $BODY$
SELECT nodes FROM tsort($1, ' ',NULL,NULL,NULL);
$BODY$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION tsort(OUT nodes text[], edges text, delimiter text, narrow text, debug integer, algorithm text) RETURNS TEXT[] AS $BODY$
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
my ($edges_string, $delimiter, $narrow, $debug, $algorithm) = @_;

# declare variables
my $readme;           # description on how to use this utility
my $left;             # left node in edge
my $right;            # right node in edge
my %pairs;            # hash, key=$left, value=hash which key=$right, i.e. $pairs{$left}{$right}
my %num_predecessors; # hash, key=node, value=number of predecessors for node
my %num_successors;   # hash, key=node, value=number of successors for node
my %successors;       # hash, key=node, value=array of the successor nodes
my %predecessors;     # hash, key=node, value=array of the predecessor nodes
my @source_nodes;     # array of nodes with successors but no predecessors
my @sink_nodes;       # array of nodes with predecessors but no successors
my @isolated_nodes;   # array of nodes without any successors nor predecessors
my @sorted_nodes;     # array of nodes in topologically sorted order (output variable)

# set defaults
$algorithm = 'DFS' unless defined $algorithm;
$debug = 0 unless defined $debug;

# set readme
$readme = '
DESCRIPTION
tsort - return a tree\'s nodes in topological order

USAGE
tsort(edges, delimiter, algorithm, narrow, debug)

SYNOPSIS
postgres=# SELECT tsort(\'a aa a ab aa aaa aa aab ab aba ab abb\',\' \',\'depth-first\',NULL,NULL);
           tsort           
---------------------------
 {a,ab,abb,aba,aa,aab,aaa}
(1 row)

OUTPUT
    nodes       text[]  array of nodes in topologically sorted order

INPUT
    edges       text    list of node pairs
    delimiter   text    token separating each node in the list of edges
    narrow      text    limit the search to start at only these nodes or NULL for all nodes
    debug       integer print debug information using RAISE DEBUG, 0=no, 1=some, 2=verbose
    algorithm   text    sorting algorithm:
                        DFS      depth-first (default)
                                 explores as far as possible along each branch
                                 before backtracking.
                        BFS      breadth-first
                                 explores all the neighboring nodes,
                                 then for each of those nearest nodes,
                                 it explores their unexplored neighbor nodes,
                                 and so on, until it finds the goal.
                        ISOLATED only return the nodes without any successors nor predecessors
                        SOURCE   only return the nodes with successors but no predecessors
                        SINK     only return the nodes with predecessors but no successors
                        ^sub     sort using perl subroutine,
                                 examples:
                                 sort numerically ascending  : sub {$a <=> $b}
                                 sort numerically descending : sub {$b <=> $a}
                                 sort lexically ascending    : sub {$a cmp $b}
                                 sort lexically descending   : sub {$b cmp $a}
                                 sort case-insensitively     : sub {uc($a) cmp uc($b)}
                                 For more examples, please goto:
                                 http://perldoc.perl.org/functions/sort.html
';

# validate input arguments
die "invalid algorithm\n\n$readme" unless $algorithm =~ '^(DFS|BFS|ISOLATED|SOURCE|SINK|sub\s+{.+})$';
die "invalid delimiter\n\n$readme" unless defined $delimiter && $delimiter ne '';

# parse string of nodes into edges array, e.g. 'a b a c' -> ('a','b','a','c')
my @edges = split $delimiter, $edges_string;

# check balance
die "input edges contains an odd number of nodes\n\n$readme" unless @edges % 2 == 0;

$debug > 0 && elog(DEBUG, "1. build data structures pairs, successors, predecessors");
foreach my $node (@edges) {
    unless( defined $left ) {
        $left = $node;
        next;
    }
    $right = $node;
    $pairs{$left}{$right}++;
    $debug > 1 && elog(DEBUG, '    1.1. $pairs{$left}{$right}++ : $left=' . $left . ' $right=' . $right . ' $pairs{$left}{$right}=' . $pairs{$left}{$right} );
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

# if algorithm begins with "sub", compile sort algorithm
my $sort_sub;
if ($algorithm =~ /^sub/) {
    $sort_sub = eval "$algorithm";
}

# sort successors
if ($sort_sub) {
    $debug > 0 && elog(DEBUG,"2. sort successors");
    foreach my $node (keys %successors) {
        $debug > 1 && elog(DEBUG,"    2.1. sorting node $node");
        @{$successors{$node}} = sort $sort_sub @{$successors{$node}};
        $debug > 1 && elog(DEBUG,"    2.2. sorted successors for node $node: " . join($delimiter,@{$successors{$node}}) );
    }
}

$debug > 0 && elog(DEBUG, "3. find isolated, source and sink nodes");

# find isolated nodes
# the hashes %num_predecessors and %num_successors both contain all the nodes,
# we could use any of them to get the isolated nodes
@isolated_nodes = grep {!$num_predecessors{$_} && !$num_successors{$_}}   keys %num_predecessors;
# find source nodes
@source_nodes   = grep {!$num_predecessors{$_}}                           keys %num_predecessors;
# find sink nodes
@sink_nodes     = grep {!$num_successors{$_}}                             keys %num_successors;

# should we sort?
if ($sort_sub) {
    $debug > 0 && elog(DEBUG, "4. sort isolated, source and sink arrays");
    @isolated_nodes  = sort $sort_sub @isolated_nodes;
    @source_nodes    = sort $sort_sub @source_nodes;
    @sink_nodes      = sort $sort_sub @sink_nodes;
}

$debug > 0 && elog(DEBUG, "5. return if algorithm is ISOLATED, SOURCE or SINK");
return \@isolated_nodes if $algorithm eq 'ISOLATED';
return \@source_nodes   if $algorithm eq 'SOURCE';
return \@sink_nodes     if $algorithm eq 'SINK';

$debug > 0 && elog(DEBUG, "6. start search at source nodes");
my @nodes = @source_nodes;

while (@nodes) {
    my $node;
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

# Build debug message
my $debug_message = "\n7. debug\npairs:\n";
foreach my $left (sort %pairs) {
    foreach my $right (sort keys %{ $pairs{$left} }) {
        $debug_message .= "$left$delimiter$right$delimiter$pairs{$left}{$right}\n";
    }
}
$debug_message .= "num_successors:\n";
foreach my $node (sort keys %num_successors) {
    $debug_message .= "$node$delimiter$num_successors{$node}\n";
}
$debug_message .= "num_predecessors:\n";
foreach my $node (sort keys %num_predecessors) {
    $debug_message .= "$node$delimiter$num_predecessors{$node}\n";
}
$debug_message .= "successors:\n";
foreach my $left (sort keys %successors) {
    $debug_message .= "$left";
    foreach my $right ( @{ $successors{$left} }) {
        $debug_message .= "$delimiter$right";
    }
    $debug_message .= "\n";
}
$debug_message .= "predecessors:\n";
foreach my $right (sort keys %predecessors) {
    $debug_message .= "$right";
    foreach my $right ( @{ $predecessors{$right} }) {
        $debug_message .= "$delimiter$right";
    }
    $debug_message .= "\n";
}
$debug_message .= "sorted_nodes:\n";
foreach my $node (@sorted_nodes) {
    $debug_message .= "$node\n";
}

$debug > 0 && elog(DEBUG, $debug_message);

# Detect cycle
if (grep {$num_predecessors{$_}} keys %num_predecessors) {
    die "cycle detected $debug_message";
}

return \@sorted_nodes;
$BODY$ LANGUAGE plperl STABLE;

SELECT tsort('a aa a ab aa aaa aa aab ab aba ab abb', ' ', NULL, NULL, NULL);
SELECT tsort('a aa a ab aa aaa aa aab ab aba ab abb', ' ', NULL, NULL, 'DFS');
SELECT tsort('a aa a ab aa aaa aa aab ab aba ab abb', ' ', NULL, NULL, 'BFS');
SELECT tsort('a aa a ab aa aaa aa aab ab aba ab abb', ' ', NULL, NULL, 'sub {$a cmp $b}');
SELECT tsort('a aa a ab aa aaa aa aab ab aba ab abb', ' ', NULL, NULL, 'sub {$b cmp $a}');

