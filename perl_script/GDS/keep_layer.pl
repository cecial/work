#!/home/wangy/localperl/bin/perl
#use lib "";
use GDS2;

if (@ARGV < 3) {
    print <<EOF;

    Usage:
        $0 <gds file> <top cell> <layer_number:layer_type> [<layer_number2:layer_type2>] ...
        ---
        remove layers in gds file except for top cell, note top cell is case-sensitive

EOF
    exit;
}

@layer_map=();

foreach my $ll (@ARGV[2..$#ARGV]) {
    my ($n,$t)=split(/:/,$ll);
    $layer_map[$n][$t]=1;
}
#$\="\n";

$gdsin=$ARGV[0];
$topcell=$ARGV[1];
$gdsout="$gdsin.keep_layer.gds";

my $gds2IN = new GDS2(-fileName=>$gdsin);
my $gds2OUT = new GDS2(-fileName=>">$gdsout");

my $find_layer=0;
my @tmp_records=();
my $layer_number="";
my $layer_type="";

my $cell="";

while (my $record = $gds2IN -> readGds2Record) {

    if ($gds2IN -> returnRecordTypeString eq "STRNAME") {
        $cell= $gds2IN -> returnStrname;
        if ($cell eq $topcell) {
            $gds2OUT -> printRecord(-data=>$record);
        } else {
            my $new_name = $cell . "_RENAMEDD";
            $gds2OUT -> printStrname( -name => $new_name );
        }
    } elsif ($gds2IN -> returnRecordTypeString eq "SNAME") {
        my $new_name = $gds2IN -> returnSname . "_RENAMEDD";
        $gds2OUT -> printSname( -name => $new_name );
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
    } elsif ($gds2IN -> returnRecordTypeString eq "ENDEL") {
        push @tmp_records,$record;
        if (!defined($layer_map[$layer_number][$layer_type])) {
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
