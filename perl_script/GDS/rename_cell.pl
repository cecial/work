#!/home/wangy/localperl/bin/perl
#use lib "";
use GDS2;

if (@ARGV < 2) {
    &usage();
}

my $gdsin=shift(@ARGV);
my $gdsout="$gdsin.rename_cell.gds";

unless (-e "$gdsin") {
    print "\nERROR: $gdsin doesn't exist, please check\n\n";
    exit;
}

my $suffix=shift(@ARGV);

my %except_cell=();
my %only_cell=();

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
                $except_cell{$e}=1;
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
                $only_cell{$e}=1;
            }
        }
    } else {
        print "\nERROR: unknown option $a\n\n";
        &usage();
    }
}

my $gds2IN = new GDS2(-fileName=>$gdsin);
my $gds2OUT = new GDS2(-fileName=>">$gdsout");

while (my $record = $gds2IN -> readGds2Record) {

    if ($gds2IN -> returnRecordTypeString eq "STRNAME") {
        my $cell= $gds2IN -> returnStrname;
        my $new_cell = "${cell}_$suffix";

        if (defined($except_cell{$cell})) {
            $gds2OUT -> printRecord(-data=>$record);
        } elsif (defined($only_cell{$cell})) {
            $gds2OUT -> printStrname( -name => $new_cell );
            print "Rename $cell to $new_cell\n";
        } else {
            if (keys %except_cell) {
                $gds2OUT -> printStrname( -name => $new_cell );
                print "Rename $cell to $new_cell\n";
            } elsif (keys %only_cell) {
                $gds2OUT -> printRecord(-data=>$record);
            } else {
                $gds2OUT -> printStrname( -name => $new_cell );
                print "Rename $cell to $new_cell\n";
            }
        }
    } elsif ($gds2IN -> returnRecordTypeString eq "SNAME") {

        my $cell= $gds2IN -> returnSname;
        my $new_cell = "${cell}_$suffix";

        if (defined($except_cell{$cell})) {
            $gds2OUT -> printRecord(-data=>$record);
        } elsif (defined($only_cell{$cell})) {
            $gds2OUT -> printSname( -name => $new_cell );
        } else {
            if (keys %except_cell) {
                $gds2OUT -> printSname( -name => $new_cell );
            } elsif (keys %only_cell) {
                $gds2OUT -> printRecord(-data=>$record);
            } else {
                $gds2OUT -> printSname( -name => $new_cell );
            }
        }
    } else {
        $gds2OUT -> printRecord(-data=>$record);
    }
}

$gds2IN -> close;
$gds2OUT -> close;

sub usage {
    print <<EOF;

    $0 <gds file> <suffix> [-except <cell1> [<cell2> ...] | -only <cell1> [<cell2> ...]]

    ---
    gds file                : gds file
    suffix                  : suffix to rename cells, <cell> => <cell_suffix>, better to use a special suffix to avoid conflicated with un-renamed cells
    -except                 : rename all cells except the excluded cells
    -only                   : rename all cells in specified cells
                            : if -except or -only not specified, will delete layers in all cells
    ---

EOF
    exit;
}

