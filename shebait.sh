#!/bin/bash

if [ "$1" = "-h" -o "$1" = "--help" ]; then
	cat <<-END
	shebait.sh -- SHell BAsed Integration Testing
	
	Run all tests in the directory 'tests'. Their exit code indicates success
	(0), test failure (1) or other errors (>1).
	
	Only files whose names do *not* contain a dot '.' are executed. This allows
	you to disable tests by giving them a file name suffix or to store helper
	functions in .sh files.
	
	During the tests the currently running test name is displayed. The test name
	is the name of the executable, with leading digits removed and underscores
	replaced by whitespace.
	
	In the end a short summary statistic is displayed.
	
	Tests results with details and command outputs are stored in
	'results/test-results.xml' in JUnit's XML format.
	END
	exit 0
fi

RESULT_FILE=results/test-results.xml

# Get a failure message from the captured standard error file or standard
# output file
get_failure_message() {
	if [ -s "$1" ]; then
		tail -1 "$1"
	else
		tail -1 "$2"
	fi
}

# Get the test name from its file name: Strip leading digits and replace
# underscores with whitespace
get_test_name() {
	basename "$1" | sed 's/^[0-9]*_*//; s/_/ /g'
}

xml_result() {
	case "$1" in
	testcase)
		echo "    <testcase name=\"$2\">" >> $RESULT_FILE.tmp
		;;
	failure)
		echo "        <failure>$2</failure>" >> $RESULT_FILE.tmp
		;;
	error)
		echo "        <error>$2</error>" >> $RESULT_FILE.tmp
		;;
	output)
		echo -n "        <system-out><![CDATA[" >> $RESULT_FILE.tmp
		cat "$2" >> $RESULT_FILE.tmp
		echo "]]></system-out>" >> $RESULT_FILE.tmp
		echo -n "        <system-err><![CDATA[" >> $RESULT_FILE.tmp
		cat "$3" >> $RESULT_FILE.tmp
		echo "]]></system-err>" >> $RESULT_FILE.tmp
		;;
	endcase)
		echo "    </testcase>" >> $RESULT_FILE.tmp
		;;
	end)
		echo "</testsuite>" >> $RESULT_FILE.tmp
		;;
	*)
		echo "Invalid argument: $@"
		exit 2
	esac
}

# Color output if running in terminal
color_red=
color_green=
color_end=
if [ -t 1 ]; then
    color_red=$(tput setaf 1)
    color_green=$(tput setaf 2)
    color_end=$(tput sgr0)
fi

pass=0
fail=0
error=0

mkdir -p $(dirname $RESULT_FILE)
echo > $RESULT_FILE.tmp

# ! Highly unportable
starttime=$(date +%s%N)

# Run all files which do *not* contain dots. The rationale is that you can
# disable tests by giving them a suffix, and that you can put common helper
# functions in .sh files.
shopt -s extglob
for each in tests/!(*.*); do
	name=$(get_test_name "$each")
	echo -n "[    ] $name"
	stdout=$(mktemp)
	stderr=$(mktemp)
	msg=""
	# Actually run the test
	"$each" > "$stdout" 2> "$stderr"
	result=$?
	xml_result testcase "$name"
	if [ $result -eq 0 ]; then
		let pass++
		echo -e "\r[${color_green}PASS${color_end}]"
	elif [ $result -eq 1 ]; then
		let fail++
		echo -e "\r[${color_red}FAIL${color_end}]"
		msg=$(get_failure_message "$stderr" "$stdout")
		xml_result failure "$msg"
	else
		let error++
		echo -e "\r[${color_red}ERR ${color_end}]"
		msg=$(get_failure_message "$stderr" "$stdout")
		xml_result error "$msg"
	fi
	xml_result output "$stdout" "$stderr"
	xml_result endcase
	rm -f "$stdout"
	rm -f "$stderr"
done
xml_result end

endtime=$(date +%s%N)
elapsed=$(( ( $endtime - $starttime ) / 1000000 ))
total=$(( $pass + $fail + $error ))

cat - $RESULT_FILE.tmp > $RESULT_FILE <<-EOF
	<?xml version="1.0" encoding="UTF-8"?>
	<testsuite tests="$total" failures="$fail" errors="$error"
	        timestamp="$(date -u -Iseconds)" hostname="$HOSTNAME">
	EOF
rm -f $RESULT_FILE.tmp

echo
echo "Summary: $pass of $total tests passed in ${elapsed}ms, $fail failed, $error error(s)"
