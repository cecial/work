#!/home/wangy/localperl/bin/perl
#use lib "";
use GDS2;

if (@ARGV < 1) {
    &usage();
}

my $gdsin=shift(@ARGV);
my $gdsout="$gdsin.remove_text.gds";

unless (-e "$gdsin") {
    print "\nERROR: $gdsin doesn't exist, please check\n\n";
    exit;
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
    } else {
        print "\nERROR: unknown option $a\n\n";
        &usage();
    }
}

my $gds2IN = new GDS2(-fileName=>$gdsin);
my $gds2OUT = new GDS2(-fileName=>">$gdsout");

my $find_delete_cell=0;
my $find_text=0;
my @tmp_records=();
my $layer_number="";
my $layer_type="";
my $string="";

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

    } elsif ($gds2IN -> returnRecordTypeString eq "TEXT") {
        $find_text=1;
        $layer_number="";
        $layer_type="";
        $string="";
        $gds2OUT -> printRecord(-data=>$record) if ($find_delete_cell==0 || $find_text==0);
    } elsif ($gds2IN -> returnRecordTypeString eq "LAYER") {
        $layer_number = $gds2IN -> returnLayer;
        $gds2OUT -> printRecord(-data=>$record) if ($find_delete_cell==0 || $find_text==0);
    } elsif ($gds2IN -> returnRecordTypeString eq "TEXTTYPE") {
        $layer_type = $gds2IN -> returnTexttype;
        $gds2OUT -> printRecord(-data=>$record) if ($find_delete_cell==0 || $find_text==0);
    } elsif ($gds2IN -> returnRecordTypeString eq "STRING") {
        $string = $gds2IN -> returnString;
        $gds2OUT -> printRecord(-data=>$record) if ($find_delete_cell==0 || $find_text==0);
    } elsif ($gds2IN -> returnRecordTypeString eq "ENDEL" ) {
        if ($find_delete_cell==1 && $find_text==1) {
            print "INFO: delete $string ($layer_number:$layer_type) in cell \"$cell\"\n";
        } else {
            $gds2OUT -> printRecord(-data=>$record);
        }
        $find_text=0;
    } else {
        $gds2OUT -> printRecord(-data=>$record) if ($find_delete_cell==0 || $find_text==0);
    }
}

$gds2IN -> close;
$gds2OUT -> close;

sub usage {
    print <<EOF;

    $0 <gds file> [-except <cell1> [<cell2> ...] | -only <cell1> [<cell2> ...]]

    ---
    gds file                : gds file
    -except                 : delete text in all cells in gds file except the excluded cells
    -only                   : delete text in specified cells
                            : if -except or -only not specified, will delete layers in all cells
    ---

EOF
    exit;
}

