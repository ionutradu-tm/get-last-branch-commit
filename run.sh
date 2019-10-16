#!/bin/bash


#VARS

REPO_USER=$WERCKER_GET_LAST_BRANCH_COMMIT_REPO_USER
REPO_NAME=$WERCKER_GET_LAST_BRANCH_COMMIT_REPO_NAME
REPO_PATH=$WERCKER_CACHE_DIR"/my_tmp/"$REPO_NAME
BRANCH=$WERCKER_GET_LAST_BRANCH_COMMIT_BRANCH
FORCE_CLONE=$WERCKER_GET_LAST_BRANCH_COMMIT_FORCE_CLONE

#END_VARS

# FUNCTIONS

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
                return 3
        fi
        # prunes tracking branches not on the remote
        git remote prune origin | awk 'BEGIN{FS="origin/"};/pruned/{print $3}' | xargs -r git branch -D
        if [ $? -eq 0 ]; then
                echo "Repository $REPO pruned"
        else
                echo "Failed to prune repository $REPO"
                return 2
        fi
}



function last_commit(){
  local BRANCH=$1

  LAST_SHA=$(git rev-parse $BRANCH)
  export LAST_SHA
}

#END_FUNCTIONS

#check vars

if [[ -z $REPO_USER ]]; then
    echo "Please provide repo username"
    exit 1
fi
if [[ -z $REPO_NAME ]]; then
    echo "Please provide repo name"
    exit 1
fi
if [[ -z $BRANCH ]]; then
    echo "Please provide source branch"
    exit 1
fi

#end check

echo "clone_pull_repo $REPO_NAME $REPO_PATH $REPO_USER $BRANCH $FORCE_CLONE"
clone_pull_repo $REPO_NAME $REPO_PATH $REPO_USER $BRANCH $FORCE_CLONE
if [ $? -ne 0 ]; then
    echo "Branch $BRANCH not found"
    exit 3
fi

last_commit $BRANCH