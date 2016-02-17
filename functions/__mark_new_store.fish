function __mark_new_store --description "generates new mark store for one year"
    echo "#colors#"
    echo "#store#"
    echo (date "+%Y"):
    for m in (seq 1 12)
        echo -n "$m:"
        for d in (seq 1 31)
            echo -n "?"
        end
        echo
    end
    echo "#end#"
end
