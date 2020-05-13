#!/home/wangy/localperl/bin/perl
#use lib "";
use GDS2;

if (@ARGV < 2) {
    print <<EOF;

    Usage:
        $0 <gds file> <top cell>
        ---
        remove text in gds file except for top cell, note top cell is case-sensitive

EOF
    exit;
}

$layer_map[141][0]="m1text";
$layer_map[142][0]="m2text";
$layer_map[143][0]="m3text";
$layer_map[144][0]="m4text";
$layer_map[145][0]="m5text";
#$\="\n";

$gdsin=$ARGV[0];
$topcell=$ARGV[1];
$gdsout="$gdsin.no.text.gds";

$find_cell=0;
my $gds2IN = new GDS2(-fileName=>$gdsin);
while (my $record = $gds2IN -> readGds2Record) {
    #print $gds2IN -> returnRecordAsString;
    #next;

    last if ($find_cell==1);
    if ($gds2IN -> returnRecordTypeString eq "BGNSTR") { 
        # find a structure(cell)


        my $cell="";
        while(my $record1 = $gds2IN -> readGds2Record) {
            if ($gds2IN -> returnRecordTypeString eq "STRNAME") {
                #structure name
                (undef,$cell)=$gds2IN -> returnRecordAsString =~ /(\S+)/g;
                $cell=~s/'//g;
                if ($cell ne $topcell) {
                    # ignore for no wanted cell
                    # exit the while loop, go to print record
                    last;
                } else {
                    $find_cell=1;
                }

            } elsif ($gds2IN -> returnRecordTypeString eq "TEXT") {
                my ($layer_number,$layer_type,$x,$y,$str)=();
                while(my $record2 = $gds2IN -> readGds2Record) {
                    if ($gds2IN -> returnRecordTypeString eq "LAYER") {
                        (undef,$layer_number)=$gds2IN -> returnRecordAsString =~ /(\S+)/g;
                    } elsif ($gds2IN -> returnRecordTypeString eq "TEXTTYPE") {
                        (undef,$layer_type)=$gds2IN -> returnRecordAsString =~ /(\S+)/g;
                    } elsif ($gds2IN -> returnRecordTypeString eq "XY") {
                        (undef,$x,$y)=$gds2IN -> returnRecordAsString =~ /(\S+)/g;
                    } elsif ($gds2IN -> returnRecordTypeString eq "STRING") {
                        (undef,$str)=$gds2IN -> returnRecordAsString =~ /(\S+)/g;
                        $str=~s/'//g;
                    } elsif ($gds2IN -> returnRecordTypeString eq "ENDEL") {
                        if (defined($layer_map[$layer_number][$layer_type])) {
                            print "INFO: find \"$str\" ($layer_map[$layer_number][$layer_type], $layer_number:$layer_type) @($x,$y) in cell \"$cell\"\n";
                        } else {
                            print "WARN: find \"$str\" (unkown_layer, $layer_number:$layer_type) @($x,$y) in cell \"$cell\"\n";
                        }

                        last;
                    }
                }
            } elsif ($gds2IN -> returnRecordTypeString eq "ENDSTR") {
                last;
            } else {
            }
        }
    }
}
