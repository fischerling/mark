function __mark_get --description 'extract information from a mark_store'
    # defaults
    set mark_store $__mark_store
    set year (date "+%Y")
    set month (math (date "+%m") "*1")
    set day (math (date "+%d") "*1")
    # range of marks retunrned around date
    set range 0

    # parse argv
    for i in (seq 1 (count $argv))
        if string match -q -- "-y=*" "$argv[$i]"
            set year (string replace -- "-y=" "" $argv[$i])
        else if string match -q -- "-m=*" "$argv[$i]"
            set month (string replace -- "-m=" "" $argv[$i])
        else if string match -q -- "-d=*" "$argv[$i]"
            set day (string replace -- "-d=" "" $argv[$i])
        else if string match -q -- "-s=*" "$argv[$i]"
            set mark_store (string replace -- "-s=" "" "$argv[$i]")
        else if string match -q -- "-r=*" "$argv[$i]"
            set range (string replace -- "-r=" "" "$argv[$i]")
        else
            echo unrecognised option:  $argv[$i] >&2
            return 1
        end
    end

    if not test -f $mark_store
        return 1
    end

    set marks (__mark_print_block store $mark_store)
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
            set first_year_offset (math "$year_offset + 12*$year_diff")

            if test $first_year_offset -gt (count marks)
                echo range is to big for available data! >&2
                return 1
            end

            # collect relevant marks
            # $s = oldest month to add
            set s $start_d[2]
            set e 12
            for y in (seq $first_year_offset -12 $year_offset)
                # set e if last year is reached
                if test $y -eq $year_offset
                    set e $month
                end
                for i in (seq $s $e)
                    set range_marks $range_marks (string split ":" $marks[(math $y + $i)])[2]
                end
                # reset s -> start with january
                set s 0
            end

            set marks (string split "" $range_marks[1])

            if test (count $range_marks) -gt 1
                set marks $marks[$start_d[3]..-1]
                for i in (seq 2 (math (count $range_marks) - 1))
                    set marks $marks (string split "" $range_marks[$i])
                end
                set tmp_marks (string split "" $range_marks[-1])
                set marks $marks $tmp_marks[1..$day]
            else
                set marks $marks[$start_d[3]..$day]
            end
            echo (string join "" $marks)
        else
            set marks (string split "" (string split ":" $marks[(math $month+$year_offset)])[2])
            echo $marks[$day]
        end
    end
end
