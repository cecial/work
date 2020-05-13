#!/home/wangy/localperl/bin/perl
#use lib "";
use GDS2;

if (@ARGV < 4) {
    &usage();
}

my ($gdsin1,$cell1,$gdsin2,$cell2)=@ARGV;
my $gdsout="$gdsin1.replace_cell.gds";

unless (-e "$gdsin1") {
    print "\nERROR: $gdsin1 doesn't exist, please check\n\n";
    exit;
}

unless (-e "$gdsin2") {
    print "\nERROR: $gdsin2 doesn't exist, please check\n\n";
    exit;
}

my %gds1_cell=();
my $gds2IN10 = new GDS2(-fileName=>$gdsin1);
while (my $record = $gds2IN10 -> readGds2Record) {

    if ($gds2IN10 -> returnRecordTypeString eq "STRNAME") {
        my $cell= $gds2IN10 -> returnStrname;
        $gds1_cell{$cell}=1;
    }
}
$gds2IN10 -> close;

my %gds2_cell_hier=();
my $gds2IN20 = new GDS2(-fileName=>$gdsin2);
my $cell="";
my $sname="";
while (my $record = $gds2IN20 -> readGds2Record) {
    if ($gds2IN20 -> returnRecordTypeString eq "STRNAME") {
        $cell= $gds2IN20 -> returnStrname;
    } elsif ($gds2IN20 -> returnRecordTypeString eq "SNAME") {
        $sname=$gds2IN20 -> returnSname;
        $gds2_cell_hier{$cell}{$sname}=1;
    } elsif ($gds2IN20 -> returnRecordTypeString eq "ENDSTR") {
        $cell="";
        $sname="";
    } 
}
$gds2IN20 -> close;




my %needed_cell2=();
$needed_cell2{$cell2}=1;
my @tmp_cell2=keys %needed_cell2;

while(my $check_cell= shift(@tmp_cell2)) {
    print "check hier $check_cell\n";

    foreach my $involved_cell (keys %{$gds2_cell_hier{$check_cell}}) {
        unless (defined($needed_cell2{$involved_cell})) {
            push @tmp_cell2,$involved_cell;
            $needed_cell2{$involved_cell}=1;
        }
    }

}

#print join (" ",keys %needed_cell2);
#print "\n";
#exit;


my $gds2IN1 = new GDS2(-fileName=>$gdsin1);
my $gds2IN2 = new GDS2(-fileName=>$gdsin2);
my $gds2OUT = new GDS2(-fileName=>">$gdsout");

my $find_cell1=0;

while (my $record1 = $gds2IN1 -> readGds2Record) {

    if ($gds2IN1 -> returnRecordTypeString eq "BGNSTR") {
        my $rdt = $gds2IN1 -> readGds2Record;
        my $cell1t= $gds2IN1 -> returnStrname;
        print "find $cell1t in gds1\n";
        if ($cell1t eq $cell1) {
            $find_cell1 = 1; 
        } else {
            $gds2OUT -> printRecord( -data=> $record1);
            $gds2OUT -> printRecord( -data=> $rdt);
        }
    } elsif ($gds2IN1 -> returnRecordTypeString eq "ENDSTR") {
        if ($find_cell1 == 1) {
            $find_cell1 = 0;
        } else {
            $gds2OUT -> printRecord( -data=> $record1);
        }

    } elsif ($gds2IN1 -> returnRecordTypeString eq "ENDLIB") {
        #import gds2 here

        print "start import $gdsin2\n";
        my $need_import=0;
        while (my $record2 = $gds2IN2 -> readGds2Record) {
            if ($gds2IN2 -> returnRecordTypeString eq "BGNSTR") {
                my $rdt2 = $gds2IN2 -> readGds2Record;
                my $cell2t = $gds2IN2 -> returnStrname;

                print "find $cell2t in gds2\n";
                if (defined($needed_cell2{$cell2t})) {
                    print "import $cell2t into $gdsin1\n";
                    $gds2OUT -> printRecord( -data=> $record2);
                    if ($cell2t eq $cell2) {
                        $gds2OUT -> printStrname(-name => $cell1);
                    } else {
                        if (defined($gds1_cell{$cell2t})) {
                            print "\nWARN: $cell2t duplicated in $gdsin1 and $gdsin2\n\n";
                        } 
                        $gds2OUT -> printRecord( -data=> $rdt2);
                    }
                    $need_import=1;
                }
            } elsif ($gds2IN2 -> returnRecordTypeString eq "ENDSTR") {
                $gds2OUT -> printRecord( -data=> $record2);
                print "import done\n" if ($need_import==1);
                $need_import=0;
            } else {
                if ($need_import == 1) {
                    $gds2OUT -> printRecord( -data=> $record2);
                }
            }
        }

        $gds2OUT -> printRecord( -data=> $record1);

    } else {
        unless ($find_cell1 == 1) {
            $gds2OUT -> printRecord( -data=> $record1);
        }
    }
}
$gds2IN1 -> close;
$gds2IN2 -> close;
$gds2OUT -> close;


sub usage {
    print <<EOF;

    $0 <gds1 file> <cell1> <gds2 file> <cell2>

    ---
    gds1/cell1              : cell1 in gds1 will be replaced
    gds2/cell2              : cell2 in gds2 will replace cell1 in gds1
    ---
    copy cell2 and its involved cells in gds2 into gds1, make sure NO SAME cell name in gds1 and gds2 except the cell to be replaced, or else some unwanted error will occur

EOF
    exit;
}

