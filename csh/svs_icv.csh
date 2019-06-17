#!/bin/csh -f

if ($#argv <4) then
    echo ""
    echo "    Usage:"
    echo "      $0 cell_list ruledeck netlist1 netlist2"
    echo ""
    exit
endif

set cell_list = $argv[1]
set ruledeck  = $argv[2]
set netlist1  = $argv[3]
set netlist2  = $argv[4]

foreach f (ruledeck netlist1 netlist2)
    eval echo \$$f | grep ^/ >& /dev/null
    if ($? == 0) then
        # absolute path
    else
        set tmp = `eval echo \$$f`
        set $f = "../$tmp"
    endif
end

#echo $cell_list $ruledeck $netlist1 $netlist2
foreach cell (`cat $cell_list`)
    mkdir -p $cell
    cd $cell

    #sed -e '/^LAYOUT PRIMARY/d' -e '/^LAYOUT PATH/d' -e '/^LAYOUT SYSTEM/d' -e '/^SOURCE PRIMARY/d' -e '/^SOURCE PATH/d' -e '/^SOURCE SYSTEM/d' -e '/^LVS REPORT "/d' $ruledeck > ruledeck
    #echo 'LAYOUT PRIMARY      "'$cell'"'     >> ruledeck
    #echo 'LAYOUT PATH         "'$netlist1'"' >> ruledeck
    #echo 'LAYOUT SYSTEM       SPICE'         >> ruledeck
    #echo 'SOURCE PRIMARY      "'$cell'"'     >> ruledeck
    #echo 'SOURCE PATH         "'$netlist2'"' >> ruledeck
    #echo 'SOURCE SYSTEM       SPICE'         >> ruledeck
    #echo 'LVS REPORT          "lvs.rep"'     >> ruledeck
    echo "run SVS for $cell"

    #calibre -lvs -calex2 ruledeck >&log_&
    icv -C -s $netlist1 -sf SPICE -stc $cell -ln $netlist2 -lnf SPICE -c $cell $ruledeck >& log_svs&

    cd ..
    sleep 1
end
