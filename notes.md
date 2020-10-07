/**
        TODO:

        -ILK-
        line   x 
        dust   x
        duty   x 
        chop   x
        dunk   x
        mat    x
        beg    x
        ttl    x
        tau    x

        -SYS-
        pot_dsr;     x
        vat_Line;    x
        pause_delay; REVISIT 04/24/2020
        vow_wait;    x
        vow_bump;    x
        vow_sump;    x
        vow_dump;    x
        vow_hump;    x
        cat_box;
        ilk_count;
     */


    // TODO increaseIlkLine
    // TODO decreaseIlkLine
    // TODO set vault dust (ilk, dust [RAD])
    // TODO set minimum vault (ilk, hump [RAD])
    // TODO set auction size (ilk, lump [WAD])
    // TODO spot liquidation ratio (ilk, mat [RAY])
    // TODO poke(spot, ilk)
    // TODO cage
    
    // TODO Freeze oracles
    // TODO Drop plotted plans
    // TODO trigger ES?



    FILE functions

    cat
        vow
        box         x
        ilk - chop  x
        ilk - dunk  x
        ilk - flip
    end
        vat
        cat
        vow
        pot
        spot
        wait
    flap
        beg   x
        ttl   x
        tau   x
    flip
        beg   x
        ttl   x
        tau   x
        cat
    flop
        beg   x
        pad   x
        ttl   x
        tau   x
    jug
        duty  x
        base
        vow
    pot
        dsr   x
        vow
    spot
        pip
        par
        ilk - mat   x
    vat
        Line        x
        ilk - spot
        ilk - line  x
        ilk - dust  x
    vow
        wait     x
        bump     x
        sump     x
        dump     x
        hump     x
        flapper
        flooper


                
