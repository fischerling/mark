# Copyright (c) 2017-2019 Florian Fischer. All rights reserved.
# Use of this source code is governed by a MIT license found in the LICENSE file.

function __mark_print_block -d "prints block from mark_store" -a block file
    set c (string match -r "#$block#[^#]*" (echo (cat $file)))
    set c (string replace "#$block#" "" $c)
    echo (string trim $c)
end

function __mark_get --description 'extract information from a mark_store' \
                    -a store year month day range

    set marks (__mark_print_block store $store)
    set marks (string split " " $marks)

    # find year in marks
    for i in (seq 1 (count $marks))
        if string match -q -r "^$year:\$" $marks[$i]
            set year_offset $i
            break
        end
    end

    # return if year not in the data
    if not set -q  year_offset
        echo year $year not found in the store >&2
        return 1
    end

    if test $day -eq 0
        # collect all marks in month
        set marks_list
        for m in (string split "" (string split ':' $marks[(math $month+$year_offset)])[2])
            # check if $m is a mark
            if test $m != '?'
                set incremented false
                # check if a count for $m is already stored in $marks_list
                for e in $marks_list
                    if test $e = mark_$m
                        set incremented true
                        # build count variable name
                        set cur mark_$m
                        # increment mark count
                        set $cur (math $$cur + 1)
                    end
                end
                # add count for $m if it was not in $marks_list
                if test $incremented = false
                    set mark_$m 1
                    set marks_list $marks_list mark_$m
                end
            end
        end
        # print result
        echo (count $marks_list) different marks found:
        for e in $marks_list
            echo (string split '_' $e)[2]:$$e
        end
    else
        # get range
        if test $range -ne 0
            set range (math $range - 1)
            set start_s (date -d "$year-$month-$day - $range days" +%s)
            set start_d (string split "-" (date -d @$start_s +%Y-%m-%d))

            set year_diff (math $year - $start_d[1])
            set first_year_offset (math "$year_offset - 13*$year_diff")

            if test $first_year_offset -le 0
                echo range is to big for available data! >&2
                return 1
            end

            # collect relevant marks
            # $s = oldest month to add
            set s $start_d[2]
            set e 12
            for y in (seq $first_year_offset +13 $year_offset)
                # set e if last year is reached
                if test $y -eq $year_offset
                    set e $month
                end
                for i in (seq $s $e)
                    set line_marks (string split ":" $marks[(math $y + $i)])[2]
                    # ignore empty lines (years <yyyy>:\n)
                    if not test "" = $line_marks
                        set range_marks $range_marks $line_marks
                    end
                end
                # reset s -> start with january
                set s 0
            end

            set marks (string split "" $range_marks)

            set marks $marks[(math $start_d[3])..(math $start_d[3] + $range)]

            echo (string join "" $marks)
        else
            set marks (string split "" (string split ":" $marks[(math $month+$year_offset)])[2])
            echo $marks[$day]
        end
    end
end

function __mark_new_store --description "generates new mark store for one year"
    set year (date "+%Y")
    echo "#colors#"
    echo "#store#"
    echo $year:
    for m in (seq 1 12)
        echo -n "$m:"
        switch $m
            case 1 3 5 7 8 10 12
                set days 31
            case 4 6 9 11
                set days 30
            case 2
                if date -d "$year-02-29" >/dev/null ^/dev/null
                    set days 29
                else
                    set days 28
                end
        end

        for d in (seq 1 $days)
            echo -n "?"
        end
        echo
    end
    echo "#end#"
end

function __mark_print_month --description "print overview over a month" \
                            -a store year month

    # get marks
    set marks (string split " " (__mark_print_block "store" $store))
    set marks (string split ":" $marks[(math $month + 1)])[2]
    set marks (string split "" $marks)

    # get colors
    set colors (__mark_print_block "colors" $store)

    # get formatted representation for month
    set month (cal $month $year)
    # strip of headline
    set month $month[2..-1]
    # day count
    set day 1
    for l in $month
        set chars (string split "" $l)
        set cursor 1
        # used if day is double-digit
        set cursor_n $cursor
        while test $cursor -le (count $chars)
            if string match -q -r "[0-9]" $chars[$cursor]
                if test (string length $day) -eq 2
                    set cursor_n (math $cursor + 1)
                end
                if test $marks[$day] != "?"
                    # find color
                    if set col (string match -r "$marks[$day]:[^\ ]*" $colors)
                        set col (string split ":" $col)[2]
                        set_color $col
                    else
                        # default to yellow
                        set_color yellow
                    end

                    echo -n (string join "" $chars[$cursor..$cursor_n])
                    set_color normal
                else
                    echo -n (string join "" $chars[$cursor..$cursor_n])
                end
                test $cursor_n -ne $cursor; and set cursor (math $cursor + 1)
                set day (math $day + 1)
            else
                echo -n $chars[$cursor]
            end
            set cursor (math $cursor + 1)
            set cursor_n $cursor
        end
        echo
    end
end

function __mark_set --description 'mark a day in a store' \
                    -a store year month day sign force

    # calculate offset: $day+1 (+1 if m > 9) because of "<month>:"
    set offset (math "floor($day + 1 + $month/10)") 

    set marks (__mark_print_block store $store)
    set marks (string split " " $marks)

    # copy everything before #store#
    string split " " (string match -r "^.*#store#" (echo (cat $store))) > $store.new

    # crawl store
    set m 0
    # correct year sub-block
    set is_year false
    for l in $marks
        if begin test $is_year = false
                 and string match -q -r "^$year:\$" $l
                 end
            set is_year true
        end

        if test $is_year = true
            if test $m -ne $month
                echo $l >> $store.new
            else
                # replace the char at offset with $sign
                if test $force = true
                    echo $l | sed "s/^\(.\{$offset\}\)./\1$sign/" >> $store.new
                else
                    echo $l | sed "s/^\(.\{$offset\}\)?/\1$sign/" >> $store.new
                end
            end

            set m (math "$m+1")
            # not in year sub-block any more
            if test $m -eq 13
                set is_year false
            end
        else
            echo $l >> $store.new
        end
    end
    
    #copy everything after #store#
    set store_and_rest (string match -r "#store#.*\$" (echo (cat $store)))
    string split " " (string replace -r "#store#[^#]*" "" $store_and_rest) >> $store.new

    mv $store.new $store
end

function mark
    # defaults
    set store $__mark_store
    set year (date "+%Y")
    set month (math (date "+%m") "*1")
    set day (math (date "+%d") "*1")
    # range of marks returned around date
    set range 0
    # sign to write to the store
    set sign !
    set force false

    for i in (seq 2 (count $argv))
        if string match -q -- "-d=*" "$argv[$i]"
            set day (string replace -- "-d=" "" $argv[$i])
        else if string match -q -- "-m=*" "$argv[$i]"
            set month (string replace -- "-m=" "" $argv[$i])
        else if string match -q -- "-y=*" "$argv[$i]"
            set year (string replace -- "-y=" "" $argv[$i])
        else if string match -q -- "-s=*" "$argv[$i]"
            set store (string replace -- "-s=" "" "$argv[$i]")
        else if string match -q -- "-z=*" "$argv[$i]"
            set sign (string replace -- "-z=" "" "$argv[$i]")
        else if string match -q -- "-r=*" "$argv[$i]"
            set range (string replace -- "-r=" ""  "$argv[$i]")
        else if string match -q -- "-f" "$argv[$i]"
            set force true
        else 
            echo unrecognised option: $argv[$i] >&2
            return 1
        end
    end

    if not test -f $store
        echo "store is not a file" >&2
        return 1
    end

    switch $argv[1]
        case "set" "s"
            __mark_set $store $year $month $day $sign $force
        case "get" "g"
            __mark_get $store $year $month $day $range
        case "month" "m"
            __mark_print_month $store $year $month
    end
end
