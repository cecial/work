#!/usr/bin/perl -w

if (@ARGV<5) {
    print <<EOF;

    Usage:
        $0 <layer file> <gds1> <topcell1> <gds2> <topcell2>
    ---
        layer file: contains layer name/number/type, one line for one layer, use # to ignore lines, all defined layers will be compared. 
                    to speed up calibre drc run, please specify only layers you want to compare
                    use following format:
                    AA  10 0 
                    CT  11 0 
        gds1/gds2 : gds file to be compared
        topcell1/2: topcell to be compared

EOF
    exit;
}

my ($layer_file,$gds1,$top1,$gds2,$top2)=@ARGV;

open(FI,"$layer_file") || die "$layer_file,$!\n";
my %layer_number=();
my %layer_type=();
my %layer_name=();
my @layer=();
my $length=0;

while(<FI>){
    next if (/^\s*#/ || /^\s*$/);
    s/^\s*//;
    my ($name,$layer_number,$layer_type)=split;
    if (defined($layer_number{$name}) && ($layer_number{$name} != $layer_number || $layer_type{$name} != $layer_type)) {
        print "Warn: Find duplicate name $name for $layer_number{$name}:$layer_number{$name} && $layer_number:$layer_type, rename to ${name}_$layer_number:$layer_type for $layer_number:$layer_type\n";
        $name = "${name}_$layer_number:$layer_type";
    }

    if (defined($layer_name{"$layer_number:$layer_type"}) && $name ne $layer_name{"$layer_number:$layer_type"}) {
        print "Warn: Find duplicate layer_number/layer_type ${layer_number}:$layer_type with different Name $layer_name{'$layer_number:$layer_type'} && $name, will use $name for final\n";
    }

    $layer_number{$name}=$layer_number;
    $layer_type{$name}=$layer_type;
    $layer_name{"$layer_number:$layer_type"}=$name;

    push @layer,"$layer_number:$layer_type";

    $length = (length($layer_number) > $length) ? length($layer_number) : $length;

}
close FI;

my $bump=10**$length;

my $out="calibre_lvl";
my $rule="$out.rules";

open (FO,">$rule") || die "$rule, $!\n";
print FO <<EOF;
// Calibre XOR rule file 

DRC BOOLEAN NOSNAP45 YES
DRC CELL NAME YES CELL SPACE XFORM

PRECISION 1000.0
UNIT LENGTH 1e-06

LAYOUT INPUT EXCEPTION SEVERITY BOX_RECORD 2
LAYOUT INPUT EXCEPTION SEVERITY PATH_NONORIENTABLE 1

DRC CHECK TEXT ALL
DRC MAXIMUM RESULTS 1000

DRC RESULTS DATABASE "$out.db" ASCII
DRC SUMMARY REPORT "$out.rep"

LAYOUT PATH "$gds1"
LAYOUT PRIMARY "$top1"
LAYOUT SYSTEM GDSII

LAYOUT PATH2 "$gds2"
LAYOUT PRIMARY2 "$top2"
LAYOUT SYSTEM2 GDSII
LAYOUT BUMP2 $bump

EOF

my $map_start = 2 * $bump;
foreach my $el (@layer) {
    my ($l,$n) = split(/:/,$el);
    my $layer_name           = $layer_name{"$l:$n"};
    my $new_layer_number     = $l + $bump;
    my $map_old_layer_number = $map_start + 1;
    my $map_new_layer_number = $map_start + 2;
    $map_start +=2;

    print FO <<EOF;
LAYER MAP $l DATATYPE $n $map_old_layer_number
LAYER $layer_name.OLD $map_old_layer_number
LAYER MAP $new_layer_number DATATYPE $n $map_new_layer_number
LAYER $layer_name.NEW $map_new_layer_number
XOR.$layer_name {
    @ Compare $layer_name($l:$n)
    XOR $layer_name.OLD $layer_name.NEW
}
DRC CHECK MAP XOR.$layer_name ASCII

EOF

}

close FO;

print "\nCalibre XOR rule file: $rule generated\n\n";
system "calibre -drc $rule";
#system "calibre -rve calibre_lvl.db";


