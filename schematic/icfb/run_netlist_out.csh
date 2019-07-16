#!/bin/csh -f

if ($#argv < 3) then
    echo ""
    echo "  Usage"
    echo "    $0 <library name> <cell name> <output netlist name> [cds.lib path]"
    echo "    cds.lib path: default is ../cds.lib"
    echo ""
    exit
endif

rm -rf ihnl map raw si.env si.foregnd.log si.log

set lib  = $argv[1]
set cell = $argv[2]
set out  = $argv[3]

if ($# == 4) then
    set cdslib = $argv[4]
else
    set cdslib = "../cds.lib"
endif

setenv CDS_Netlisting_Mode "Analog"

cat <<EOF > si.env
simLibName = "$lib"
simCellName = "$cell"
simViewName = "schematic"
simSimulator = "auCdl"
simNotIncremental = nil
simReNetlistAll = nil
simViewList = '("auCdl" "schematic")
simStopList = '("auCdl")
simNetlistHier = t
hnlNetlistFileName = "$out"
resistorModel = ""
shortRES = 2000.0
preserveRES = 't
checkRESVAL = 't
checkRESSIZE = 'nil
preserveCAP = 't
checkCAPVAL = 't
checkCAPAREA = 'nil
preserveDIO = 't
checkDIOAREA = 't
checkDIOPERI = 't
checkCAPPERI = 'nil
checkScale = "meter"
checkLDD = 'nil
pinMAP = 't
simPrintInhConnAttributes = 'nil
shrinkFACTOR = 0.0
globalPowerSig = ""
globalGndSig = ""
displayPININFO = 't
preserveALL = 't
setEQUIV = ""
incFILE = ""
EOF

si -batch -command netlist -cdslib $cdslib
