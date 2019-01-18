// Useful globals for everybody!

  // Options for -twoway- graphs
  global tw_opts ///
  	title(, justification(left) color(black) span pos(11)) ///
  	graphregion(color(white) lc(white) lw(med)) bgcolor(white) ///
  	ylab(,angle(0) nogrid) xtit(,placement(left) justification(left)) ///
  	yscale(noline) xscale(noline) legend(region(lc(none) fc(none)))

  // Options for -graph- graphs
  global graph_opts ///
  	title(, justification(left) color(black) span pos(11)) ///
  	graphregion(color(white) lc(white) lw(med)) bgcolor(white) ///
  	ylab(,angle(0) nogrid) ytit(,placement(left) justification(left))  ///
  	yscale(noline) legend(region(lc(none) fc(none)))

  // Options for histograms
  global hist_opts ///
  	ylab(, angle(0) axis(2)) yscale(off alt axis(2)) ///
  	ytit(, axis(2)) ytit(, axis(1))  yscale(alt)

  // Useful stuff

  global pct `" 0 "0%" .25 "25%" .5 "50%" .75 "75%" 1 "100%" "'
  global numbering `""(1)" "(2)" "(3)" "(4)" "(5)" "(6)" "(7)" "(8)" "(9)" "(10)""'
  global bar lc(white) lw(thin) la(center) fi(100) // ← Remove la(center) for Stata < 15

// Analysis for paper

  global dir "/Users/bbdaniels/GitHub/jclintb2019"

  // Figure 1: Testing
  use "${dir}/constructed/classic.dta" , clear
    replace lab_cxr = 1 if study == "Delhi"

    graph hbar lab_cxr lab_afb lab_gx ///
      , over(facility_type) over(study) nofill ///
        ${graph_opts} ylab(${pct}) ysize(4.5) ///
        bar(1 , ${bar})  bar(2 , ${bar})  bar(3 , ${bar})

  // Figure 2: Diversity in Medication Use (Quinolones/Antibiotic/Steroid/Unlabelled Use)
  use "${dir}/constructed/classic.dta" , clear

    foreach var in med_st med_qu med_an med_un {
      replace `var' = 0 if `var' == .
      local l : var label `var'
      gen `var'l = "`l'" if `var' == 1
    }

    contract study facility_type med_stl med_qul med_anl med_unl
      gen x = study + " " + facility_type
      gen y = itrim(trim(med_anl + " " + med_qul + " " + med_stl + " " + med_unl))
        replace y = " None" if y == ""
        replace y = subinstr(y," "," + ",.) if y != " None"
        egen check = noccur(y) , string(+)
        replace y = " "*(3-check) + y
      encode x , gen(x2)
      encode y , gen(y2)

    levelsof y2 , local(levels)
    foreach mix in `levels' {
      local lab : lab (y2) `mix'
      local ylab `"`ylab' `mix' "`lab'"  "'
    }

    levelsof x2 , local(levels)
    foreach place in `levels' {
      local plots = "`plots' (scatter y2 x2 if x2 == `place' [pweight = _freq] , m(i) mc(black) ml(_freq) mlabp(0))"
      local lab : lab (x2) `place'
      local xlab `"`xlab' `place' "`lab'"  "'
    }

    tw `plots' , ${graph_opts} ///
      ylab(`ylab' , notick) xlab(`xlab',angle(90)) ///
      legend(off) yscale(reverse) xtit(" ") ytit(" ")

  // Figure 3: Checklist Range
  use "${dir}/constructed/classic.dta" , clear

    graph hbox checklist ///
      , over(facility_type, axis(noline)) over(study) nofill noout ///
        ${graph_opts} ylab(${pct}) ysize(4.5) ///
        bar(1 , lc(black) lw(thin) la(center) fi(0) ) ///
        note(" ") ytit("History Checklist Completion {&rarr}")

  // Figure 4: Changes by case (Qutub)

    // Figure 4.1: Testing
    use "${dir}/constructed/qutub.dta" , clear

      collapse (mean) lab_any (sebinomial) se=lab_any  , by(case_code facility_type study)
        gen ul = lab_any + 1.96 * se
        gen ll = lab_any - 1.96 * se
      gen check = study + " " + facility_type + " "
      sort check case_code

      tw  ///
        (line lab_any case_code , connect(ascending) lc(black) lw(thin)) ///
        (rspike ul ll case_code , connect(ascending) lc(black) lw(thin)) ///
        (scatter lab_any case_code , mlc(black) mlw(med) mfc(white) msize(large)) ///
        (scatter lab_any case_code if case_code == 1 , m(none) mlab(check) mlabc(black) mlabpos(9)) ///
      , ${tw_opts} xtit(" ") xlab(0 "SP:" 1 `" "Classic" "Case" "' 2 `" "Showed" "X-Ray" "' 3 `" "Showed" "Sputum" "' 4 `" "MDR" "Case" "' , notick) ///
        ylab(1 "100%" 0 "0%"  , notick) yline(0 1 , lc(black)) ytit(" ") legend(off) title("TB Laboratory Testing")

        graph save "${dir}/temp/f-4-1.gph" , replace

    // Figure 4.2: Steroids & Quinolones
    use "${dir}/constructed/qutub.dta" , clear

      collapse (mean) med_st med_qu  , by(case_code facility_type study)
        // gen ul = med_any + 1.96 * se
        // gen ll = med_any - 1.96 * se
      gen check = study + " " + facility_type + " "
      sort check case_code

      tw  ///
        (line med_st case_code , connect(ascending) lc(black) lw(thin)) ///
        (line med_qu case_code , connect(ascending) lc(black) lw(thin)) ///
        (scatter med_st case_code , mlc(black) mlw(med) mfc(black) msize(large)) ///
        (scatter med_qu case_code , mlc(black) mlw(med) mfc(white) msize(large)) ///
        (scatter med_st case_code if case_code == 1 , m(none) mlab(check) mlabc(black) mlabpos(9)) ///
        (scatter med_qu case_code if case_code == 1 , m(none) mlab(check) mlabc(black) mlabpos(9)) ///
      , ${tw_opts} xtit(" ") xlab(0 "SP:" 1 `" "Classic" "Case" "' 2 `" "Showed" "X-Ray" "' 3 `" "Showed" "Sputum" "' 4 `" "MDR" "Case" "' , notick) ///
        ylab(.50 "50%" 0 "0%" , notick) yline(0 .5 , lc(black)) ytit(" ") legend(order(3 "Steroids" 4 "Quinolones") ring(0) pos(12)) title("Contraindicated Medication")

        graph save "${dir}/temp/f-4-2.gph" , replace

    // Combine
    graph combine ///
      "${dir}/temp/f-4-1.gph" ///
      "${dir}/temp/f-4-2.gph" ///
    , ${comb_opts} r(1)

  // Figure 5: SP Fixed Effects // TODO: Height, weight, etc effects?

  use "${dir}/constructed/sp_id.dta" , clear

    reg correct sp_age sp_height sp_weight sp_bmi sp_male i.city i.facility_type i.case , cl(sp_id)
    coefplot , ${graph_opts} drop(_cons) xline(0 , lp(dash) lc(gray)) m(+) mc(black) ciopts(lc(black)) 	ylab(,notick) title("By Characteristics")
      graph save "${dir}/temp/f-5-1.gph" , replace

    reg correct i.sp_id i.case i.city i.facility_type , coefl
    coefplot , ${graph_opts} keep(*.sp_id) xline(0 , lp(dash) lc(gray)) m(+) mc(black) ciopts(lc(black)) 	ylab(,notick) title("By Individual SP")
      graph save "${dir}/temp/f-5-2.gph" , replace

    graph combine ///
      "${dir}/temp/f-5-1.gph" ///
      "${dir}/temp/f-5-2.gph" ///
    , ${comb_opts} r(1)

// Have a lovely day!