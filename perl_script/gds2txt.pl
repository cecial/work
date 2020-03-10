#!/home/wangy/localperl/bin/perl
#use lib "";
use GDS2;

if (@ARGV < 1) {
    print <<EOF;
    Usage:
        $0 <gds file>
        ---
        print gds info as txt format

EOF
    exit;
}

$\="\n";
my $gds2File = new GDS2(-fileName=>$ARGV[0]);
while ($gds2File -> readGds2Record)
{
    print $gds2File -> returnRecordAsString;
    next;
}
