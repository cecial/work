#!/home/wangy/localperl/bin/perl
#use lib "";
use GDS2;

if (@ARGV < 1) {
    print <<EOF;

    Usage:
        $0 <gds file>
        ---
        remove text in gds file except for top cell, note top cell is case-sensitive

EOF
    exit;
}

#$\="\n";

$gdsin=$ARGV[0];

my $gds2IN = new GDS2(-fileName=>$gdsin);

my $layer_number="";
my $layer_type="";

my %layer=();

while (my $record = $gds2IN -> readGds2Record) {
    if ($gds2IN -> returnRecordTypeString eq "LAYER") {
        $find_layer_number=1;
        (undef,$layer_number)=$gds2IN -> returnRecordAsString =~ /(\S+)/g;
    } elsif ($gds2IN -> returnRecordTypeString eq "TEXTTYPE" && $find_layer_number==1) {
        $find_layer_number=0;
        (undef,$layer_type)=$gds2IN -> returnRecordAsString =~ /(\S+)/g;
        $layer{$layer_number}{$layer_type}="TEXT";
    } elsif ($gds2IN -> returnRecordTypeString eq "DATATYPE" && $find_layer_number==1) {
        $find_layer_number=0;
        (undef,$layer_type)=$gds2IN -> returnRecordAsString =~ /(\S+)/g;
        $layer{$layer_number}{$layer_type}="DATA";
    } else {
        $find_layer_number=0;
        $layer_number="";
        $layer_type="";
    }
}

foreach my $k (sort {$a <=> $b} keys %layer) {
    foreach my $j (sort {$a <=> $b} keys %{$layer{$k}}) {
        print "$k:$j $layer{$k}{$j}\n";
    }
}


