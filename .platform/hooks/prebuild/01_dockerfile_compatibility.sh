#!/usr/bin/env bash

# Replace all named stages since it is not yet supported in Amazon Linux 2 for Elastic Beanstalk
# https://stackoverflow.com/questions/61518512/aws-elastic-beanstalk-docker-does-not-support-multi-stage-build

DOCKERFILE="$PWD/Dockerfile"
TMP_FILE="$PWD/tmp_file"

# Remove dev stage
sed -n '/^FROM prod AS dev/q;p' $DOCKERFILE > $TMP_FILE && mv $TMP_FILE $DOCKERFILE

# Find all named stages from the Dockerfile
NAMED_STAGES=$(sed -n 's/FROM .* AS \(\w*\)/\1/p' $DOCKERFILE)

# Replace words/phrases in the file given the file, search pattern and replace pattern
string_replace_dockerfile() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
        --file)
            local FILE="$2"
            shift
            ;;
        --search)
            local SEARCH="$2"
            shift
            ;;
        --replace)
            local REPLACE="$2"
            shift
            ;;
        *)
            echo "Unknown parameter: $1" >&2
            return 1
            ;;
        esac
        shift
    done

    # Replace "$SEARCH" with "$REPLACE" and save to tmp file
    # Partial match like "$SEARCH"X is not replaced
    # Partial match like "$SEARCH": is not replaced
    # sed definition: "/$SEARCH:/!" - skip if the $SEARCH has ":" suffix
    # sed definition: "s/$SEARCH\b/$REPLACE/g" - replace all occurence of "$SEARCH" to "$REPLACE"
    sed "/$SEARCH:/! s/$SEARCH/$REPLACE/g" $FILE >$TMP_FILE

    # Replace original file with tmp file
    mv $TMP_FILE $FILE
}

declare -i STAGE_INDEX=0
for STAGE in $NAMED_STAGES; do
    # Replace "FROM $STAGE" to "FROM $STAGE_INDEX"
    string_replace_dockerfile \
        --file "$DOCKERFILE" \
        --search "^FROM $STAGE\b" \
        --replace "FROM $STAGE_INDEX"

    # Replace "--from=$STAGE" to "--from=$STAGE_INDEX"
    string_replace_dockerfile \
        --file "$DOCKERFILE" \
        --search "^COPY --from=$STAGE\b" \
        --replace "COPY --from=$STAGE_INDEX"

    STAGE_INDEX+=1
done

# Replace "FROM X AS Y" to "FROM X"
string_replace_dockerfile \
    --file "$DOCKERFILE" \
    --search "^FROM \(.*\) AS .*$" \
    --replace "FROM \1"
