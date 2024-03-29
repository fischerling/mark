# Copyright (c) 2017-2022 Florian Fischer. All rights reserved.
# Use of this source code is governed by a MIT license found in the LICENSE file.

function __mark_find_store --argument store
	if test -n "$store" -a -f "$store"
		echo $store
		return
	end

	if set -q MARK_STORE
		echo $MARK_STORE
		return
	end

	for dir in $XDG_DATA_DIRS
		if test -f $dir/mark/marks
			echo $dir/mark/marks
			return
		end
	end

	set xdg_data_home $XDG_DATA_HOME
	if test -z $xdg_data_home
		set xdg_data_home ~/.local/share
	end
	if test -f $xdg_data_home/mark/marks
		echo $xdg_data_home/mark/marks
		return
	end

	if test -f ~/.marks
		echo ~/.marks
		return
	end

	echo "Creating new mark file at $xdg_data_home/mark/marks" >&2
	mkdir -p $xdg_data_home/mark
	__mark_new_year_block (date +%Y) > $xdg_data_home/mark/marks
	echo $xdg_data_home/mark/marks
end

function __mark_parse_date --argument date
	if test -n "$date"
		if not date -d "$date" > /dev/null 2>&1
			echo "$date is not a valid date" >&2
			return 1
		end
		echo (date -I -d $date)
	else
		echo (date -I)
	end
end

function __mark_new_year_block --argument year
	echo "$year":
	echo "01: ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ?"
	echo "02: ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ?"
	echo "03: ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ?"
	echo "04: ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ?"
	echo "05: ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ?"
	echo "06: ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ?"
	echo "07: ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ?"
	echo "08: ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ?"
	echo "09: ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ?"
	echo "10: ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ?"
	echo "11: ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ?"
	echo "12: ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ?"
end

function __mark_years_in_store
	grep -o "....:" (__mark_find_store) | sed "s/.//5"
end

function __mark_print_year --argument year
	grep --color=never -A12 $year (__mark_find_store)
end

function __mark_print_month --argument year month
	__mark_print_year $year | sed -n (math $month +1)"p"
end

function __mark_print_date --argument date
	set date (string split "-" $date)
	__mark_print_month $date[1] $date[2] | cut -d' ' -f(math $date[3] + 1)
end

function __mark_print_dates --argument date before after
	if not set date (__mark_parse_date $date)
		return 1
	end

	if test -n "$before" -a "$before" -gt 0
		for b in (seq 1 $before | tac)
			set cur_date (date -I -d "$date - $b days")
			__mark_print_date $cur_date
		end
	end

	__mark_print_date $date

	if test -n "$after" -a "$after" -gt 0
		for a in (seq 1 $after)
			set cur_date (date -I -d "$date + $a days")
			__mark_print_date $cur_date
		end
	end
end

function __mark_append_mark --argument mark date
	set date_a (string split "-" $date)
	set year $date_a[1]
	set month $date_a[2]
	set day $date_a[3]

	for y in (__mark_years_in_store)
		if test "$y" != $year
			__mark_print_year $y
		else
			# set first mark
			if test (__mark_print_date $date) = "?"
				__mark_print_year $year | sed (math $month + 1)"s/ [^[:space:]]*/ $mark/"$day
			# append to marks
			else
				__mark_print_year $year | sed (math $month + 1)"s/ [^[:space:]]*/&$mark/"$day
			end
		end
		echo
	end
end

function __mark_count --argument pattern
	if test -z "$pattern"
		echo "No countable pattern provided" >&2
		return 1
	end

	grep -v '[1-9][0-9][0-9][0-9]:' (__mark_find_store) | sed -r 's/^.{3}//' | grep -Eo $pattern | wc -l
	return 0
end

function __mark_edit
	set store (__mark_find_store)
	if test ! -z "$VISUAL"
		eval $VISUAL $store
	else if test ! -z "EDITOR"
		eval $EDITOR $store
	else if type -q "xdg-open"
		xdg-open $store
	else
		echo "Don't know how to open marks." >&2
		echo "Please set VISUAL or EDITOR in your environment." >&2
		return 1
	end

	return $status
end

function __mark_print_usage
	echo "Usage:	mark [cmd | <mark>] date [cmd args]"
	echo "Cmds:"
	echo "	print [before] [after]: print marks in range [date-before, date-after]"
	echo "	edit: open the mark store file in an editor or using xdg-open"
	echo "	count <pattern>: count the occurrences of <pattern> in the mark store"
end

function mark --argument cmd
	if test -z "$cmd"
		echo "No cmd specified"
		__mark_print_usage
		return 1
	end

	switch "$cmd"
		case "print"
			__mark_print_dates $argv[2] $argv[3] $argv[4]
		case "--help" "-h"
			__mark_print_usage
		case "count"
			__mark_count $argv[2]
		case "edit" "e"
			__mark_edit
		case "*"
			set store (__mark_find_store)
			if not set date (__mark_parse_date $argv[2])
				return 1
			end

			cp $store $store.bak

			__mark_append_mark $cmd $date > $store.new

			mv $store.new $store
	end
	return $status
end
