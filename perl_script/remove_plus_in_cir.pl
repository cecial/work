#!/usr/bin/perl -w

if (@ARGV < 1) {
    print <<EOF;

    Usage:
      $0 <cir file>

EOF
    exit;
}

$org_cir = $ARGV[0];
$new_cir = "$org_cir.no_plus";

open (FI,"$org_cir") || die "$org_cir, $!\n";
@org_cir=(<FI>);
close FI;

open (FO,">$new_cir") || die "$new_cir, $!\n";

while(my $line=shift(@org_cir)) {
    my ($status,$new_line) = &check_line($line);
    if ($status eq "normal_line") {
        print FO $new_line;
        my @tmp_lines=();

        while(my $line1=shift(@org_cir)) {
            my ($status1,$new_line1) = &check_line($line1);
            if ($status1 eq "normal_line") {
                unshift(@org_cir,$line1);
                last;
            } elsif ($status1 eq "plus_line") {
                $new_line1=~s/^\s*\+\s*/ /;
                print FO $new_line1;
            } else {
                push @tmp_lines,$line1;
            }
        }

        print FO "\n";
        @org_cir=(@tmp_lines,@org_cir);
    } elsif ($status eq "commented_line_wo_plus" || $status eq "commented_line_wi_plus") {
        print FO $new_line;
        my @tmp_lines=();

        while(my $line1=shift(@org_cir)) {
            my ($status1,$new_line1) = &check_line($line1);
            if ($status1 eq "normal_line" || $status1 eq "commented_line_wo_plus") {
                unshift(@org_cir,$line1);
                last;
            } elsif ($status1 eq "commented_line_wi_plus") {
                $new_line1=~s/^\s*[\*\$]\s*\+/ /;
                print FO $new_line1;
            } else {
                push @tmp_lines,$line1;
            }
        }
        print FO "\n";
        @org_cir=(@tmp_lines,@org_cir);
    } elsif ($status eq "empty_line") {
        print FO "\n";
    } else {
        print "can't deal line: $line\n\n";
    }
}

close FO;
print "\n    please check $new_cir\n\n";


sub check_line {
    my $line=shift(@_);
    chomp($line);
    $line=~s/^\s+//g;
    $line=~s/\s+$//g;
    $line=~s/\s+/ /g;

    my $status="";
    if ($line=~/^\s*$/) {
        $status="empty_line";
    } elsif ($line=~/^\s*[\*\$]\s*[^\+]/) {
        $status="commented_line_wo_plus";
    } elsif ($line=~/^\s*[\*\$]\s*\+/) {
        $status="commented_line_wi_plus";
    } elsif ($line=~/^\s*\+/) {
        $status="plus_line";
        #$line=~s/^\s*\+\s*/ /;
    } elsif ($line=~/^\s*\.subckt\b/i) {
        $status="normal_line";
    } elsif ($line=~/^\s*\.ends\b/i) {
        $status="normal_line";
    } elsif ($line=~/^\s*\.param\b/i) {
        $status="normal_line";
    } elsif ($line=~/^\s*\.options?\b/i) {
        $status="normal_line";
    } elsif ($line=~/^\s*\w+\b/i) {
        $status="normal_line";
    } else {
        $status="unknown_line";
        print "unknown line: $line\n";
    }

    return ($status,$line);
}
