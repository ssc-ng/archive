*! lusinfoscore.ado  version 1.0.32
*! 1.0.32: air bronchograms described as DYNAMIC (with concentric, irregular or clustered) score 15, or +10 when
*!         pneumonia/consolidation also scores; STATIC air bronchograms are no longer a pneumonia pattern and
*!         score like any other air bronchogram (5, or +5 with pneumonia). "static" was replaced by "dynamic".
*! 1.0.31: a pneumothorax that is not negated now scores 20 by default (ptxpoints() default was 0);
*!         ptxpoints(0) restores the 1.0.30 scores.
*! 1.0.30: bug fixes. (a) replace no longer drops a different variable whose name starts with the
*!         generate()/detail name (drop treated the name as an abbreviation). (b) A comma or "and" ends a
*!         negation when the next item has a quantity, size or severity word ("no pneumothorax, long
*!         b-lines in the left base" now scores the B-lines; plain lists such as "no effusion,
*!         consolidation, or pneumothorax" stay negated). (c) A normal word after "impression" makes the
*!         report normal only when it ends the statement or names the whole study (study, exam,
*!         ultrasound, lungs, windows, B-lines); "impression: normal lung sliding ... with long B-lines"
*!         and "essentially normal cardiac function" no longer force 0. (d) left/right before ventricle,
*!         atrium, heart or chamber is not laterality. (e) "considered" (e.g. "findings considered
*!         consistent with ...") is not a differential; "consider", "considerations" and "should be
*!         considered" still are. (f) Empty reports are counted in r(N_unscored).
*!         Scores on dataset_for_LUS_final.dta and Lung_information_score_validation_dataset.dta are
*!         unchanged from 1.0.29.
*! 1.0.29: "lots of b-lines" scores 10, the same as "lots of Kerley" (B-lines are scored once, as the highest
*!         tier matched, so both terms in one report do not add).
*! 1.0.28: intrascapular / infrascapular / interscapular / subscapular / scapular count as the posterior
*!         sub-zone; "lots of Kerley (lines)" scores 10 as B-lines.
*! 1.0.27: air bronchograms now ADD to pneumonia/consolidation (+5 if mentioned, +10 if described as concentric,
*!         irregular, static or clustered); without pneumonia they score as before (5 / 15).
*! 1.0.26: works with by: (byable(recall)); if and in were already supported. Scores are per report,
*!         so by only selects rows; outputs are created on the first group and filled by later groups.
*! 1.0.25: a limiting quantity word (occasional, few, scant, rare, sparse, isolated) before excess/diffuse/
*!         numerous B-lines caps the score at 1 ("occasional excess b-lines" = 1, was 10); occasional
*!         misspellings (occassional, ocasional) are recognized.
*! 1.0.24: misspelled "air bronchiograms" / "bronchigrams" are recognized as air bronchograms.
*! 1.0.23: reports with unfilled Epic template placeholders ({name:digits...}, e.g. {location:138623},
*!         {sh:125346::"presence","absence"}) get a MISSING score (option keeptemplate restores scoring).
*! 1.0.22: "medical decision making" no longer clips the whole report when it PRECEDES the lung ultrasound
*!         (only text after the impression is clipped); ED-note preamble before "lung ultrasound indication:"
*!         is dropped; "impression: normal, but <finding>" is not a normal impression.
*! 1.0.21: "indications:" (plural) field is clipped; "views:"/"procedure:" end it; "impression: negative [limited]
*!         lung ultrasound" is read as a normal impression.
*! 1.0.20: etiology/differential component capped at 15 points in total (named etiology, multiple
*!         etiologies and differential no longer add up).
*! 1.0.19: "all zones" / "all lung zones" / "all fields" (also areas, regions) in a finding clause gives full
*!         credit: all 5 sub-zones (so +15 with carpet-like or worse B-lines), 2 localization points and 3
*!         laterality. A scanning clause ("zones interrogated") does not count.
*! 1.0.18: effusion parsed per side (see the effusion block): tiny 5, small 10, moderate 15, large 20 per
*!         side, no size 10; left+right named = sum of sides; "loculated"/"non-loculated" adds 5 (loculated no
*!         longer implies a large effusion). "small right and moderate left effusions" = 10 + 15.
*! 1.0.17: pleural effusion scores per side: tiny/trace/minimal 5, small 10, moderate/large 15, no size word
*!         10; bilateral (or left and right both named with the effusion) doubles it (bilateral with no
*!         descriptor = 20). With pneumonia the larger of this and the old pneumonia tiers (5/15/20) counts.
*! 1.0.16: "bibasally"/"bibasal"/"bibasilar" also count as the base sub-zone (once, with "base"), so they
*!         earn the 2 sub-zone localization points as well as laterality.
*! 1.0.15: "bibasally"/"bibasal"/"bibasilar" count as laterality; "shred sign" counts as pneumonia (15);
*!         "bronchiolitis versus/vs/or/ pneumonitis" (either order, with or without "consistent with"/"c/w")
*!         no longer earns differential points (a differential needs an alternative outside that pair).
*! 1.0.14: atelectasis scores 5 (parenchymal tier, max with the others) and no longer earns etiology points;
*!         air bronchograms that are static, clustered, irregular or concentric score like pneumonia (15);
*!         text after "signed by" / "digitally signed" / "signed electronically" is also ignored.
*! 1.0.13: "increased B-lines" / "increased number of B-lines" score 1 (borderline) when one area; 3 when
*!         patchy / multifocal / multiple (several, scattered, numerous) areas, foci, regions or zones.
*! 1.0.12: text after "medical decision making" (ED note boilerplate such as "differential diagnoses are
*!         considered as follows") is ignored like ED course, so it no longer earns differential points.
*! 1.0.11: "absence of a consolidation consistent with pneumonia" is read as NO pneumonia: a negation
*!         (no/absence of/without ...) now runs through "consistent with"/"compatible with" unless a
*!         comma comes first (", consistent with X" stays a positive statement). Unfilled template
*!         fields ({...} choice lists, plus the next two words, and ***) are ignored. "pneumonthorax"
*!         spelling accepted.
*! 1.0.10: bronchiolitis is scored exactly like pneumonitis (own severity-scaled score: very mild 2,
*!         mild 5, mild to moderate 7, moderate 10, moderate to severe 12, severe 15; none stated =
*!         pnitispoints()), and the higher of that and the pneumonia/consolidation score is counted.
*!         Bronchiolitis no longer earns etiology points.
*! 1.0.9: asthma and reactive airway no longer count as a specified etiology (they are background
*!        conditions, not the cause of the findings).
*! 1.0.8: "upper limit of normal"/"within normal limits" now removes only the part of the
*!        sentence before the next with/and/but (v1.0.7 and earlier removed the whole sentence,
*!        e.g. dropping "minimal pleural thickening" in "upper limit of normal B-lines with
*!        minimal pleural thickening"); "upper limit of normal to slightly abnormal B-lines"
*!        scores as borderline (1); minimal/trace/tiny/slight(ly) pleural findings = very mild (1);
*!        text after "ED medication" is ignored like ED course.
*! 1.0.7: generic window names (posterior/axillary/anterior) and bilateral(ly) in a clause with
*!        "interrogated/scanned/examined" (what was scanned, not where findings were) are no
*!        longer counted as sub-zones or laterality. Specific zones (upper/mid/lower posterior,
*!        base) and left/right in the same clause are still counted.
*! 1.0.6: "small number of", "a couple of", "handful of", "several" and "scattered" before
*!        B-lines score 1 (like few/occasional), not 10 for long B-lines.
*! 1.0.5: pneumonitis points rise with the nearby severity word: very mild 2, mild 5,
*!        mild to moderate 7, moderate 10, moderate to severe 12, severe 15; no severity
*!        word = pnitispoints() (default 5).
*! 1.0.4: generic "viral" (e.g. "viral pneumonitis") no longer earns the 15 etiology points;
*!        a named cause is required (COVID, RSV, influenza, adenovirus, bacterial, aspiration,
*!        cardiogenic edema, ...). Table 1 itself says "any specified etiology".
*! 1.0.3: negation now covers up to 60 characters and stops at "impression"/"findings"/
*!        but/with/etc. Before, a negation whose clause had no stop word or punctuation
*!        within 100 characters failed entirely (v1.0.1 and earlier: "no effusion/
*!        consolidation impression:patchy viral pneumonitis reviewed and ..." left effusion
*!        and consolidation scored as present; v1.0.2 fixed that case only because of the
*!        new colon rule, not the underlying failure). "rule out"
*!        and "r/o" are treated as not-a-finding; the indication field and any text after
*!        "electronically signed" / "ED course" are ignored (option noclip turns this off).
*! 1.0.2: pneumonitis/colon/spacing fixes (see below)
*!        "pneumonitis" is milder than pneumonia: it scores pnitispoints() (default 5, the
*!        lowest parenchymal tier) and is not treated as pneumonia for effusion tiers.
*! 1.0.2: ":" now ends a clause (negation no longer runs from "no effusion" into the
*!        next "impression:" when the report has no period); whitespace collapsed;
*!        "b  lines"/"b- lines" spacing accepted;
*!        few/occasional/rare/sparse/minimal/trace B-lines score 1 (like borderline);
*!        bare "posterior" counts as a sub-zone; "mid-posterior" etc. accepted.
*! 1.0.1: "upper limit of normal", "within normal limits", WNL and "unremarkable" are
*!        now recognized as normal (impression or whole report), and such clauses are
*!        not scored as findings. 1.0.0 treated them as abnormal.
*! Point-of-care lung ultrasound (LUS) report information score (regex-assigned)
*!
*! Syntax:
*!   lusinfoscore strvar [if] [in], GENerate(newvar) [REPlace DETail PREfix(str)
*!                       NORMal(numvar) PTXpoints(#) PNITispoints(#) KEEPTemplate NOCLIP
*!                       STRIP(regex)]
*!   by is allowed. See help lusinfoscore for the full scoring rules.
*!
*! strvar        str# or strL variable holding the free-text LUS report
*! generate()    name of the new information-score variable
*! replace       overwrite generate() (and detail variables) if they exist
*! detail        also keep component scores, named <prefix>bline, <prefix>blzone,
*!               <prefix>pleura, <prefix>parench, <prefix>effusion, <prefix>ptx,
*!               <prefix>laterality, <prefix>location, <prefix>etiology,
*!               <prefix>cardiac and <prefix>normal (default prefix lus_)
*! normal()      optional numeric variable overriding the text rule for "normal":
*!               1 = normal (score forced to 0), 0 = abnormal, missing = use text rule.
*!               NOTE: do not feed this a manual severity score you later correlate
*!               with the information score; that makes the analysis circular.
*! ptxpoints()   points for a non-negated pneumothorax (default 20 from v1.0.31; Table 1 has no
*!               pneumothorax row, so ptxpoints(0) gives the 1.0.30 behavior)
*! pnitispoints() points for pneumonitis with no severity word, without consolidation/air
*!               bronchograms (default 5); with a severity word see version notes (2/5/7/10/12/15)
*! keeptemplate  do not set reports containing unfilled template placeholders to missing
*! noclip        do not remove the "indication:" field or text after "electronically signed"
*!               / "ED course" before scoring (clipping is the default)
*! strip()       ICU regular expression for non-patient-specific boilerplate (machine,
*!               probe, image-storage text) to delete before scoring
*!
*! Requires Stata 14 or later (ICU regular-expression functions).
*!
*! ----------------------------------------------------------------------------
*! Interpretation of Table 1 and corrections to the original development code
*! ----------------------------------------------------------------------------
*!  1. Normal studies score 0. "Normal" is read from the text only (impression
*!     normal / essentially normal / almost normal). The original code set
*!     normal_imp from the manual severity score (f_score), which is circular.
*!     "abnormal" elsewhere in the text no longer cancels a normal impression.
*!  2. Laterality = 3 and sub-zone localization = 2 (Table 1). The original code
*!     used 7 for laterality and never assigned sub-zone points.
*!  3. Sub-zone count adds 0/5/7/10/15 for 1/2/3/4/5+ distinct sub-zone terms, but
*!     only when B-lines are carpet-like or worse (>=5 points), as in the original
*!     code. Terms are counted once each (the original double counted).
*!  4. Severity words ("very mild", "mild", "mild to moderate", "moderate",
*!     "moderate to severe", "severe") are tokenized so that "very mild" is not
*!     scored as "mild", and are only attached to a finding in the same clause
*!     (within 60 characters). The original searched the whole report and
*!     overwrote "very mild" with "mild".
*!  5. "dome", "cupola", "pyramid" and a bare "diffuse" no longer score as B-lines.
*!     Cupola/dome belong to the parenchymal (consolidation) row as in Table 1;
*!     "dome of the diaphragm" is not a finding. "diffuse" counts only near a B-line.
*!  6. Air bronchograms and consolidation follow Table 1 (5 / 5 / 15 / 15 / 20)
*!     and take the maximum attained. Pneumonia or consolidation = 15, or 20 if
*!     multilobar, bilateral, extensive or severe; with pneumonia, air bronchograms
*!     add +5 / +10 (v1.0.27). The original code gave plain consolidation about 1
*!     point and air bronchograms 7 / 20.
*!  7. Pleural effusion is scored per side (v1.0.18): tiny 5, small 10, moderate 15,
*!     large 20, no size word 10; both sides named = sum; bilateral = twice; loculated
*!     +5. With pneumonia the larger of this and tiny 5 / small 15 / moderate-large 20.
*!     The original gave an unsized effusion 0 and added effusion points twice.
*!     Pericardial effusion is not scored as pleural effusion.
*!  8. Etiology: 15 for a named etiology, multiple etiologies or a differential,
*!     capped at 15 in total (v1.0.20). The original never added the multiple
*!     etiology or differential rows to the total.
*!  9. Negation is handled in one place (pre-negation cues such as no / without /
*!     absent / none, post-negation such as "not seen" / "absent", terminated by
*!     but / however / with / clause end, or by a comma or "and" before a quantified
*!     finding) instead of ad hoc per-finding patterns.
*!     Whole-word matching fixes "base" matching "baseline" and "min" matching
*!     "minute".
*! 10. Cardiac (1 point, "any cardiac finding, including normal") is read from the
*!     un-negated text so a documented pertinent negative still counts.
*! 11. Laterality and sub-zone localization points are only awarded when the report
*!     scores for at least one abnormal finding.
*! 12. Quantification of B-lines/pleura uses the Table 1 values directly; the
*!     commented-out generic "quant" weights of the original are dropped.
*!
*! Reports that are empty or blank get a missing score.

program define lusinfoscore, rclass byable(recall)
    version 14.0
    syntax varname(string) [if] [in] , GENerate(name) ///
        [ REPlace DETail PREfix(name) NORMal(varname numeric) ///
          PTXpoints(real 20) PNITispoints(real 5) STRIP(string) NOCLIP KEEPTemplate ]

    * novarlist: empty reports stay in the sample (they get a missing score and are counted as unscored)
    marksample touse, strok novarlist

    * by varlist: lusinfoscore ...  -- the program runs once per group; the first call creates the
    * output variables and later calls fill their rows (scores are per report, so by only selects rows)
    local bycont = (_by() & _byindex() > 1)
    local gcmd "gen double"
    local gcmdb "gen byte"
    if `bycont' {
        local gcmd "replace"
        local gcmdb "replace"
    }

    if `bycont' {
        * output variables already created by the first by-group
    }
    else if "`replace'" == "" {
        confirm new variable `generate'
    }
    else {
        * exact: without it, drop would treat the name as an abbreviation and could drop another variable
        capture confirm variable `generate', exact
        if !_rc drop `generate'
    }
    if "`prefix'" == "" local prefix "lus_"

    local comps "bline blzone pleura parench effusion ptx laterality location etiology cardiac normal"
    if "`detail'" != "" {
        foreach c of local comps {
            if `bycont' {
            }
            else if "`replace'" == "" {
                confirm new variable `prefix'`c'
            }
            else {
                capture confirm variable `prefix'`c', exact
                if !_rc drop `prefix'`c'
            }
        }
    }

    * ------------------------------------------------------------------
    * Regex building blocks (ICU syntax). "@" marks a clause boundary.
    * ------------------------------------------------------------------
    local blx  "(?:\b[bv][- ]{0,2}lines?\b|\bvertical\s+artifacts?\b|\bcomet[- ]?tails?\b)"
    local nsh  "(?:(?!short)[a-z]+\s+)?"
    local plp  "(?:\bmoth[- ]?eaten\b|\bmothy\b|\bstring[- ]of[- ]pearls\b|\bpunch(?:ed)?[- ]?out\b|\bpleural\s+(?:line\s+)?(?:irreg|thicken|edema)|\birregular\s+(?:pleura|pleural)|\bthicken(?:ed|ing)\s+(?:of\s+(?:the\s+)?)?(?:pleura|pleural)|\bedema(?:tous)?\s+(?:of\s+)?(?:the\s+)?pleura|\bpleura(?:l)?[^@]{0,15}(?:irregular|thicken|edemat))"
    local pna  "(?:\bpneumonia\b|\bbronchopneumonia\b|\bpna\b|\bconsolidat\w*|\bshred(?:ded)?[\s-]+sign\b)"
    local abr  "air[- ]?bronch(?:io?|o)?[- ]?gram"
    local eff  "(?:\beffusions?\b|\bhydrothorax\b)"

    quietly {

        * ------------------------------------------------------------------
        * Text preparation
        * ------------------------------------------------------------------
        tempvar txt0 txt
        gen strL `txt0' = ustrlower(`varlist') if `touse'
        * unfilled template fields: {smart list choices} and the next two words, and ***
        replace `txt0' = ustrregexra(`txt0', "\{[^{}]*\}(?:\s+[a-z\-]+){1,2}", " ") if `touse'
        replace `txt0' = ustrregexra(`txt0', "\*{3,}", " ") if `touse'
        if "`noclip'" == "" {
            * ED-note preamble before the report header ("... lung ultrasound indication:") is not report text
            replace `txt0' = ustrregexra(`txt0', "(?s)^.*?(?=\b(?:point[- ]of[- ]care\s+)?lung\s+ultrasound\s+indications?\s*:)", " ") if `touse'
            * drop the clinical indication field and anything after the signature or ED course
            replace `txt0' = ustrregexra(`txt0', "(?s)\bindications?\s*:.*?(?=\b(?:machine|archived|probe|image\s+quality|narrative|findings|impression|views|procedure)\s*:|\z)", " ") if `touse'
            replace `txt0' = ustrregexra(`txt0', "(?s)(?:reviewed\s+and\s+)?electronically\s+signed.*\z|\bed\s+course\b.*\z|\bed\s+medication\b.*\z|\b(?:digitally\s+signed|signed\s+electronically|signed\s+by)\b.*\z", " ") if `touse'
            * "medical decision making" boilerplate: clipped after the impression (or anywhere if there is no impression)
            replace `txt0' = ustrregexra(`txt0', "(?s)(\bimpression\s*:.*?)\bmedical\s+decision\s+making\b.*\z", "$1") if `touse'
            replace `txt0' = ustrregexra(`txt0', "(?s)\bmedical\s+decision\s+making\b.*\z", " ") if `touse' & !ustrregexm(`txt0', "\bimpression\b")
        }
        if `"`strip'"' != "" {
            replace `txt0' = ustrregexra(`txt0', `"`strip'"', " ") if `touse'
        }
        gen strL `txt' = ustrregexra(`txt0', "[.;!?:\r\n|]+", "@") if `touse'
        replace `txt' = ustrregexra(`txt', "\s+", " ") if `touse'

        * "upper limit of normal" / "within normal limits" / WNL: drop that phrase's clause
        * (up to the neighbouring comma or sentence break) so it is not scored as a finding
        * "upper limit of normal to slightly abnormal B-lines" = borderline B-lines
        replace `txt' = ustrregexra(`txt', "\bupper\s+limits?\s+of\s+normal\s+to\s+(?:slightly|minimally|mildly)\s+abnormal\s+(?=`blx')", " borderline ") if `touse'
        replace `txt' = ustrregexra(`txt', "(?:(?!\b(?:with|and|but|while|whereas|however|although|though|plus|also)\b)[^@,])*(?:\bupper\s+limits?\s+of\s+normal|\bwithin\s+normal\s+limits|\bwnl\b)(?:(?!\b(?:with|and|but|while|whereas|however|although|though|plus|also)\b)[^@,])*", " ") if `touse'
        * dome of the diaphragm / liver dome is not a parenchymal "dome"
        replace `txt' = ustrregexra(`txt', "\b(?:hemi)?diaphragm(?:atic)?\s+dome\b|\bdome\s+of\s+(?:the\s+)?(?:hemi)?(?:diaphragm|liver)\b|\bliver\s+dome\b", " diaphragm ") if `touse'
        * pericardial effusion is not a pleural effusion
        replace `txt' = ustrregexra(`txt', "\b(?:pericardial|cardiac)\s+effusions?\b|\beffusions?\s+(?:in|of|around)\s+(?:the\s+)?pericardi\w*", " qpericard ") if `touse'
        * "cannot be excluded" is not a negation
        replace `txt' = ustrregexra(`txt', "\b(?:cannot|can\s+not|could\s+not)\s+(?:be\s+)?(?:exclude|excluded|rule\s+out|ruled\s+out)\b", " qcannotexclude ") if `touse'

        * severity tokens, most specific first
        replace `txt' = ustrregexra(`txt', "\b(?:moderate(?:ly)?|mod)(?:[\s/-]+to[\s/-]+|[\s/-]+)(?:severe(?:ly)?|sev)\b", " qmodsev ") if `touse'
        replace `txt' = ustrregexra(`txt', "\bmild(?:ly)?(?:[\s/-]+to[\s/-]+|[\s/-]+)(?:moderate(?:ly)?|mod)\b", " qmildmod ") if `touse'
        replace `txt' = ustrregexra(`txt', "\bvery\s+mild(?:ly)?\b", " qvmild ") if `touse'
        replace `txt' = ustrregexra(`txt', "\bsever(?:e|ely)\b", " qsevere ") if `touse'
        replace `txt' = ustrregexra(`txt', "\b(?:moderate|moderately|mod)\b", " qmoderate ") if `touse'
        replace `txt' = ustrregexra(`txt', "\bmild(?:ly)?\b", " qmild ") if `touse'

        * negation: post-negation first ("X was not seen", "X absent"), then pre-negation
        replace `txt' = ustrregexra(`txt', "(?:\b[a-z\-/]+\s+){1,4}(?:(?:was|were|is|are|been)\s+)?(?:not\s+(?:seen|identified|noted|visuali[sz]ed|appreciated|demonstrated|present|evident|detected)|absent|ruled\s+out)\b", " qneg ") if `touse'
        * a comma or "and" also ends the negation when the next item carries a quantity, size or severity
        * word ("no pneumothorax, long b-lines ..."; "no effusion and diffuse b-lines"); a plain list
        * ("no effusion, consolidation, or pneumothorax") stays negated
        local negpos "(?:long|few|occasional|scattered|several|multiple|numerous|diffuse(?:ly)?|excess\w*|carpet\w*|coalesc\w*|confluen\w*|patchy|multifocal|focal|small|tiny|trace|minimal|large|massive|extensive|significant|some|increased|lots?|borderline|qvmild|qmild|qmildmod|qmoderate|qmodsev|qsevere)"
        replace `txt' = ustrregexra(`txt', "\b(?:no|not|without|absent|absence\s+of|none|nor|negative\s+for|free\s+of|denies|rule\s+out|r/o)\b(?:(?!,\s*(?:consistent|compatible|c/w)\b|(?<!consistent )(?<!compatible )(?<!associated )\bwith\b|\b(?:but|however|although|though|except|whereas|demonstrat\w*|shows?|showing|there\s+(?:is|are)|impression|findings?)\b|(?:,\s*|\band\s+)(?!(?:or|nor|no)\b)(?=[^@,]{0,40}?\b`negpos'\b))[^@]){0,60}", " qneg ") if `touse'

        * ------------------------------------------------------------------
        * Normal impression
        * ------------------------------------------------------------------
        tempvar nrm keep
        local nph "(?:normal\b|unremarkable\b|within\s+normal\s+limits|wnl\b|(?:at\s+|near\s+)?(?:the\s+)?upper\s+limits?\s+of\s+normal)"
        * what "normal" describes: the whole study (study, exam, ultrasound, lungs, B-lines), not one feature
        * such as "normal lung sliding" or "normal cardiac function"
        local nnoun "(?:(?:limited|point[- ]of[- ]care|bedside|bilateral|thoracic|chest|pediatric|lung|lungs|cardiac|acoustic)\s+){0,4}(?:ultrasound|sonogram|us|lus|pocus|study|exam\w*|scan|findings?|lungs?|windows?|views?|[ab][- ]?lines?)\b(?!\s+sliding)"
        * after the impression: the normal word ends the statement (punctuation, line break, a run of spaces
        * or underscores where the next note field starts), or names the whole study
        local nsuf "(?:\s*\z|\s*[.;,!?\r\n_]|\s{2,}|\s+`nnoun')"
        gen byte `nrm' = (ustrregexm(`txt0', "impression\s*:?\s*(?:(?:essentially|almost|grossly|overall|completely)\s+)?`nph'`nsuf'") | ustrregexm(`txt0', "impression\s*:?\s*negative\s+(?:limited\s+)?(?:point[- ]of[- ]care\s+)?(?:lung\s+|lus\s+|thoracic\s+|chest\s+)?(?:ultrasound|lus|exam|study|scan)\b") | ustrregexm(`txt0', "\b(?:essentially|almost)\s+normal\s+`nnoun'") | ustrregexm(`txt0', "^\W*(?:(?:lung|lus|thoracic|chest)\s+(?:ultrasound\s+)?)?(?:(?:is|are|was|were)\s+)?`nph'\W*$")) if `touse'
        replace `nrm' = 0 if `touse' & (ustrregexm(`txt0', "impression\s*:?\s*abnormal") | ustrregexm(`txt0', "impression\s*:?\s*normal\W*(?:but|however|except|although|though)\b") | ustrregexm(`txt0', "otherwise\s+normal"))
        if "`normal'" != "" {
            replace `nrm' = (`normal' == 1) if `touse' & !missing(`normal')
        }
        gen byte `keep' = (`nrm' == 0) if `touse'

        * ------------------------------------------------------------------
        * B-lines (maximum attained)
        * ------------------------------------------------------------------
        * limiting quantity word + "excess/diffuse/numerous" (e.g. "occasional excess b-lines"): the quantity
        * word caps the B-line score at 1 (borderline); common misspellings of occasional are normalized
        replace `txt' = ustrregexra(`txt', "\boc+as+ional(?:ly)?\b|\bocasional(?:ly)?\b|\boccasionally\b", "occasional") if `touse'
        replace `txt' = ustrregexra(`txt', "\b(occasional|few|scant|rare|sparse|isolated)\s+(?:excess(?:ive)?|diffuse|numerous)\s+(?!short\b)", "$1 ") if `touse'
        tempvar bl
        gen double `bl' = 0 if `touse'
        replace `bl' = max(`bl', 1)  if `touse' & ustrregexm(`txt', "\b(?:borderline|isolated|scant|few|occasional|rare|sparse|minimal|trace|scattered|several|small\s+number\s+of|couple\s+of|handful\s+of)\s+`nsh'`blx'|\b(?:increased|increase\s+in)\s+(?:number\s+of\s+)?`nsh'`blx'")
        replace `bl' = max(`bl', 3)  if `touse' & ustrregexm(`txt', "\bexcess(?:ive)?\s+short\s+`blx'|(?:\bpatchy|\bmultifocal|\b(?:multiple|several|scattered|numerous)\s+(?:foci|areas|regions|zones))[^@]{0,40}`blx'|`blx'[^@]{0,25}\b(?:patchy|multifocal)\b")
        replace `bl' = max(`bl', 5)  if `touse' & ustrregexm(`txt', "\bcarpet[- ]?like\b[^@]{0,25}`blx'|`blx'[^@]{0,25}\bcarpet[- ]?like\b")
        replace `bl' = max(`bl', 10) if `touse' & ustrregexm(`txt', "(?<!few )(?<!borderline )(?<!isolated )(?<!scant )(?<!occasional )(?<!rare )(?<!sparse )(?<!minimal )(?<!trace )(?<!scattered )(?<!several )(?<!small number of )(?<!couple of )(?<!handful of )\blong\b[^@]{0,25}`blx'|\bexcess(?:ive)?\s+`nsh'`blx'|\bdiffuse(?:ly)?\b[^@]{0,25}`blx'|`blx'[^@]{0,25}\bdiffuse(?:ly)?\b|`blx'[^@]{0,30}\ball\s+(?:lung\s+)?zones\b|\ball\s+(?:lung\s+)?zones\b[^@]{0,30}`blx'|\blots?\s+of\s+(?:kerley\w*|`blx')")
        replace `bl' = max(`bl', 15) if `touse' & ustrregexm(`txt', "(?:\bcoalesc\w*|\bcoel\w*sc\w*|\bconfluen\w*)[^@]{0,40}`blx'|`blx'[^@]{0,40}(?:\bcoalesc\w*|\bcoel\w*sc\w*|\bconfluen\w*)|\bwhite[- ]?out\b")

        * where the sonographer looked ("windows interrogated bilaterally") does not say where the
        * findings were: inside a clause with a scanning verb, generic window names (posterior,
        * axillary, anterior) and bilateral(ly) are ignored for sub-zone and laterality counts.
        * Specific zones (upper/mid/lower posterior, base) and left/right are kept, so a mixed
        * sentence such as "windows scanned, with long B-lines in the left base" still scores.
        tempvar txtz
        gen strL `txtz' = ustrregexra(`txt', "(?:(?<!upper[ -])(?<!mid[ -])(?<!middle[ -])(?<!lower[ -])\bposterior\b|\baxill\w*|\banterior\b|\bbilateral(?:ly)?\b|\bbilat\b|\bbibasal\w*|\bbibasilar\w*|\ball\s+(?:lung\s+)?(?:zones?|fields?|areas?|regions?)\b)(?=[^@]*(?:\binterrogat\w*|\b(?:scanned|examined|evaluated|imaged|obtained|visuali[sz]ed|assessed)\b))", " ") if `touse'
        replace `txtz' = ustrregexra(`txtz', "(?<=(?:\binterrogat[a-z]{0,10}|\b(?:scanned|examined|evaluated|imaged|obtained|visuali[sz]ed|assessed)\b)[^@]{0,80})(?:(?<!upper[ -])(?<!mid[ -])(?<!middle[ -])(?<!lower[ -])\bposterior\b|\baxill\w*|\banterior\b|\bbilateral(?:ly)?\b|\bbilat\b|\bbibasal\w*|\bbibasilar\w*|\ball\s+(?:lung\s+)?(?:zones?|fields?|areas?|regions?)\b)", " ") if `touse'

        * sub-zone count (each term once) and sub-zone points added to larger B-line patterns
        tempvar zc blz
        gen byte `zc' = 0 if `touse'
        foreach z in "\bupper[\s-]+post" "\bmid(?:dle)?[\s-]+post" "\blower[\s-]+post" "(?<!upper[ -])(?<!mid[ -])(?<!middle[ -])(?<!lower[ -])\bposterior\b|\b(?:intra|infra|inter|sub|supra)?-?scapular\w*" "\bbas(?:e|es|al)\b|\bbibasal\w*|\bbibasilar\w*" "\baxill" "\banterior\b" "\bdiaphragm" {
            replace `zc' = `zc' + ustrregexm(`txtz', "`z'") if `touse'
        }
        * "all zones" / "all lung zones" / "all fields": every sub-zone (5) and both sides
        tempvar allz
        gen byte `allz' = ustrregexm(`txtz', "\ball\s+(?:lung\s+)?(?:zones?|fields?|areas?|regions?)\b") if `touse'
        replace `zc' = max(`zc', 5) if `touse' & `allz'
        gen double `blz' = cond(`zc'==2, 5, cond(`zc'==3, 7, cond(`zc'==4, 10, cond(`zc'>=5, 15, 0)))) * (`bl' >= 5) if `touse'

        * ------------------------------------------------------------------
        * Pleural pathology x quantifier (default 2; tokens are ascending so later replaces = maximum)
        * ------------------------------------------------------------------
        tempvar pl plh
        gen byte `plh' = ustrregexm(`txt', "`plp'") if `touse'
        gen double `pl' = 2 * `plh' if `touse'
        replace `pl' = 1  if `touse' & `plh' & ustrregexm(`txt', "`plp'[^@]{0,60}\b(?:qvmild|minimal|minimally|trace|tiny|slight|slightly)\b|\b(?:qvmild|minimal|minimally|trace|tiny|slight|slightly)\b[^@]{0,60}`plp'")
        replace `pl' = 2  if `touse' & `plh' & ustrregexm(`txt', "`plp'[^@]{0,60}\bqmild\b|\bqmild\b[^@]{0,60}`plp'")
        replace `pl' = 4  if `touse' & `plh' & ustrregexm(`txt', "`plp'[^@]{0,60}\bqmildmod\b|\bqmildmod\b[^@]{0,60}`plp'")
        replace `pl' = 7  if `touse' & `plh' & ustrregexm(`txt', "`plp'[^@]{0,60}\bqmoderate\b|\bqmoderate\b[^@]{0,60}`plp'")
        replace `pl' = 15 if `touse' & `plh' & ustrregexm(`txt', "`plp'[^@]{0,60}\bqmodsev\b|\bqmodsev\b[^@]{0,60}`plp'")
        replace `pl' = 20 if `touse' & `plh' & ustrregexm(`txt', "`plp'[^@]{0,60}\bqsevere\b|\bqsevere\b[^@]{0,60}`plp'")

        * ------------------------------------------------------------------
        * Air bronchograms / parenchyma / pneumonia (maximum attained)
        * ------------------------------------------------------------------
        tempvar par pnaf
        gen byte `pnaf' = ustrregexm(`txt', "`pna'") if `touse'
        gen double `par' = 0 if `touse'
        replace `par' = max(`par', 5)  if `touse' & ustrregexm(`txt', "`abr'")
        replace `par' = max(`par', 15) if `touse' & ustrregexm(`txt', "(?:concentric|irregular|dynamic|clustered)[^@]{0,25}`abr'|`abr'[^@]{0,25}(?:concentric|irregular|dynamic|clustered)|\bc[- ]?stripe\b|\bc[- ]?line\b|\bcupola\b|\bdome\b")
        replace `par' = max(`par', 15) if `touse' & `pnaf'
        replace `par' = max(`par', 5) if `touse' & ustrregexm(`txt', "\batelecta\w*")
        * pneumonitis (milder than pneumonia): points rise with the severity word near it
        tempvar pnt pnh
        gen byte `pnh' = ustrregexm(`txt', "(?:\bpneumonit\w*|\bbronchiolit\w*)") if `touse'
        gen double `pnt' = `pnitispoints' * `pnh' if `touse'
        replace `pnt' = 2 if `touse' & `pnh' & ustrregexm(`txt', "(?:\bpneumonit\w*|\bbronchiolit\w*)[^@]{0,60}\bqvmild\b|\bqvmild\b[^@]{0,60}(?:\bpneumonit\w*|\bbronchiolit\w*)")
        replace `pnt' = 5 if `touse' & `pnh' & ustrregexm(`txt', "(?:\bpneumonit\w*|\bbronchiolit\w*)[^@]{0,60}\bqmild\b|\bqmild\b[^@]{0,60}(?:\bpneumonit\w*|\bbronchiolit\w*)")
        replace `pnt' = 7 if `touse' & `pnh' & ustrregexm(`txt', "(?:\bpneumonit\w*|\bbronchiolit\w*)[^@]{0,60}\bqmildmod\b|\bqmildmod\b[^@]{0,60}(?:\bpneumonit\w*|\bbronchiolit\w*)")
        replace `pnt' = 10 if `touse' & `pnh' & ustrregexm(`txt', "(?:\bpneumonit\w*|\bbronchiolit\w*)[^@]{0,60}\bqmoderate\b|\bqmoderate\b[^@]{0,60}(?:\bpneumonit\w*|\bbronchiolit\w*)")
        replace `pnt' = 12 if `touse' & `pnh' & ustrregexm(`txt', "(?:\bpneumonit\w*|\bbronchiolit\w*)[^@]{0,60}\bqmodsev\b|\bqmodsev\b[^@]{0,60}(?:\bpneumonit\w*|\bbronchiolit\w*)")
        replace `pnt' = 15 if `touse' & `pnh' & ustrregexm(`txt', "(?:\bpneumonit\w*|\bbronchiolit\w*)[^@]{0,60}\bqsevere\b|\bqsevere\b[^@]{0,60}(?:\bpneumonit\w*|\bbronchiolit\w*)")
        replace `par' = max(`par', `pnt') if `touse' & `pnh'
        replace `par' = max(`par', 20) if `touse' & ustrregexm(`txt', "\bcauliflower\b|\bhepati[sz]ation\b")
        replace `par' = max(`par', 20) if `touse' & `pnaf' & ustrregexm(`txt', "`pna'[^@]{0,60}(?:\bmulti[- ]?lob\w*|\bbilat\w*|\bboth\s+lungs\b|\bextensive\b|\bqsevere\b|\bqmodsev\b)|(?:\bmulti[- ]?lob\w*|\bbilat\w*|\bboth\s+lungs\b|\bextensive\b|\bqsevere\b|\bqmodsev\b)[^@]{0,60}`pna'|(?:\bleft\b[^@]{0,30}\bright\b|\bright\b[^@]{0,30}\bleft\b)[^@]{0,40}`pna'")

        * air bronchograms add to pneumonia/consolidation instead of being absorbed by it: +5 when mentioned,
        * +10 when described as concentric, irregular, dynamic or clustered; a static air bronchogram is only "mentioned" (+5)
        tempvar abp
        gen double `abp' = 5 * ustrregexm(`txt', "`abr'") if `touse'
        replace `abp' = 10 if `touse' & ustrregexm(`txt', "(?:concentric|irregular|dynamic|clustered)[^@]{0,25}`abr'|`abr'[^@]{0,25}(?:concentric|irregular|dynamic|clustered)")
        replace `par' = `par' + `abp' if `touse' & `pnaf'

        * ------------------------------------------------------------------
        * Pleural effusion (scored once; tiers differ with pneumonia)
        * ------------------------------------------------------------------
        tempvar effh efft effp
        gen byte `effh' = ustrregexm(`txt', "`eff'") if `touse'
        gen byte `efft' = `effh' if `touse'
        replace `efft' = 2 if `touse' & `effh' & ustrregexm(`txt', "`eff'[^@]{0,40}\bsmall\b|\bsmall\b[^@]{0,40}`eff'")
        replace `efft' = 3 if `touse' & `effh' & ustrregexm(`txt', "`eff'[^@]{0,40}\bqmoderate\b|\bqmoderate\b[^@]{0,40}`eff'")
        replace `efft' = 4 if `touse' & `effh' & ustrregexm(`txt', "`eff'[^@]{0,40}\b(?:large|extensive|massive|qsevere|qmodsev)\b|\b(?:large|extensive|massive|qsevere|qmodsev)\b[^@]{0,40}`eff'")
        * Effusion, parsed per side. Size per side: tiny/trace/minimal 5, small 10, moderate 15, large 20,
        * no size word 10. A size word is attached to a side when it sits next to it ("small right",
        * "left ... moderate"); otherwise the size near the effusion applies to each side named. Left and
        * right both named = sum of the two sides; "bilateral" alone = twice the size; one side = that side.
        * "loculated" or "non-loculated" near the effusion adds 5. With pneumonia the larger of this and the
        * pneumonia-specific tiers (tiny 5, small 15, moderate/large 20) counts.
        local ef_t "(?:tiny|trace|minimal|minimally)"
        local ef_l "(?:large|extensive|massive|qsevere|qmodsev)"
        local ef_stop "(?:(?!\b(?:and|but|with|left|right|bilateral\w*)\b)[^@,]){0,25}"
        local ef_sstop "(?:(?!\b(?:but|with|consolidat\w*|pneumon\w*|atelect\w*|lobe)\b)[^@,]){0,30}"
        local ef_bil "(?:bilateral\w*|bilat\b|both\s+(?:sides|lungs|hemithoraces|pleural\s+spaces)|bibasal\w*|bibasilar\w*)"
        tempvar eg ehl ehr elp erp eb eloc effn effl
        gen double `eg' = 10 * `effh' if `touse'
        replace `eg' = 5  if `touse' & `effh' & ustrregexm(`txt', "`eff'[^@]{0,40}\b`ef_t'\b|\b`ef_t'\b[^@]{0,40}`eff'")
        replace `eg' = 10 if `touse' & `effh' & ustrregexm(`txt', "`eff'[^@]{0,40}\bsmall\b|\bsmall\b[^@]{0,40}`eff'")
        replace `eg' = 15 if `touse' & `effh' & ustrregexm(`txt', "`eff'[^@]{0,40}\bqmoderate\b|\bqmoderate\b[^@]{0,40}`eff'")
        replace `eg' = 20 if `touse' & `effh' & ustrregexm(`txt', "`eff'[^@]{0,40}\b`ef_l'\b|\b`ef_l'\b[^@]{0,40}`eff'")
        foreach pair in "l left" "r right" {
            gettoken k sd : pair
            local sd `sd'
            gen byte `eh`k'' = ustrregexm(`txt', "\b`sd'\b`ef_sstop'`eff'|`eff'`ef_sstop'\b`sd'\b") if `touse' & `effh'
            replace `eh`k'' = 0 if `touse' & missing(`eh`k'')
            gen double `e`k'p' = 0 if `touse'
            replace `e`k'p' = 5  if `touse' & `eh`k'' & ustrregexm(`txt', "\b`ef_t'\b`ef_stop'\b`sd'\b|\b`sd'\b`ef_stop'\b`ef_t'\b")
            replace `e`k'p' = 10 if `touse' & `eh`k'' & ustrregexm(`txt', "\bsmall\b`ef_stop'\b`sd'\b|\b`sd'\b`ef_stop'\bsmall\b")
            replace `e`k'p' = 15 if `touse' & `eh`k'' & ustrregexm(`txt', "\bqmoderate\b`ef_stop'\b`sd'\b|\b`sd'\b`ef_stop'\bqmoderate\b")
            replace `e`k'p' = 20 if `touse' & `eh`k'' & ustrregexm(`txt', "\b`ef_l'\b`ef_stop'\b`sd'\b|\b`sd'\b`ef_stop'\b`ef_l'\b")
            replace `e`k'p' = `eg' if `touse' & `eh`k'' & `e`k'p' == 0
        }
        gen byte `eb' = ustrregexm(`txt', "`ef_bil'[^@]{0,40}`eff'|`eff'[^@]{0,40}`ef_bil'") if `touse' & `effh'
        gen byte `eloc' = ustrregexm(`txt', "(?:\b(?:non|un)[- ]?loculated\b|\bloculated\b)[^@]{0,40}`eff'|`eff'[^@]{0,40}(?:\b(?:non|un)[- ]?loculated\b|\bloculated\b)") if `touse' & `effh'
        gen double `effn' = 0 if `touse'
        replace `effn' = `elp' + `erp' if `touse' & `effh' & `ehl' & `ehr'
        replace `effn' = 2 * `eg'      if `touse' & `effh' & !(`ehl' & `ehr') & `eb'
        replace `effn' = `elp'         if `touse' & `effh' & !`eb' & `ehl' & !`ehr'
        replace `effn' = `erp'         if `touse' & `effh' & !`eb' & !`ehl' & `ehr'
        replace `effn' = `eg'          if `touse' & `effh' & !`eb' & !`ehl' & !`ehr'
        replace `effn' = `effn' + 5 * `eloc' if `touse' & `effh'
        gen double `effl' = cond(`efft'==1, 5, cond(`efft'==2, 15, 20)) if `touse' & `effh'
        gen double `effp' = 0 if `touse'
        replace `effp' = `effn' if `touse' & `effh'
        replace `effp' = max(`effn', `effl') if `touse' & `effh' & `pnaf'

        * pneumothorax (no row in Table 1; points set by ptxpoints(), default 20)
        tempvar ptx
        gen double `ptx' = `ptxpoints' * ustrregexm(`txt', "\bpneumo-?n?thora\w*|\bptx\b") if `touse'

        * ------------------------------------------------------------------
        * Location, etiology, cardiac
        * ------------------------------------------------------------------
        tempvar core lat loc eti card
        gen double `core' = `bl' + `blz' + `pl' + `par' + `effp' + `ptx' if `touse'
        * heart chambers ("right ventricle", "left atrium", "right-sided heart") are not lung laterality
        tempvar txtl
        gen strL `txtl' = ustrregexra(`txtz', "\b(?:left|right)[\s-]+(?:sided\s+)?(?:ventric\w*|atri(?:um|a|al)\b|heart\b|cardiac\b|chambers?\b)", " ") if `touse'
        gen double `lat' = 3 * (ustrregexm(`txtl', "\b(?:left|right|bilateral|bilaterally|unilateral|bilat|bibasal\w*|bibasilar\w*)\b") | `allz') * (`core' > 0) if `touse'
        gen double `loc' = 2 * (`zc' >= 1) * (`core' > 0) if `touse'

        tempvar en dx
        gen byte `en' = ustrregexm(`txt', "\b(?:covid(?:[- ]?19)?|sars[- ]?cov(?:[- ]?2)?|rsv|respiratory\s+syncytial|influenza|flu|adenovir\w*|metapneumovir\w*|rhinovir\w*|parainfluenza|mycoplasma|mis[- ]?c)\b") ///
                      + ustrregexm(`txt', "\bbacterial\b|\bpneumococc\w*") ///
                      + ustrregexm(`txt', "\bcardiogenic\b|\bpulmonary\s+edema\b|\bheart\s+failure\b|\bchf\b") ///
                      + ustrregexm(`txt', "\baspiration\b") ///
                      + ustrregexm(`txt', "\b(?:contusion|foreign\s+body)\b") if `touse'
        * "bronchiolitis versus pneumonitis" (or "or", "/") is not enough to count as a differential
        tempvar txtd
        gen strL `txtd' = ustrregexra(`txt', "(?:bronchiolit\w*|pneumonit\w*)\s*(?:versus|vs@?|or|/)\s*(?:bronchiolit\w*|pneumonit\w*)", " ") if `touse'
        * "consider X" / "considerations" / "should be considered" suggest a differential; "findings considered
        * consistent with ..." and "considered normal" do not
        gen byte `dx' = ustrregexm(`txtd', "\bdifferential\b|\bddx\b|\bd/dx\b|\bversus\b|\bvs\b|\bconsider\b|\bconsiderations?\b|\b(?:be|been)\s+considered\b(?!\s+(?:normal|consistent|compatible|typical|unremarkable|reassuring)\b)|\bqcannotexclude\b") if `touse'
        gen double `eti' = 15 * ((`en' >= 1) | `dx') if `touse'   // capped: 15 maximum in total

        gen double `card' = ustrregexm(`txt0', "\b(?:cardiac|heart|contractil\w*|myocard\w*|pericard\w*|ventric\w*|ejection)\b") if `touse'

        * ------------------------------------------------------------------
        * Total (normal reports score 0; blank reports are missing)
        * ------------------------------------------------------------------
        tempvar tot
        gen double `tot' = (`core' + `lat' + `loc' + `eti' + `card') * `keep' if `touse'
        replace `tot' = . if `touse' & !ustrregexm(`varlist', "\S")
        * unfilled Epic template (placeholders such as {location:138623} or {sh:125346::"presence","absence"}) -> missing
        if "`keeptemplate'" == "" {
            replace `tot' = . if `touse' & ustrregexm(`varlist', "\{[^{}]*:\d+[^{}]*\}")
        }

        `gcmd' `generate' = `tot' if `touse'
        label variable `generate' "LUS report information score"

        if "`detail'" != "" {
            `gcmd' `prefix'bline      = `bl'   * `keep' if `touse'
            `gcmd' `prefix'blzone     = `blz'  * `keep' if `touse'
            `gcmd' `prefix'pleura     = `pl'   * `keep' if `touse'
            `gcmd' `prefix'parench    = `par'  * `keep' if `touse'
            `gcmd' `prefix'effusion   = `effp' * `keep' if `touse'
            `gcmd' `prefix'ptx        = `ptx'  * `keep' if `touse'
            `gcmd' `prefix'laterality = `lat'  * `keep' if `touse'
            `gcmd' `prefix'location   = `loc'  * `keep' if `touse'
            `gcmd' `prefix'etiology   = `eti'  * `keep' if `touse'
            `gcmd' `prefix'cardiac    = `card' * `keep' if `touse'
            `gcmdb' `prefix'normal     = `nrm' if `touse'
            foreach c of local comps {
                replace `prefix'`c' = . if `touse' & missing(`generate')
            }
            label variable `prefix'bline      "LUS score: B-lines"
            label variable `prefix'blzone     "LUS score: sub-zone count points (B-lines)"
            label variable `prefix'pleura     "LUS score: pleural pathology"
            label variable `prefix'parench    "LUS score: air bronchograms/consolidation"
            label variable `prefix'effusion   "LUS score: pleural effusion"
            label variable `prefix'ptx        "LUS score: pneumothorax"
            label variable `prefix'laterality "LUS score: laterality"
            label variable `prefix'location   "LUS score: sub-zone localization"
            label variable `prefix'etiology   "LUS score: etiology/differential"
            label variable `prefix'cardiac    "LUS score: cardiac finding"
            label variable `prefix'normal     "LUS: normal impression (score forced to 0)"
        }
    }

    quietly count if `touse' & !missing(`generate')
    local nsc = r(N)
    quietly count if `touse' & missing(`generate')
    local nmiss = r(N)
    quietly count if `touse' & !missing(`generate') & `generate' > 0
    local npos = r(N)
    display as txt "lusinfoscore v1.0.32: " as res `nsc' as txt " reports scored (" as res `npos' ///
        as txt " with score > 0), " as res `nmiss' as txt " blank/unscored -> " as res "`generate'"

    return local version "1.0.32"
    return scalar N_scored = `nsc'
    return scalar N_positive = `npos'
    return scalar N_unscored = `nmiss'
end
