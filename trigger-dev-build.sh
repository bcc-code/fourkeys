  
# This script is made to quickly trigger new dev builds
# This currently only works for Linux/Mac

# Create a new custom tag and attach it to the last commit
DATE="dev_"$(date +%s%12N)
git tag $DATE HEAD

## Push the last commit and then the tag after that
git push
git push --tags