#!/usr/bin/env bash

# Generate a CSV file with the date of the last commit to each tutorial in it.
#
# Whenever importing tutorials into production you'll need to make sure that
# this script gets run first.
#
# See https://github.com/DrupalizeMe/dmesite/issues/5006

echo "Generate CSV file with date of last commit to tutorial files ...";
rm -f tutorial-changed-dates.csv
git ls-files -- content/ |
while read file; do
  timestamp=$(git log --pretty=format:%ct -1 -- "$file");
  f=`echo "gatsbyguides.com:/$file"`;
  #echo "$f,$timestamp";
  echo "$f,$timestamp" >> tutorial-changed-dates.csv;
done
echo "Done! Output saved to tutorial-changed-dates.csv"
