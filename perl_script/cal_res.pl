#!/usr/bin/perl -w

use strict;



usage() if (@ARGV<3);



my ($res_file,$n1,$n2)=($ARGV[0],lc($ARGV[1]),lc($ARGV[2]));



my $g_hash=read_res_file($res_file);

#remove_float($g_hash,$n1,$n2);



while (1) {

    if (!defined($g_hash->{$n1}) || !defined($g_hash->{$n2})) {
        print "*" x 40, "\n";
        print "Open circuit between [$ARGV[1]]<->[$ARGV[2]], no path found\n";
        print "*" x 40, "\n";
        last;
    } elsif ((keys %{$g_hash->{$n1}} == 1 || keys %{$g_hash->{$n2}} == 1) && defined($g_hash->{$n1}{$n2})) {
        # if n1 or n2 has only one connection, and the connection is between n1 & n2, then report the res
        print "*" x 40, "\n";
        printf "Res of [$ARGV[1]]<->[$ARGV[2]] : %10.3e\n",1/$g_hash->{$n1}{$n2};
        print "*" x 40, "\n";
        last;
    } else {
        &remove_float($g_hash,$n1,$n2);

        foreach my $c_node (keys %$g_hash) {
            if ($c_node ne "$n1" && $c_node ne "$n2") {
                #print "merge $c_node\n";
                my @nodes_around_c_node=keys %{$g_hash->{$c_node}};
                star2ret_transfer($g_hash,$c_node,\@nodes_around_c_node);
                last;
            }
        }
    }
}

sub read_res_file {
    my $file=shift;

    my %g=();

    open (FI,"$file") || die "$file, $!\n";
    while(<FI>) {
        next if (/^\s*[\*\$]/ || /^\s*$/);

        if (/^\s*R/i) {
            s/^\s*//g;
            #print;
            my(undef,$node1,$node2,$res)=split(/\s+/,lc($_));
            add_g(\%g,$node1,$node2,1/$res);
        }
    }
    close FI;
    return \%g;
}

sub remove_float {
    my ($hash_ref,$node1,$node2) = @_;

    my $flag_of_remove = 0;

    foreach my $key (keys %$hash_ref) {
        next unless (defined($hash_ref->{$key})); # avoid key is deleted

        my $num_of_node_cnn2_key = my @nodes_cnn2_key = keys %{$hash_ref->{$key}};

        if (($num_of_node_cnn2_key == 1) && ($key ne "$node1") && ($key ne "$node2")) {
            # delete the node which only have 1 connection to other node, except the wanted node1 & node2
            delete $hash_ref->{$key};
            delete $hash_ref->{$nodes_cnn2_key[0]}{$key};
            delete $hash_ref->{$nodes_cnn2_key[0]} if (keys %{$hash_ref->{$nodes_cnn2_key[0]}} == 0);
            $flag_of_remove = 1;
            #print "remove $key $nodes_cnn2_key[0]\n";
        }
    }

    if ($flag_of_remove == 1) {
        remove_float($hash_ref,$node1,$node2);
    }
}

sub star2ret_transfer {
    ### star to reticular res network transfer, can reduce one node

    my ($hash_ref,$center_node,$other_node_ary_ref)=@_;

    return if ($#$other_node_ary_ref == 0); # return if center_node has only 1 connection.

    my $g_loop=0;
    foreach my $n (@$other_node_ary_ref) {
        $g_loop+=$hash_ref->{$center_node}{$n};
    }

    for my $i (0..$#$other_node_ary_ref) {
        for my $j ($i+1..$#$other_node_ary_ref) {
            my $g1=$hash_ref->{$center_node}{$other_node_ary_ref->[$i]};
            my $g2=$hash_ref->{$center_node}{$other_node_ary_ref->[$j]};
            my $new_g=$g1*$g2/$g_loop;

            &add_g($hash_ref,$other_node_ary_ref->[$i],$other_node_ary_ref->[$j],$new_g);
        }

        delete $hash_ref->{$other_node_ary_ref->[$i]}{$center_node};
        #delete $hash_ref->{$other_node_ary_ref->[$i]} if (keys %{$hash_ref->{$other_node_ary_ref->[$i]}} == 0);
    }
    delete $hash_ref->{$center_node};
}

sub add_g {
    my ($hash_ref,$node1,$node2,$value)=@_;

    if (exists($hash_ref->{$node1}{$node2})) {
        # if exist res between node1 and node2, then g12 = g12(old) + g12(new)
        $hash_ref->{$node1}{$node2} += $value;
        $hash_ref->{$node2}{$node1} += $value;
    } else {
        # if res between node1 and node2 is new, then create the g12
        $hash_ref->{$node1}{$node2}  = $value;
        $hash_ref->{$node2}{$node1}  = $value;
    }
    #return $hash_ref;
}

sub usage {

    print <<EOF;

    Usage:
      $0 res_file node1 node2
    ---
      res_file: Resistance file, contain res like "R01 node1 node2 10".
      node1   : node1 of res network
      node2   : node2 of res network
    ---
    Description:
      This script is used to caculate res between node1 and node2, based on the res network in "res_file"
EOF
    exit;

}
