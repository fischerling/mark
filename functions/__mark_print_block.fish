function __mark_print_block -d "prints block from mark_store" -a block file
    set c (string match -r "#$block#[^#]*" (echo (cat $file)))
    set c (string replace "#$block#" "" $c)
    echo (string trim $c)
end
