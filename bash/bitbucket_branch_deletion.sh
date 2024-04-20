#!/bin/bash
# =============================================================================================================================
#
# Shell script to cleanup/delete branches matching a pattern across repositories in a given Bitbucket project
# ----------------------------------------------------------------------------------------------------------------
#
# Parameters to run this script
#
# 1. Provide the project key or name --> $PROJECT_KEY
# 2. Provide your organisation's bitbucket base url --> $BASE_URL
# 3. Provide either the username or id or email address --> $USERNAME
# 4. Provide either the password or api token to authenticate --> $TOKEN
# 5. Provide the path of working directory --> $GIT_WORK_DIR
# 6. Provide the branch pattern that you would like to cleanup/delete --> $BRANCH_PATTERN
# =============================================================================================================================


# !!! ---------- IMPORTANT ---------- !!!
#
# To avoid any unintended deletion of branches, the script is set to run in READ_ONLY_MODE by default.
#
# READ_ONLY_MODE will return the list of branches matching the given pattern, but not delete them.
#
# Run the script in READ_ONLY_MODE first, know the branches matching the pattern and then proceed to delete the branches.
#
# To delete the branches, set the flag READ_ONLY_MODE to NO.


# Update the flag to NO to delete the branches
READ_ONLY_MODE="YES"

$PROJECT_KEY="<Bitbucket project key or name>" #Eg: project1234 or mybbproject
$BASE_URL="<Your org's bitbucket base url>" #Eg: https://myorg.bitbucket.com

$USERNAME="<Your bitbucket user id or username or email address>"
$TOKEN="<Password or api token to authenticate>" # API token is recommended as it takes away the issue of frequent password resets

$GIT_WORK_DIR="/var/temp/bitbucket_cleanup"
$BRANCH_PATTERN="release/rel123.*"


if [ $READ_ONLY_MODE = "YES"]; then
    echo -e "\nScript is running in READ ONLY mode. It lists all the branches matching the pattern.\n\n"
elif [ $READ_ONLY_MODE = "NO"]; then
    echo -e "\nScript is set to run in DELETE mode. All the pattern matching branches would be deleted.\n\n"
else
    echo -e "\nREAD_ONLY_MODE flag accepts only YES or NO values."
    echo "Flag is set a value other than YES or NO."
    echo -e "Script exiting here.\n"
fi

# Curl command to fetch list of repositories for a given Bitbucket project
REPOLIST=`curl -s -k --request GET --user "$USERNAME:$TOKEN" "$BASE_URL/rest/api/1.0/projects/$PROJECT_KEY/repos?limit=1000" | jq -r '.values[].name' | sed 's/"//g'`


if [ -z "$REPOLIST"]; then
    echo "List is null. Script did not return any repositories to operate against."
    echo "Please check all the parameters are correct and run the script again."
    echo "Bye...."
else
    for REPO in $REPOLIST; do
        # case statement to exclude important repositories from branch cleanup
        case $REPO in
            'my-pet-repo' | 'imp-repo')
                echo "---------------------------------------------------------------------------------------------------"
                echo -e "Skipping repository [$REPO]"
                echo -e "---------------------------------------------------------------------------------------------------\n\n"
                ;;
            *)
                echo "---------------------------------------------------------------------------------------------------"
                if [ -d $GIT_WORK_DIR ]; then
                    echo "Repo [$REPO] is already cloned"
                else
                    cd $GIT_WORK_DIR
                    echo -e "Cloning repo [$REPO]\n"
                    git clone ssh://git@[SSH-Clone-URL]/$PROJECT_KEY/$REPO
                fi

                echo ""

                if [ -d "$GIT_WORK_DIR/$REPO" ]; then
                    echo -e "Start clean up of repository [$REPO]\n"
                    cd $GIT_WORK_DIR/$REPO
                    git fetch
                    echo ""

                    # Finding all branches matching the given pattern
                    BRANCH_CLEANUP_LIST=$(git branch -r | grep $BRANCH_PATTERN)

                    # Check if branchlist variable is empty
                    if [ -z $BRANCH_CLEANUP_LIST]; then
                        echo "No branches found matching the pattern [$BRANCH_PATTERN] in the repo [$REPO]"
                        echo -e "---------------------------------------------------------------------------------------------------\n\n"
                    else
                        echo -e "Branches matching the give npattern [$BRANCH_PATTERN] are below...\n"
                        for B in $BRANCH_CLEANUP_LIST; do
                            if [ $READ_ONLY_MODE = "YES" ]; then
                                echo "$B"
                            elif [ $READ_ONLY_MODE = "NO" ]; then
                                BRANCH=$(echo $B | sed -e "s/origin\///")
                                echo "Branch [$BRANCH] from the repo [$REPO] is marked for deletion"
                                # git push origin --delete $BRANCH
                                # echo -e "\nBranch [$BRANCH] is deleted from the repo [$REPO]"
                            else
                                echo ""
                            fi
                        done
                        echo -e "---------------------------------------------------------------------------------------------------\n\n"
                    fi
                else
                    echo "Either the [$REPO] is not cloned properly of the directory path is not available"
                    echo "Could not cleanup branches for the repo [$REPO]"
                    echo -e "---------------------------------------------------------------------------------------------------\n\n"
                fi
                ;;
        esac
    done
fi
