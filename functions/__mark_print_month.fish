function __mark_print_month --description "print overview over a month"

    # defaults
    # use current year and month
    set mark_store $__mark_store
    # convert "0m" to "m" if m < 10
    set month (math (date "+%m") "*1")
    set year (date "+%Y")

    # parse argv
    for i in (seq 1 (count $argv))
        if string match -q -- "-y=*" "$argv[$i]"
            set year (string replace -- "-y=" "" $argv[$i])
        else if string match -q -- "-m=*" "$argv[$i]"
            set month (string replace -- "-m=" "" $argv[$i])
        else if string match -q -- "-s=*" "$argv[$i]"
            set mark_store (string replace -- "-s=" "" "$argv[$i]")
        else
            echo unrecognised option: $argv[$i] >&2
            return 1
        end
    end

    if not test -f $mark_store
        return 1
    end

    # get marks
    set marks (string split " " (__mark_print_block "store" $mark_store))
    set marks (string split ":" $marks[(math $month + 1)])[2]
    set marks (string split "" $marks)

    # get colors
    set colors (__mark_print_block "colors" $mark_store)

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
