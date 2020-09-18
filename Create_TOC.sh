# FIRST REMOVE THE TOC FORM THE README MANUALLY

cp /home/web_dev/github_personl_token_for_gh_md_toc/token.txt .
split -b 300KB README.md
rm -rf toc
mkdir toc
for f in x*; 
do 
cat $f | gh-md-toc - > toc/$f.toc 
done;
cat toc/*.toc > toc.md 
cp README.md README_copy.md
cat toc.md README_copy.md > README.md
rm README_copy.md toc.md token.txt xaa