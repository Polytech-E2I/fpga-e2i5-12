#! /bin/bash

# $1 : path of target directory (where produced badges will be stored)
# $2 : mode of the script. Accepted values are : "autotest", "mutants", "manual"
# $3 :   - in "manual" mode   : path to the file with manual validations listing
#        - in "autotest" mode : path to the autotest results file
#        - in "mutants" mode  : path to the mutants results file

PATH=~/.local/bin:$PATH
check_anybadge() {
        command -v anybadge >/dev/null 2>&1 || {
                echo "anybadge n'est pas installé on l'installe pour l'utilisateur"
                (wget https://bootstrap.pypa.io/get-pip.py && python get-pip.py --user
                cd ~/.local/bin
                ./pip install anybadge --user
                )
        }
}

check_anybadge # Première vérification et installation si nécessaire
check_anybadge # Deuxième vérification, devrait être ok

source ../config/inst_cfg.source

PUBLIC_DIR="$1"
MODE="$2"
FILENAME="$3"

work_dir=${PUBLIC_DIR}
note_dir=${PUBLIC_DIR}/note

if [[ "$MODE" == "mutants" ]] ; then
    work_dir=${PUBLIC_DIR}/mutants
elif [[ "$MODE" == "manual" ]] ; then
    work_dir=${PUBLIC_DIR}/manual
    MANUAL_OPS=$(cat ${FILENAME})
elif [[ "$MODE" == "autotest" ]] ; then
    work_dir=${PUBLIC_DIR}
else 
    echo "ERROR: Unsupported mode $MODE . Accepted modes are autotest, mutants, manual."
    exit -1
fi

mkdir -p ${work_dir}

echo "Generation des badge pour : $MODE"


convert_perc_to_color() {
    perc="-1"
    if [ "$1" != "" ] ; then
        perc="$1"
    fi
    if [ "$perc" -eq 100 ] ; then
        color=green
    elif [ "$perc" -gt 75 ] ; then
        color=#00FFFF
    elif [ "$perc" -gt 40 ] ; then
        color=yellow
    elif [ "$perc" -ge 0 ] ; then
        color=red
    else
        echo "percentage undefined"
        # undefined case
        color=#FFC0CB
    fi
}

get_color() {
    case $1 in
        PASSED|full_coverage)
            color=green
            ;;
        Done)
            color=#5b9b84
            ;;
        FAILED|low_coverage)
            color=red
            ;;
        TIMEOUT|medium_coverage)
            color=yellow
            ;;
        todo|need_working_feature_and_test)
            color=#E0E0E0
            ;;
        NO_TEST_FOUND|no_mutants_found)
            color=#FFC0CB
            ;;
        high_coverage)
            color=#00FFFF
            ;;
        timestamp)
            color=blue
            ;;
        *)
            color=gray
            ;;
    esac

}

generate_timestamp_badge() {
    echo "Generating timestamp bagde"
    get_color "timestamp"
    tag="timestamp"
    result=$(date +%d.%m.%Y_%H:%M:%S) 
    anybadge -o -l "$tag" -v "$result" -c "$color" -f ${work_dir}/timestamp.svg
}

generate_progression_badge() {
    rm -rf ${note_dir}
    mkdir -p ${note_dir}
    echo "Generating note badge"
    get_color "note"
    tag=$(basename $(dirname $(pwd)) | sed 's/_eval//')
    source ../avancement.source
    content=${note_tmp}
    anybadge -o -l "$tag" -v "${content}" -c "$color" -f ${note_dir}/note.svg
    for i in 1 2 3 4 5 ; do
        var="avcmt_$i"
        tag="seance $i"
        echo "  - séance $i"
        convert_perc_to_color ${!var}
        content="${!var}%"
        anybadge -o -l "$tag" -v "${content}" -c "$color" -f ${note_dir}/seance_$i.svg
        
    done
}

generate_default_badges_manual() {
    echo "generating default manual badges"
    for op in ${MANUAL_OPS}
    do
        echo " - ${op}"
        result="todo"
        get_color $result
        cat liste_binomes.txt | while read line
        do
            anybadge -o -l "$op" -v "$result" -c "$color" -f ${work_dir}/${op}_${line}.svg
        done
    done
}

generate_default_badges() {
    echo "Generating default badges for ${MODE}"
    for tag in ${GEN_BADGES}
    do
        if [[ "${MODE}" == "autotest" ]] ; then
            result="todo"
        elif [[ "${MODE}" == "mutants" ]]; then 
            result="need_working_feature_and_test"
        fi
        echo " - ${tag}"
        get_color $result
        anybadge -o -l "$tag" -v "$result" -c "$color" -f ${work_dir}/${tag}.svg
    done
}


get_info() {
# $1 : contains a full line of the test results file, of which we want to extract the info 
    if [[ ${MODE} == autotest ]] ; then

        info=$(echo $1 | sed 's/.*(\(.*\)).*/\1/' | sed 's/ /,/g')
    else # mutants
        info=$(echo $1 | awk '{print $3;}' ) 
    fi
}


format_result() {
    # $1 : result before badge formating
    # $2 : infos for formating
    
    formated_result=$1
    
    if [[ ${MODE} == autotest ]] ; then
        # If tag's result is not "PASSED" (or NO_TEST_FOUND) 
        # for a given tag and the tag has several tags files associated with
        # it, then we print the result per files as well on the badge.
        if [[ "$1" != "PASSED" && "$1" != "NO_tag_FOUND" ]] ; then
            several_tags=$(echo $2 | grep ",")
            if [[ "${several_tags}" != "" ]] ; then
                formated_result="$1,$2"
            fi
        fi
    else #mutants mode
        if     [ "$1" != "need_working_feature_and_test" ] && [ "$1" != "no_mutants_found" ] ; then
            formated_result="$2"
        fi
    fi
}

generate_manual_badges() {
    echo "Generating manual badges"
    for op in ${MANUAL_OPS}
    do
        echo "${op}"
        cat ${op}.txt | while read line
        do
            echo "$op"
            result="Done"
            get_color $result
            anybadge -o -l "${op}" -v "${result}" -c "${color}" -f ${work_dir}/${op}_${line}.svg
        done
    done
}


generate_badges() {
    # $1 : file containing tests results 
    
    cat $1 | while read line
    do
        tag=$(echo $line | awk '{print $1;}')
        tag=${tag}
        echo "$tag"
        result=$(echo $line | awk '{print $2;}')
        get_info "$line"
        get_color $result
        format_result "${result}" "${info}"
        anybadge -o -l "$tag" -v "${formated_result}" -c "${color}" -f ${work_dir}/$tag.svg
    done
}



mkdir -p ${work_dir}
rm -f ${work_dir}/*.svg

if [[ "$MODE" == "manual" ]] ; then
    generate_default_badges_manual
    generate_manual_badges
    exit 0
fi

generate_default_badges 
generate_badges ${FILENAME}
#if [[ $MODE == "mutants" ]] ; then
    generate_progression_badge
#fi
generate_timestamp_badge
