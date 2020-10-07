#!/bin/bash

#VARS:

####################
Expected environment variables
####################
#REPO_USER
#REPO_NAME
#FORCE_CLONE force repository clone
#PROD_TAG not used
#TAG_PATH not used
#FIRST_TAG previous build number
#SECOND_TAG current build number
#COMMIT_SHA current commit_sha build
#TOKEN git hub token

REPO_PATH="/my_tmp/"$REPO_NAME
CHANGELOG_FILE="/changelog-"$REPO_NAME
CHANGELOG_TMP_FILE="/changelog-"$REPO_NAME"tmp"

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
                echo "git clone https://token@github.com/$USER/$REPO.git "
                git clone https://${TOKEN}@github.com/$USER/$REPO.git
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

        git log  --merges --pretty=format:"%h - %an, %ar : %b: %s" $FIRST_TAG..$SECOND_TAG |  grep -i  -Eo "ESDT-[0-9]+" | tr '[:lower:]' '[:upper:]'| cut -d\- -f1,2 | cut -d_ -f1>$CHANGELOG_TMP_FILE
        #git log  --pretty=format:"%h - %an, %ar : %b: %s" $FIRST_TAG..$SECOND_TAG | grep "Merge pull"  | cut -d\/ -f2- | cut -d\  -f1| tr '[:lower:]' '[:upper:]' >>$CHANGELOG
        cat $CHANGELOG_TMP_FILE | sort -rn | uniq > $CHANGELOG_FILE
        cat $CHANGELOG_FILE
        rm -f $CHANGELOG_TMP_FILE
}

# Tag commit. If the commit is not provided the last commit will be tagged
# ARG1: repo name
# ARG2: local PATH to store the repo
# ARG3: repo username
# ARG4: TAG
# ARG5: commit sha (if the commit sha is missing the last commit will be tagged)
#
function tag_commit_sha(){
        local REPO=$1
        local REPO_PATH=$2
        local USER=$3
        local NEW_TAG=$4
        local COMMIT_SHA=$5

        if [ -d "$REPO_PATH" ]; then
                if [[ -z $COMMIT_SHA ]]; then
                        COMMIT_SHA=$(git log -n 1 |  head -n 1 |  cut -d\  -f2)
                fi
                git tag $NEW_TAG $COMMIT_SHA
                echo "git tag $NEW_TAG $COMMIT_SHA"
                git push origin $NEW_TAG
                echo "git push origin $NEW_TAG"

        else
                echo "Please clone repository $REPO first"
                return 2
        fi

}



######################## END functions ################


echo "clone_pull_repo $REPO_NAME $REPO_PATH $REPO_USER master $FORCE_CLONE"
clone_pull_repo $REPO_NAME $REPO_PATH $REPO_USER master $FORCE_CLONE
if [ $? -ne 0 ]; then
        echo "Branch $SOURCE_BRANCH not found"
        exit 3
fi

#add build tag
if [[ -n $SECOND_TAG ]];then
    echo "tag_commit_sha $REPO_NAME $REPO_PATH $REPO_USER $SECOND_TAG $COMMIT_SHA"
    tag_commit_sha $REPO_NAME $REPO_PATH $REPO_USER $SECOND_TAG $COMMIT_SHA
fi
#add production tag if exists
if [[ -n $PROD_TAG ]];then
        tag_commit_sha $REPO_NAME $REPO_PATH $REPO_USER $PROD_TAG $COMMIT_SHA
        echo "tag_commit_sha $REPO_NAME $REPO_PATH $REPO_USER $PROD_TAG $COMMIT_SHA"
fi

if [[ -n $FIRST_TAG ]] && [[ -n $SECOND_TAG ]];then
        changelog $FIRST_TAG $SECOND_TAG
        echo "changelog $FIRST_TAG $SECOND_TAG"
else
        echo "FIRST_TAG $FIRST_TAG is not set or"
        echo "SECOND_TAG $SECOND_TAG is not set"
fi