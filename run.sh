#!/bin/bash

#VARS:

REPO_USER=$WERCKER_CHANGELOG_REPO_USER
REPO_NAME=$WERCKER_CHANGELOG_REPO_NAME
REPO_PATH=$WERCKER_CACHE_DIR"/my_tmp/"$REPO_NAME
FORCE_CLONE=$WERCKER_CHANGELOG_FORCE_CLONE
PROD_TAG=$WERCKER_CHANGELOG_PROD_TAG
#TAG_PATH=$WERCKER_SOURCE_DIR"/tag"
CHANGELOG=$WERCKER_OUTPUT_DIR"/changelog-"$REPO_NAME
FIRST_TAG=$WERCKER_CHANGELOG_FIRST_TAG
SECOND_TAG=$WERCKER_CHANGELOG_SECOND_TAG
COMMIT_SHA=$WERCKER_CHANGELOG_COMMIT_SHA

###### end VARS ##################


##### functions ###########

# clone or pull a repository
# ARG1: repo name
# ARG2: local PATH to store the repo
# ARG3: repo username
# ARG4: branch name
# ARG5: remove REPO_PATH
function clone_pull_repo (){
        local REPO=$1
        local REPO_PATH=$2
        local USER=$3
        local BRANCH=$4
        local DEL_REPO_PATH=$5

        if [[ ${DEL_REPO_PATH,,} == "yes" ]];then
                rm -rf $REPO_PATH
        fi
        #check if REPO_PATH exists
        if [ ! -d "$REPO_PATH" ]; then
                echo "Clone repository: $REPO"
                mkdir -p $REPO_PATH
                cd $REPO_PATH
                echo "git clone git@github.com:$USER/$REPO.git . >/dev/null"
                git clone git@github.com:$USER/$REPO.git . >/dev/null
                if [ $? -eq 0 ]; then
                        echo "Repository $REPO created"
                else
                        echo "Failed to create repository $REPO"
                        rm -rf $REPO_PATH
                        return 3
                fi
        fi
        echo "Pull repository: $REPO"
        cd $REPO_PATH
        git checkout $BRANCH
        if [ $? -eq 0 ]; then
                echo "Succesfully switched to branch $BRANCH"
                git pull 2>/dev/null
        else
                echo "Branch $BRANCH does not exists"
                #rm -rf $REPO_PATH
                return 3
        fi
        # prunes tracking branches not on the remote
        git remote prune origin | awk 'BEGIN{FS="origin/"};/pruned/{print $3}' | xargs -r git branch -D
}

function changelog {
        local FIRST_TAG=$1
        local SECOND_TAG=$2

        git log  --pretty=format:"%h - %an, %ar : %b: %s" $FIRST_TAG..$SECOND_TAG |  grep -i -w -Eo "ESDT-[0-9]+" | tr '[:lower:]' '[:upper:]'>$CHANGELOG
        #git log  --pretty=format:"%h - %an, %ar : %b: %s" $FIRST_TAG..$SECOND_TAG | grep "Merge pull"  | cut -d\/ -f2- | cut -d\  -f1| tr '[:lower:]' '[:upper:]' >>$CHANGELOG
        cat $CHANGELOG | sort -rn | uniq
}

######################## END functions ################

if [[ ${FORCE_CLONE,,} == "yes" ]];then
    rm -rf $REPO_PATH
fi

echo "clone_pull_repo $REPO_NAME $REPO_PATH $REPO_USER master"
clone_pull_repo $REPO_NAME $REPO_PATH $REPO_USER master
if [ $? -ne 0 ]; then
        echo "Branch $SOURCE_BRANCH not found"
        exit 3
fi

#add build tag
if [[ -n $SECOND_TAG ]];then
    echo "tag_commit_sha $REPO_NAME $REPO_PATH $REPO_USER $NEW_TAG $COMMIT_SHA"
    tag_commit_sha $REPO_NAME $REPO_PATH $REPO_USER $NEW_TAG $COMMIT_SHA
fi
#add production tag if exists
if [[ -n $PROD_TAG ]];then
        #tag_commit_sha $REPO_NAME $REPO_PATH $REPO_USER $PROD_TAG $COMMIT_SHA
        echo "tag prod"
fi

if [[ -n $FIRST_TAG ]] && [[ -n $SECOND_TAG ]];then
        changelog $FIRST_TAG $SECOND_TAG
        echo "changelog $FIRST_TAG $SECOND_TAG"
else
        echo "FIRST_TAG $FIRST_TAG is not set or"
        echo "SECOND_TAG $SECOND_TAG is not set"
fi