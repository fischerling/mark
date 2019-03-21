# Copyright (c) 2017-2019 Florian Fischer. All rights reserved.
# Use of this source code is governed by a MIT license found in the LICENSE file.

function mark_find_store --argument store
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
	mark_new_year_block (date +%Y) > $xdg_data_home/mark/marks
	echo $xdg_data_home/mark/marks
end

function mark_new_year_block --argument year
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

function mark_years_in_store
	grep -o "....:" (mark_find_store) | sed "s/.//5"
end

function mark_print_year --argument year
	grep --color=never -A12 $year (mark_find_store)
end

function mark_print_month --argument year month
	mark_print_year $year | sed -n (math $month +1)"p"
end

function mark_print_date --argument date
	set date (string split "-" $date)
	mark_print_month $date[1] $date[2] | cut -d' ' -f(math $date[3] + 1)
end

function mark_print_dates --argument date before after
	if test -n "$before" -a "$before" -gt 0
		for b in (seq 1 $before | tac)
			set cur_date (date -I -d "$date - $b days")
			mark_print_date $cur_date
		end
	end

	mark_print_date $date

	if test -n "$after" -a "$after" -gt 0
		for a in (seq 1 $after)
			set cur_date (date -I -d "$date + $a days")
			mark_print_date $cur_date
		end
	end
end

function mark_append_mark --argument mark date
	set date_a (string split "-" $date)
	set year $date_a[1]
	set month $date_a[2]
	set day $date_a[3]

	for y in (mark_years_in_store)
		if test "$y" != $year
			mark_print_year $y
		else
			# set first mark
			if test (mark_print_date $date) = "?"
				mark_print_year $year | sed (math $month + 1)"s/ [^[:space:]]*/ $mark/"$day
			# append to marks
			else
				mark_print_year $year | sed (math $month + 1)"s/ [^[:space:]]*/&$mark/"$day
			end
		end
		echo
	end
end

function mark --argument cmd date
	if test -z "$cmd"
		echo "No cmd specified"
		echo "Usage:	mark [cmd | <mark>] date [cmd args]"
		echo "Cmds:"
		echo "	print [before] [after]: print marks in range [date-before, date-after]"
		return 1
	end

	if test -n "$argv[2]"
		if not date -d "$argv[2]" > /dev/null 2>&1
			echo $argv[2] " is not a valid date" >&2
		end
		set date "$argv[2]"
	else
		set date (date -I)
	end

	switch "$cmd"
		case "print"
			mark_print_dates $date $argv[3] $argv[4]
		case "*"
			set store (mark_find_store)

			cp $store $store.bak

			mark_append_mark $cmd $date > $store.new

			mv $store.new $store
	end
end
