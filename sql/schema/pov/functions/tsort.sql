-- Stolen from:
--  -> Jeffrey S. Haemer (Perl Power Tools->tcsort, http://cpansearch.perl.org/src/CWEST/ppt-0.14/html/commands/tsort/tcsort, v 1.3 2004/08/05 14:24:05 cwest)
--  -> Jon Bentley (I<More Programming Pearls>, pp. 20-23)
--  -> Don Knuth (I<Art of Computer Programming, volume 1: Fundamental Algorithms>, Section 2.2.3)
CREATE OR REPLACE FUNCTION tsort(OUT nodes text[], vertices text) RETURNS TEXT[] AS $BODY$
SELECT nodes FROM tsort($1, ' ', 'depth-first',NULL,FALSE);
$BODY$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION tsort(OUT nodes text[], vertices text, delimiter text, sort_algorithm text, roots text, debug boolean) RETURNS TEXT[] AS $BODY$
BEGIN {
    strict->import();
    warnings->import();
}
my ($vertices, $delimiter, $algorithm, $roots, $debug) = @_;
die "usage: tsort(vertices, delimiter, [depth-first|breadth-first|roots-only|sub {...}], [root node(s) or NULL for all], [debug TRUE|FALSE])" unless $algorithm =~ '^(depth-first|breadth-first|roots-only|sub)' && $delimiter ne '';

my $left;             # left noce in edge
my $right;            # right node in edge
my %pairs;            # all pairs ($left, $right)
my %num_predecessors; # number of predecessors
my %successors;       # list of successors
my %predecessors;     # list of predecessors
my @sorted_nodes;     # list of nodes in topologically sorted order
my @root_nodes;       # list of nodes without predecessors
my @ignored_nodes;    # list of nodes not part of output, ignored because they are not part of our root node trees
my @all_root_nodes;   # list of all root nodes found

my @edges = split $delimiter, $vertices;
die "input contains an odd number of nodes" unless @edges % 2 == 0;

foreach my $node (@edges) {
    unless( defined $left ) {
        $left = $node;
        next;
    }
    $right = $node;
    elog(DEBUG, "left: $left, right: $right");
    $pairs{$left}{$right}++;
    $num_predecessors{$left} += 0;
    ++$num_predecessors{$right};
    push @{$successors{$left}}, $right;
    push @{$predecessors{$right}}, $left;
    undef $left;
    undef $right;
}

my $sort_sub;
if ($algorithm =~ /^sub/) {
    $sort_sub = eval "$algorithm";
}

# sort successors
if ($sort_sub) {
    foreach my $node (keys %successors) {
        @{$successors{$node}} = sort $sort_sub @{$successors{$node}};
    }
}

# set to nodes without predecessors
if ($sort_sub) {
    @all_root_nodes = sort $sort_sub grep {!$num_predecessors{$_}} keys %num_predecessors;
} else {
    @all_root_nodes = grep {!$num_predecessors{$_}} keys %num_predecessors;
}

if (defined $roots) {
    if ($sort_sub) {
        @root_nodes = sort $sort_sub split $delimiter, $roots;
    } else {
        @root_nodes = split $delimiter, $roots;
    }
} else {
    # default to all root nodes
    @root_nodes = @all_root_nodes;
}

return \@root_nodes if $algorithm eq 'roots-only';

my @nodes = @all_root_nodes;

my $node_on_root_tree = 0;
while (@nodes) {
    my $node;
    if ($sort_sub) {
        @nodes = sort $sort_sub @nodes;
        $node = shift @nodes;
    } else {
        $node = pop @nodes;
    }

    elog(DEBUG, "node: $node");

    if (grep {$_ eq $node} @root_nodes) {
        # this node is a root node, part of the root nodes of interest
        elog(DEBUG, "$node is root node to be included");
        $node_on_root_tree = 1;
    } elsif(grep {$_ eq $node} @all_root_nodes) {
        # this node is a root node, not part of the root nodes of interest
        # ignore all nodes, until we encounter a new root node
        elog(DEBUG, "$node is root node to be ignored");
        $node_on_root_tree = 0;
    }
    if ($node_on_root_tree == 1) {
        elog(DEBUG, "push node $node to sorted_nodes");
        push @sorted_nodes, $node;
    } else {
        elog(DEBUG, "push node $node to ignored_nodes");
        push @ignored_nodes, $node;
    }
    foreach my $child (@{$successors{$node}}) {
        if ($algorithm eq 'breadth-first') {
            elog(DEBUG, "unshift child $child to nodes");
            unshift @nodes, $child unless --$num_predecessors{$child};
        } elsif ($algorithm eq 'depth-first' || defined $sort_sub) {
            elog(DEBUG, "push child $child to nodes");
            push @nodes, $child unless --$num_predecessors{$child};
        } else {
            die "invalid algorithm";
        }
    }
}

# Build debug message
my $debug_message = "\npairs:\n";
foreach my $left (sort %pairs) {
    foreach my $right (sort keys %{ $pairs{$left} }) {
        $debug_message .= "$left$delimiter$right$delimiter$pairs{$left}{$right}\n";
    }
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
$debug_message .= "all_root_nodes:\n";
foreach my $node (@all_root_nodes) {
    $debug_message .= "$node\n";
}
$debug_message .= "sorted_nodes:\n";
foreach my $node (@sorted_nodes) {
    $debug_message .= "$node\n";
}
$debug_message .= "ignored_nodes:\n";
foreach my $node (@ignored_nodes) {
    $debug_message .= "$node\n";
}
foreach my $node (@ignored_nodes) {
    delete $num_predecessors{$node};
}
$debug_message .= "num_predecessors (post delete ignored nodes):\n";
foreach my $node (sort keys %num_predecessors) {
    $debug_message .= "$node$delimiter$num_predecessors{$node}\n";
}

if (defined $debug && $debug eq 't') {
    elog(DEBUG, $debug_message);
}

# Detect cycle
if (grep {$num_predecessors{$_}} keys %num_predecessors) {
    die "cycle detected $debug_message";
}

return \@sorted_nodes;
$BODY$ LANGUAGE plperl IMMUTABLE;
