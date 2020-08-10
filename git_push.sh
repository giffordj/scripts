# Change this to your git_repos folder if it is different
cd ~/git_repos/scripts

# Add all files to the repository with respect to .gitignore rules
git add .

# Commit changes with message with current date stamp
git commit -m "Updated on `date +'%d-%m-%Y %H:%M:%S:'`"

# Push changes towards GitHub
git push -u origin master
