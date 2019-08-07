#!/usr/bin/perl -w
use strict;
use warnings;

if (@ARGV<2) {
    print <<EOF;

    Usage:
        $0 <cir_file> <subckt name> [<X devices name1> <X devices name2> ...]
        ---
        cir_file: netlist file
        subckt name: the subckt name which you want to flattern
        X devices name: mos/diode/cap/res name, when prefix is X, please list here

EOF
    exit;
}

my ($cir,$topcell,@xdevices)=@ARGV;
$topcell=lc($topcell);

my $cir_content_ref=&__read_cir($cir);

my @global_pin=();
my %global_param=();
my %cir=();

while (my $line=shift(@$cir_content_ref)) {
    #print "##$line\n";
    if ($line=~s/^\s*\.param(eter)?\b\s+//i) {
        my @parameter_pairs=split(/\s+/,$line);
        #print "$line\n";
        foreach my $pp (@parameter_pairs) {
            my @tmp=split(/=/,$pp);
            #print "@tmp\n";
            $global_param{$tmp[0]}=$tmp[1];
        }
    } elsif ($line=~/^\.subckt\s+(\w+)/) {
        my @con=($line);
        while (my $line2=shift(@$cir_content_ref)) {
            if ($line2=~/^\.ends/) {
                push @con,$line2;
                last;
            } else {
                push @con,$line2;
            }
        }
        #foreach (@con) {
        #    print "#$_\n";
        #}
        #print "here2\n";
        my %h=&__create_subckt(@con);
        %cir=(%cir,%h);
        next;
    } elsif ($line=~s/^\s*\.global\b\s*//i) {
        @global_pin=split(/\s+/,$line);
    } else {
        print "WARN: $line is not recgnized\n";
    }
}

my %t=();

#print "here1\n";
#

__flattern($topcell,\%cir,"",$cir{$topcell}{"__pin"},\%t);


################################################################################


sub __flattern {
    my ($subckt,$cir_hash,$hier_path,$net_connect_to_pin,$parent_param)=@_;

    my %pin_to_net_map=();
    foreach my $i (0..$#{$cir_hash->{$subckt}{"__pin"}}) {
        $pin_to_net_map{$cir_hash->{$subckt}{"__pin"}[$i]} = $net_connect_to_pin->[$i];
    }

    #print "$subckt @{$cir_hash->{$subckt}{__parameter}}\n";
    my %subckt_header_param=%{$cir_hash->{$subckt}{"__parameter_hash"}};;
    foreach my $p (@{$cir_hash->{$subckt}{"__parameter"}}) {
        my $value=$cir_hash->{$subckt}{"__parameter_hash"}{$p};
        my @words=&__get_all_words($value);
        foreach my $w (@words) {
            if (defined($global_param{$w})) {
                $value=~s/\b\Q$w\E\b/$global_param{$w}/ig;
            } 
        }
        $subckt_header_param{$p}=$value;
    }
    %subckt_header_param=(%subckt_header_param,%{$parent_param});

    foreach my $x (@{$cir_hash->{$subckt}{"__block"}}) {
        my @net_to_pin=();
        foreach my $n (@{$cir_hash->{$subckt}{"__block_hash"}{$x}{"__connect"}}) {
            if (__is_exist_in_array($n,$cir_hash->{$subckt}{"__pin"})) {
                push @net_to_pin,$pin_to_net_map{$n};
                #print "$n is pin, @tmp\n";
            } elsif (__is_exist_in_array($n,$cir_hash->{$subckt}{"__net"})) {
                push @net_to_pin,"$hier_path$n";
                #print "$n is net, @tmp\n";
            } else {
                print "error: $n is not pin or net \n";
                print "error: pin: @{$cir_hash->{$subckt}{__pin}}\n";
                print "error: net: @{$cir_hash->{$subckt}{__net}}\n";
            }
        }
        #print "out2 $cir_info->{$subckt}{$x}{name},$cir_info,$hier$x.,@tmp\n";
        my %param_down_to_x = ();
        my $multi=1;
        foreach my $k (@{$cir_hash->{$subckt}{"__block_hash"}{$x}{"__parameter"}}) {
            my $value=$cir_hash->{$subckt}{__block_hash}{$x}{__parameter_hash}{$k};
            my @words=&__get_all_words($value);
            foreach my $w (@words) {
                if (defined($subckt_header_param{$w}) ) {
                    $value=~s/\b\Q$w\E\b/$subckt_header_param{$w}/ig;
                } elsif (defined($global_param{$w})) {
                    $value=~s/\b\Q$w\E\b/$global_param{$w}/ig;
                } else {
                    print "\nERROR1: $value of block $x in $subckt has no global or local parameter to replace\n";
                }
            }

            if ($k eq "m") {
                $value=~s/['"]//g;
                $multi = eval ($value);
                #print "eval m of #$value# => $multi\n";
            } else {
                $param_down_to_x{$k}=$value;
            }
        }

        if ($multi>=1) {
            foreach my $f (1..$multi) {
                my $ff="";
                if ($f > 1) {
                    $ff = "\@$f";
                }
                    
                __flattern($cir_hash->{$subckt}{"__block_hash"}{$x}{"__name"},$cir_hash,"$hier_path$x$ff.",\@net_to_pin,\%param_down_to_x);

            }
        } else {
            print "m < 1 of $x in $subckt\n";
        }
    }

    foreach my $x (@{$cir_hash->{$subckt}{"__device"}}) {
        #print "device3\n";
        print "$hier_path$x";
        #print "here device3\n";
        foreach my $n (@{$cir_hash->{$subckt}{"__device_hash"}{$x}{"__connect"}}) {
            if (__is_exist_in_array($n,\@global_pin)) {
                print " $n";
            } elsif (__is_exist_in_array($n,$cir_hash->{$subckt}{"__pin"})) {
                print " $pin_to_net_map{$n}";
            } elsif (__is_exist_in_array($n,$cir_hash->{$subckt}{"__net"})) {
                print " $hier_path$n";
            } else {
                print "error:";
                print "net: $n\n";
                print "pin: @{$cir_hash->{$subckt}{__pin}}\n";
            }
        }

        #print "here device4\n";

        # Mos/Diode Case
        if (defined($cir_hash->{$subckt}{"__device_hash"}{$x}{"__name"})) {
            print " $cir_hash->{$subckt}{__device_hash}{$x}{__name}";
        }

        ### Res/Cap case
        if (defined($cir_hash->{$subckt}{"__device_hash"}{$x}{"__value"})) {
            my $value=$cir_hash->{$subckt}{"__device_hash"}{$x}{"__value"};
            my @words=&__get_all_words($value);
            foreach my $w (@words) {
                if (defined($subckt_header_param{$w}) ) {
                    $value=~s/\b\Q$w\E\b/$subckt_header_param{$w}/ig;
                } elsif (defined($global_param{$w})) {
                    $value=~s/\b\Q$w\E\b/$global_param{$w}/ig;
                } else {
                    print "\nERROR2: $value of device $x in $subckt has no global or local parameter to replace\n";
                }
            }
            #print " $cir_hash->{$subckt}{__device_hash}{$x}{__value}";
            print " $value";
        }

        #print "here device5\n";

        foreach my $k (@{$cir_hash->{$subckt}{"__device_hash"}{$x}{"__parameter"}}) {
            my $value=$cir_hash->{$subckt}{__device_hash}{$x}{__parameter_hash}{$k};
            #print "\n# $k # $value#\n";
            my @words=&__get_all_words($value);
            foreach my $w (@words) {
                #print "## $w ##\n";
                if (defined($subckt_header_param{$w}) ) {
                    $value=~s/\b\Q$w\E\b/$subckt_header_param{$w}/ig;
                } elsif (defined($global_param{$w})) {
                    $value=~s/\b\Q$w\E\b/$global_param{$w}/ig;
                } else {
                    print "\nERROR3: $value of device $x in $subckt has no global or local parameter to replace\n";
                }
            }
            #print " $k=$cir_hash->{$subckt}{__device_hash}{$x}{__parameter_hash}{$k}";
            if ($value=~/['"]/) {
                $value=~s/['"]//g;
                $value="\"$value\"";
            }
            print " $k=$value";
        }

        #print "here device6\n";
        print "\n";
    }
}

sub __read_cir {
    my $cir=shift(@_);
    open(FI,"$cir") || die "$cir,$!\n";
    my @cir_content=(<FI>);
    close FI;
    #print "here3\n";
    @cir_content= &__remove_cir_plus(@cir_content);
    @cir_content = map {lc} @cir_content;
    #foreach (@cir_content) {
    #    print "###$_\n";
    #}
    return \@cir_content;
}

sub __create_subckt {

    my %hash=();

    my $subckt_name="";

    foreach my $line (@_) {
        if ($line=~/^\s*\.subckt\s+\w+/i) {
            my @pins_and_parameters=();
            (undef,$subckt_name,@pins_and_parameters)=split(/\s+/,$line);
            #print "$subckt_name\n";
            $hash{$subckt_name}{"__pin"}=[];
            $hash{$subckt_name}{"__pin_hash"}={};
            $hash{$subckt_name}{"__net"}=[];
            $hash{$subckt_name}{"__net_hash"}={};
            $hash{$subckt_name}{"__block"}=[];
            $hash{$subckt_name}{"__block_hash"}={};
            $hash{$subckt_name}{"__device"}=[];
            $hash{$subckt_name}{"__device_hash"}={};
            $hash{$subckt_name}{"__parameter"}=[];
            $hash{$subckt_name}{"__parameter_hash"}={};

            foreach my $pp (@pins_and_parameters) {
                if ($pp=~/=/) {
                    my @tmp=split(/=/,$pp);
                    push @{$hash{$subckt_name}{"__parameter"}},$tmp[0];
                    $hash{$subckt_name}{"__parameter_hash"}{$tmp[0]}=$tmp[1];
                } else {
                    push @{$hash{$subckt_name}{"__pin"}},$pp;
                    $hash{$subckt_name}{"__pin_hash"}{$pp}+=1;
                }
            }
        } elsif ($line=~s/^\s*\.param(eter)?\b//i) {
            my @parameters=split(/\s+/,$line);
            foreach my $p (@parameters) {
                my @tmp=split(/=/,$p);
                push @{$hash{$subckt_name}{"__parameter"}},$tmp[0];
                $hash{$subckt_name}{"__parameter_hash"}{$tmp[0]}=$tmp[1];
            }
        } elsif ($line=~/^\s*m/i) {
            my ($index,$d,$g,$s,$b,$mos_name,@parameters)=split(/\s+/,$line);
            push @{$hash{$subckt_name}{"__device"}},$index;
            $hash{$subckt_name}{"__net_hash"}{$d}=1;
            $hash{$subckt_name}{"__net_hash"}{$g}=1;
            $hash{$subckt_name}{"__net_hash"}{$s}=1;
            $hash{$subckt_name}{"__net_hash"}{$b}=1;

            $hash{$subckt_name}{"__device_hash"}{$index}{"__name"}=$mos_name;
            $hash{$subckt_name}{"__device_hash"}{$index}{"__parameter"}=[];
            $hash{$subckt_name}{"__device_hash"}{$index}{"__parameter_hash"}={};
            $hash{$subckt_name}{"__device_hash"}{$index}{"__connect"}=[];
            push @{$hash{$subckt_name}{"__device_hash"}{$index}{"__connect"}},$d;
            push @{$hash{$subckt_name}{"__device_hash"}{$index}{"__connect"}},$g;
            push @{$hash{$subckt_name}{"__device_hash"}{$index}{"__connect"}},$s;
            push @{$hash{$subckt_name}{"__device_hash"}{$index}{"__connect"}},$b;

            foreach my $p (@parameters) {
                if ($p=~/=/) {
                    my @tmp=split(/=/,$p);
                    push @{$hash{$subckt_name}{"__device_hash"}{$index}{"__parameter"}},$tmp[0];
                    $hash{$subckt_name}{"__device_hash"}{$index}{"__parameter_hash"}{$tmp[0]}=$tmp[1];
                } else {
                    print "$p is not parameter in line $line\n";
                }
            }
        } elsif ($line=~/^\s*d/i) {
            my ($index,$p,$n,$diode_name,@parameters)=split(/\s+/,$line);
            push @{$hash{$subckt_name}{"__device"}},$index;
            $hash{$subckt_name}{"__net_hash"}{$p}=1;
            $hash{$subckt_name}{"__net_hash"}{$n}=1;

            $hash{$subckt_name}{"__device_hash"}{$index}{"__name"}=$diode_name;
            $hash{$subckt_name}{"__device_hash"}{$index}{"__parameter"}=[];
            $hash{$subckt_name}{"__device_hash"}{$index}{"__parameter_hash"}={};
            $hash{$subckt_name}{"__device_hash"}{$index}{"__connect"}=[];
            push @{$hash{$subckt_name}{"__device_hash"}{$index}{"__connect"}},$p;
            push @{$hash{$subckt_name}{"__device_hash"}{$index}{"__connect"}},$n;

            foreach my $p (@parameters) {
                if ($p=~/=/) {
                    my @tmp=split(/=/,$p);
                    push @{$hash{$subckt_name}{"__device_hash"}{$index}{"__parameter"}},$tmp[0];
                    $hash{$subckt_name}{"__device_hash"}{$index}{"__parameter_hash"}{$tmp[0]}=$tmp[1];
                } else {
                    print "$p is not parameter in line $line\n";
                }
            }
        } elsif ($line=~/^\s*[rc]/i) {
            my ($index,$p,$n,$value)=split(/\s+/,$line);
            push @{$hash{$subckt_name}{"__device"}},$index;
            $hash{$subckt_name}{"__net_hash"}{$p}=1;
            $hash{$subckt_name}{"__net_hash"}{$n}=1;
            $hash{$subckt_name}{"__device_hash"}{$index}{"__value"}=$value;
            $hash{$subckt_name}{"__device_hash"}{$index}{"__connect"}=[];
            push @{$hash{$subckt_name}{"__device_hash"}{$index}{"__connect"}},$p;
            push @{$hash{$subckt_name}{"__device_hash"}{$index}{"__connect"}},$n;
        } elsif ($line=~/^\s*x/i) {
            my ($index,@nets_and_parameters)=split(/\s+/,$line);
            my @nets=();
            my $sub_name="";
            my @parameters=();

            foreach my $s (0..$#nets_and_parameters) {
                if ($s == $#nets_and_parameters) {
                    $sub_name=pop(@nets_and_parameters);
                    @nets=@nets_and_parameters;
                } elsif ($nets_and_parameters[$s+1]=~/=/) {
                    $sub_name=$nets_and_parameters[$s];
                    @nets=@nets_and_parameters[0..$s-1];
                    @parameters=@nets_and_parameters[$s+1..$#nets_and_parameters];
                    last;
                }
            }

            foreach my $n (@nets) {
                $hash{$subckt_name}{"__net_hash"}{$n}=1;
            }

            my $db="";

            #if (grep {/^$sub_name$/} @xdevices) {
            if (__is_exist_in_array($sub_name,\@xdevices)) {
                # devices with X prefix
                $db="__device_hash";
                push @{$hash{$subckt_name}{"__device"}},$index;
            } else {
                $db="__block_hash";
                push @{$hash{$subckt_name}{"__block"}},$index;
            }

            $hash{$subckt_name}{$db}{$index}{"__name"}=$sub_name;
            $hash{$subckt_name}{$db}{$index}{"__connect"}=\@nets;
            $hash{$subckt_name}{$db}{$index}{"__parameter"}=[];
            $hash{$subckt_name}{$db}{$index}{"__parameter_hash"}={};

            foreach my $p (@parameters) {
                if ($p=~/=/) {
                    my @tmp=split(/=/,$p);
                    push @{$hash{$subckt_name}{$db}{$index}{"__parameter"}},$tmp[0];
                    $hash{$subckt_name}{$db}{$index}{"__parameter_hash"}{$tmp[0]}=$tmp[1];
                } else {
                    $hash{$subckt_name}{"__net_hash"}{$p}=1;
                }
            }
        } elsif ($line=~/^\s*.global/i) {
        } elsif ($line=~/^\s*\.ends/i) {
        } else {
            print "unknown line $line\n";
        }
    }


    #$hash{$subckt_name}{"__net"}
    #print "nett: ", keys %{$hash{$subckt_name}{"__net_hash"}} , "\n";

    foreach my $p (@{$hash{$subckt_name}{"__pin"}}) {
        if ($hash{$subckt_name}{"__pin_hash"}{$p} > 1) {
            print "duplicate pin \"$p\" found in subckt $subckt_name, please check\n";
            print "pin: @{$hash{$subckt_name}{__pin}}\n";
            exit;
        }
    }

    foreach my $net (keys %{$hash{$subckt_name}{"__net_hash"}}) {
        if (defined($hash{$subckt_name}{"__pin_hash"}{$net})) {
            delete $hash{$subckt_name}{"__net_hash"}{$net};
        }
    }

    my @ttmp=keys %{$hash{$subckt_name}{"__net_hash"}};
    #print "HHH @ttmp\n";
    $hash{$subckt_name}{"__net"}=\@ttmp;

    return %hash;

}

sub __get_all_words {
    my $tmp=shift(@_);
    $tmp=~s/-?\d+(\.\d)?e[\+-]\d+/ /g; # remove scientific number;
    $tmp=~s/[\+\-\*\/]/ /g; #remove  + - * /
    my @tmp=$tmp=~/\b([a-z]\w*)/g;
    return @tmp;
}

sub __remove_cir_plus {
    my $tmp_l="";

    while (my $line=shift(@_)) {
        $line=~s/\$.*//g;
        next if ($line=~/^\s*[\*\$]/ || $line=~/^\s*$/);
        #while($line=~s/((['"]).*?)\s+(.*?\2)/$1$3/g) {}
        $line=&__remove_space_inside_quote($line);
        $tmp_l .= $line;
    }
    $tmp_l=~s/\n\s*\+/ /g;
    $tmp_l=~s/ +/ /g;
    $tmp_l=~s/\s*=\s*/=/g;
    my @subckt=split(/\n/,$tmp_l);
    return @subckt;
}

sub __remove_space_in_operation {
    my @lines=@_;
    foreach my $line (@lines) {
        while($line=~s/((['"]).*?)\s+(.*?\2)/$1$3/g) {
        }
        s/\s*=\s*/=/g;
    }
    return @lines;
}

sub __is_exist_in_array {
    my ($ele,$array_ref)=@_;

    foreach (@$array_ref) {
        return 1 if ($ele eq $_);
    }

    return 0;
}

sub __remove_space_inside_quote {

    my $line=$_[0];
    $line=~s/\s*=\s*/=/g;
    my @tmp=split(/\s+/,$line);
    
    my $find_eq=0;

    my $new_line=shift(@tmp);

    foreach my $e (@tmp) {
        if ($e=~/=/) {
            $find_eq=1;
            $new_line .= " $e";
        } elsif ($find_eq == 1) {
            $new_line .= "$e";
        } else {
            $new_line .= " $e";
        }
    }
    return "$new_line\n";
}

################################################################################
