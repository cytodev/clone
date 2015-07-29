#!/bin/bash
if [ "$(id -u)" != "0" ]; then
	echo "This script must be run as root" 1>&2;
	exit 1;
fi

WIDTH=$(tput cols);
MAXWIDTH=$[WIDTH-10];
PROGRAMNAME="clone";




#-----------------------------------------------------------------------------#
#                                confirm  exit                                #
#-----------------------------------------------------------------------------#

hasDepends() {
	if [ -z $(which pv) ]; then
		echo "You need pv to run this script.";
		exit;
	fi
	if [ -z $(which dialog) ]; then
		echo "You need dialog to run this script.";
		exit;
	fi
}




#-----------------------------------------------------------------------------#
#                                confirm  exit                                #
#-----------------------------------------------------------------------------#

confirmExit() {
	dialog --title "Exit program" --yesno "Are you sure you want to exit $PROGRAMNAME?" 10 $MAXWIDTH;
	ret=$?;

	if [ $ret -eq 0 ]; then
		reset;
		echo "$PROGRAMNAME terminated";
		exit;
	fi
}




#-----------------------------------------------------------------------------#
#                               confirm  action                               #
#-----------------------------------------------------------------------------#

confirmAction() {
	dialog --title "Check your input" --yesno "Is this input correct?\nERRORS MAY CAUSE SYSTEM FAILURE\n\nInput file/block: $INF\nOutput file/block: $OUF\nBlock size: $BLS" 20 $MAXWIDTH;
	ret=$?;

	if [ $ret -eq 1 ]; then
		main;
	else
		start;
	fi
}




#-----------------------------------------------------------------------------#
#                           query for inputlocation                           #
#-----------------------------------------------------------------------------#

queryInput() {
	INPUT="/tmp/queryIntput.txt";
	>$INPUT;
	trap "rm $INPUT; exit" SIGHUP SIGINT SIGTERM;
	dialog --title "Input file or block" --inputbox "Please type the full path to the input file or block to copy" 10 $MAXWIDTH 2>$INPUT;
	ret=$?;

	case $ret in
		0) INF=$(<$INPUT);;
		*) confirmExit;;
	esac

	rm $INPUT;
}




#-----------------------------------------------------------------------------#
#                          query for  outputlocation                          #
#-----------------------------------------------------------------------------#

queryOutput() {
	OUTPUT="/tmp/queryOutput.txt";
	>$OUTPUT;
	trap "rm $OUTPUT; exit" SIGHUP SIGINT SIGTERM;
	dialog --title "Output file or block" --inputbox "Please type the full path to the output file or block to copy to" 10 $MAXWIDTH 2>$OUTPUT;
	ret=$?;

	case $ret in
		0) OUF=$(<$OUTPUT);;
		*) confirmExit;;
	esac

	rm $OUTPUT;
}




#-----------------------------------------------------------------------------#
#                             query for blocksize                             #
#-----------------------------------------------------------------------------#

queryBlockSize() {
	BLOCK="/tmp/queryBlocks.txt";
	>$BLOCK;
	trap "rm $BLOCK; exit" SIGHUP SIGINT SIGTERM;
	dialog --title "Blocksize" --inputbox "Please designate the block size to be used" 10 $MAXWIDTH 2>$BLOCK;
	ret=$?;

	case $ret in
		0) BLS=$(<$BLOCK);;
		*) confirmExit;;
	esac

	rm $BLOCK;
}




#-----------------------------------------------------------------------------#
#                            actual  functionality                            #
#-----------------------------------------------------------------------------#

start() {
	(pv -n $INF | dd of=OUF bs=$BLS conv=notrunc,noerror) 2>&1 | dialog --title "Cloning..." --gauge "Cloning $INF to $OUF, please wait...\n\nIMPORTANT! DO NOT EXIT THIS PROGRAM WHILE IT IS RUNNING. DOING SO CAN CAUSE SEVERE DRIVE FAILURE" 10 $MAXWIDTH 0;
	dialog --title "Cloning finished" --msgbox "$INF was written over $OUF with a block size of $BLS.\n\nIt is now safe to exit." 10 $MAXWIDTH;
	reset;
}




#-----------------------------------------------------------------------------#
#                                  main loop                                  #
#-----------------------------------------------------------------------------#

main() {
	hasDepends;

	INF='';
	OUF='';
	BLS='';

	while [ -z "$INF" ]; do
		queryInput;
	done
	while [ -z "$OUF" ]; do
		queryOutput;
	done
	while [ -z "$BLS" ]; do
		queryBlockSize;
	done

	confirmAction;
}




#-----------------------------------------------------------------------------#
# now  we just need to call main,  because I like to keep shit organised  and #
# such...  You know...  C and Java have a main function that gets called... I #
# wonder how they came up with that name. Why not call it "0" or "first"? Ah, #
# well,  I think it's an assembly thing...  Which I would also want to  learn #
# some time soon.                                                             #
#                                                                             #
# Thanks for reading all the source code by the way. Any tips? You know where #
# to find me. :)                                                              #
#-----------------------------------------------------------------------------#

main
