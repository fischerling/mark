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
