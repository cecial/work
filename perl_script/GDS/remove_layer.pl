#!/home/wangy/localperl/bin/perl
#use lib "";
use GDS2;

if (@ARGV < 2) {
    &usage();
}

my $gdsin=shift(@ARGV);
my $gdsout="$gdsin.remove_layer.gds";

unless (-e "$gdsin") {
    print "\nERROR: $gdsin doesn't exist, please check\n\n";
    exit;
}

my @delete_layer=();

if($ARGV[0] =~ /^(\d+):(\d+)$/) {
    $delete_layer[$1][$2]=1;
    shift(@ARGV);
}

my %except_in_cell=();
my %only_in_cell=();

while (my $a = shift(@ARGV)) {
    if ($a eq "-except") {
        unless (@ARGV) {
            print "\nERROR: at least one cell should be after -except\n\n";
            &usage();
        }

        while (my $e = shift(@ARGV)) {
            if ($e eq "-only") {
                print "\nERROR: -except and -only should not use at same time\n\n";
                &usage();
            } else {
                $except_in_cell{$e}=1;
            }
        }
    } elsif ($a eq "-only") {
        unless (@ARGV) {
            print "\nERROR: at least one cell should be after -only\n\n";
            &usage();
        }
        while (my $e = shift(@ARGV)) {
            if ($e eq "-except") {
                print "\nERROR: -except and -only should not use at same time\n\n";
                &usage();
            } else {
                $only_in_cell{$e}=1;
            }
        }
    } elsif ($a=~/^(\d+):(\d+)$/) {
        $delete_layer[$1][$2]=1;
    } else {
        print "\nERROR: unknown option $a\n\n";
        &usage();
    }
}

my $gds2IN = new GDS2(-fileName=>$gdsin);
my $gds2OUT = new GDS2(-fileName=>">$gdsout");

my $find_delete_cell=0;
my $find_layer=0;
my @tmp_records=();
my $layer_number="";
my $layer_type="";

my $cell="";

while (my $record = $gds2IN -> readGds2Record) {

    if ($gds2IN -> returnRecordTypeString eq "STRNAME") {
        $cell= $gds2IN -> returnStrname;

        $find_delete_cell=0;
        if (defined($except_in_cell{$cell})) {
            $find_delete_cell=0;
        } elsif (defined($only_in_cell{$cell})) {
            $find_delete_cell=1;
        } else {
            if (keys %except_in_cell) {
                $find_delete_cell=1;
            } elsif (keys %only_in_cell) {
                $find_delete_cell=0;
            } else {
                $find_delete_cell=1;
            }
        }

        $gds2OUT -> printRecord(-data=>$record);

    } elsif ($gds2IN -> returnRecordTypeString eq "BOUNDARY" || $gds2IN -> returnRecordTypeString eq "TEXT" || $gds2IN -> returnRecordTypeString eq "PATH") {
        push @tmp_records,$record;
        $find_layer=1;
        $layer_number="";
        $layer_type="";
    } elsif ($gds2IN -> returnRecordTypeString eq "LAYER") {
        $layer_number = $gds2IN -> returnLayer;
        push @tmp_records,$record if ($find_layer==1);
    } elsif ($gds2IN -> returnRecordTypeString eq "DATATYPE" || $gds2IN -> returnRecordTypeString eq "TEXTTYPE") {
        if ($gds2IN -> returnDatatype != "-1") {
            $layer_type = $gds2IN -> returnDatatype;
        }
        if ($gds2IN -> returnTexttype != "-1") {
            $layer_type = $gds2IN -> returnTexttype;
        }
        push @tmp_records,$record if ($find_layer==1);

    } elsif ($gds2IN -> returnRecordTypeString eq "ENDEL" && $find_layer==1) {
        push @tmp_records,$record;
        if ($find_delete_cell==1 && $find_layer==1 && defined($delete_layer[$layer_number][$layer_type])) {
            print "INFO: delete layer $layer_number:$layer_type in cell \"$cell\"\n";
        } else {
            foreach my $r (@tmp_records) {
                $gds2OUT -> printRecord(-data=>$r);
            }
        }
        @tmp_records=();
        $find_layer=0;
    } else {
        if ($find_layer==1) {
            push @tmp_records,$record;
        } else {
            $gds2OUT -> printRecord(-data=>$record);
        }
    }
}

$gds2IN -> close;
$gds2OUT -> close;

sub usage {
    print <<EOF;

    $0 <gds file> <layer_number1:layer_type1> [<layer_number2:layer_type2> ...] [-except <cell1> [<cell2> ...] | -only <cell1> [<cell2> ...]]

    ---
    gds file                : gds file
    layer_number:layer_type : layer number and type, like 10:0
    -except                 : delete all specified layers in all cells in gds file except the excluded cells
    -only                   : delete all specified layers in specified cells
                            : if -except or -only not specified, will delete layers in all cells
    ---

EOF
    exit;
}

