#!/home/wangy/localperl/bin/perl
#use lib "";
use GDS2;

if (@ARGV < 2) {
    &usage();
}

my $gdsin=shift(@ARGV);
my $gdsout="$gdsin.delete_cell_all.gds";

unless (-e "$gdsin") {
    print "\nERROR: $gdsin doesn't exist, please check\n\n";
    exit;
}

my %delete_cell=();
foreach my $c (@ARGV) {
    $delete_cell{$c}=1;
}

my $gds2IN = new GDS2(-fileName=>$gdsin);
my $gds2OUT = new GDS2(-fileName=>">$gdsout");

while (my $record = $gds2IN -> readGds2Record) {

    if ($gds2IN -> returnRecordTypeString eq "SREF" || $gds2IN -> returnRecordTypeString eq "AREF") {
        my $rd1 = $gds2IN -> readGds2Record;
        my $sname= $gds2IN -> returnSname;

        if (defined($delete_cell{$sname})) {
            print "delete calling of $sname\n";
            while($gds2IN -> readGds2Record) {
                if ($gds2IN -> returnRecordTypeString eq "ENDEL") {
                    last;
                }
            }
        } else {
            $gds2OUT -> printRecord(-data=>$record);
            $gds2OUT -> printRecord(-data=>$rd1);
        }
    } else {
        $gds2OUT -> printRecord(-data=>$record);
    }
}

$gds2IN -> close;
$gds2OUT -> close;

sub usage {
    print <<EOF;

    $0 <gds file> <cell1> [<cell2> ...]

    ---
    gds file                : gds file
    cell                    : cell in gds 
                            : note that, this script doesn't delete the cell, but only delete the calling of cells
    ---

EOF
    exit;
}

