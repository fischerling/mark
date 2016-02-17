function __mark_set --description 'mark a day in a store'
    # defaults
    set mark_store $__mark_store
    set sign "*"
    set day (math (date +"%d") "*1")
    set month (math (date +"%m") "*1")
    set year (date +"%Y")

    # parse argv
    for i in (seq 1 (count $argv))
        if string match -q -- "-d=*" "$argv[$i]"
            set day (string replace -- "-d=" "" $argv[$i])
        else if string match -q -- "-m=*" "$argv[$i]"
            set month (string replace -- "-m=" "" $argv[$i])
        else if string match -q -- "-y=*" "$argv[$i]"
            set year (string replace -- "-y=" "" $argv[$i])
        else if string match -q -- "-s=*" "$argv[$i]"
            set mark_store (string replace -- "-s=" "" "$argv[$i]")
        else if string match -q -- "-z=*" "$argv[$i]"
            set sign (string replace -- "-z=" "" "$argv[$i]")
        else
            echo unrecognised option: $argv[$i] >&2
            return 1
        end
    end

    if not test -f $mark_store
        return 1
    end

    # calculate offset: $day+1 (+1 if m > 9) because of "<month>:"
    set offset (math "($day + 1 + $month/10)") 

    set marks (__mark_print_block store $mark_store)
    set marks (string split " " $marks)

    # copy everything before #store#
    string split " " (string match -r "^.*#store#" (echo (cat $mark_store))) > $mark_store.new

    # crawl store
    set m 0
    # correct year sub-block
    set is_year false
    for l in $marks
        if begin test $is_year= false
                 and string match -q -r "^$year:\$" $l
                 end
            set year_found true
        end

        if test $is_year= true
            if test $m -ne $month
                echo $l >> $mark_store.new
            else
                # replace the char at offset with $sign
                echo $l | sed "s/^\(.\{$offset\}\)?/\1$sign/" >> $mark_store.new
            end

            set m (math "$m+1")
            # not in year sub-block any more
            if test $m -eq 13
                set is_year false
            end
        else
            echo $l >> $mark_store.new
        end
    end
    
    #copy everything after #store#
    set store_and_rest (string match -r "#store#.*\$" (echo (cat $mark_store)))
    string split " " (string replace -r "#store#[^#]*" "" $store_and_rest) >> $mark_store.new

    mv $mark_store.new $mark_store
end
