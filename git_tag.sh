
# I have the habit of creating in each git workspace a local tag 'local/props'
# with my local modification. So I can use this command to quickly load all
# my private settings
# gtool gt-load-local-properties: Load my local properties
alias gt-load-local-properties='git cherry-pick local/props && git reset HEAD~1'

# gtool gt-save-local-properties: Save my local properties
function gt-save-local-properties()
{
    git cherry-pick local/props
}

# gtool gt-bkp: Generate a backup tag
function gt-bkp()
{
    tag_sufix=$1
    bkp_tag=bkp-$(date +%F)${tag_sufix}
    echo "Generating git tag BKP: "$bkp_tag
    git tag $bkp_tag
}

# gtool gt-list-bkp: List backup tags
function gt-tags-bkp()
{
    git tag -l 'bkp-*' -n1
}

# gtool gt-tags: List all tags
function gt-tags()
{
    git tag -l -n1
}

# gtool gt-tags-by-date: List all tags ordered by date
function gt-tags-by-date()
{
    git for-each-ref --sort=creatordate --format '%(refname) %(creatordate)' refs/tags | cut -c11-
}