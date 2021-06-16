#!/usr/bin/env bash
shopt -s globstar
# we've been invoked w/ stdin, just run it
if [ ! -t 0 ]; then
    nodejs applyPatch.js < /dev/stdin
    exit 0
fi

cd dirname "$0"  || exit 1
BASE_PATH=${BASE_PATH:../../../}

build () {
    # since there's not stdin we are expecting a mounted directory
    TARGET_PATH=${BASE_PATH}/config/7.0/$1
    OVERLAY_PATH=${BASE_PATH}/config/$2
    
    # build baseline from target
    OUTPUT_PATH=${BASE_PATH}/docker
    cp -R $TARGET_PATH/* "$OUTPUT_PATH/"
    
    # overwrite baseline with patches
    for patch in $OVERLAY_PATH/**/*.json;
    do
        patch_filename=$(basename ${patch})
        output_base_path=$(dirname ${patch/$OVERLAY_PATH/$OUTPUT_PATH})
        mkdir -p $output_base_path
        # a file with a patch has a patch applied
        if [[ "$patch_filename" == *"patch.json" ]];
        then
            target_name=${patch_filename/.patch/}
            target_base_path=$(dirname ${patch/${OVERLAY_PATH}/$TARGET_PATH})
            target_path="${target_base_path}/${target_name}"
            output="${output_base_path}/${target_name}"
            cat $target_path <(echo "=====") $patch | nodejs applyPatch.js > $output
            continue
        fi
        # copy files wholesale if they don't have patch in the name
        cp "${patch}" "${output_base_path}/${patch_filename}"
    done
}

if [[ $# -ne 3 ]];             
then                                      
    echo "requires three args"     
    exit 1                                
fi                                        
                                          
case $1 in                        
    build)                                
        build "$2" "$3";; 
    **)                                   
        echo "invalid arg"; exit 1;;      
esac
