#!/home/wangy/localperl/bin/perl
#use lib "";
use GDS2;

$metal_map[48][2]="metal4";
$metal_map[59][2]="metal2";
$metal_map[60][2]="metal3";
$metal_map[142][0]="metal2";
$metal_map[143][0]="metal3";
#$\="\n";
my $gds2File = new GDS2(-fileName=>$ARGV[0]);
while ($gds2File -> readGds2Record)
{
    #print $gds2File -> returnRecordAsString;
    #next;
    if ($gds2File -> returnRecordTypeString eq "BGNSTR") {
        $cell="";
        while($gds2File -> readGds2Record) {
            if ($gds2File -> returnRecordTypeString eq "STRNAME") {
                (undef,$cell)=$gds2File -> returnRecordAsString =~ /(\S+)/g;
                $cell=~s/'//g;
                $print_cell=0;
            } elsif ($gds2File -> returnRecordTypeString eq "TEXT") {
                ($layer_number,$layer_type,$x,$y,$str)=();
                while($gds2File -> readGds2Record) {
                    if ($gds2File -> returnRecordTypeString eq "LAYER") {
                        (undef,$layer_number)=$gds2File -> returnRecordAsString =~ /(\S+)/g;
                    } elsif ($gds2File -> returnRecordTypeString eq "TEXTTYPE") {
                        (undef,$layer_type)=$gds2File -> returnRecordAsString =~ /(\S+)/g;
                    } elsif ($gds2File -> returnRecordTypeString eq "XY") {
                        (undef,$x,$y)=$gds2File -> returnRecordAsString =~ /(\S+)/g;
                    } elsif ($gds2File -> returnRecordTypeString eq "STRING") {
                        (undef,$str)=$gds2File -> returnRecordAsString =~ /(\S+)/g;
                        $str=~s/'//g;
                        #if ($str=~/_[io]p[vh]/i && defined($metal_map[$layer_number][$layer_type])) {
                        if ($str=~/^[ABCDEF]/i && defined($metal_map[$layer_number][$layer_type])) {
                            if ($print_cell == 0) {
                                print "Create $cell probe file: $cell.probe_file\n";
                                open (FO,">$cell.probe_file") || die "create,$cell.probe_file,$!\n";
                                print FO "CELL $cell\n\n";
                            }
                            print FO "$str $x $y $metal_map[$layer_number][$layer_type]\n";
                            $print_cell=1;
                        }
                    } elsif ($gds2File -> returnRecordTypeString eq "ENDEL") {
                        last;
                    }

                }
            } elsif ($gds2File -> returnRecordTypeString eq "ENDSTR") {
                close FO;
                last;
            }
        }
    }
}

