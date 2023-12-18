---
title: "[TLDR] Revert"
excerpt: "Make a new commits that undo the work of previous commits"
---

Make a new commits that undo the work of previous commits

{% highlight bash %}
# Create a new commit that reverts the work of one or more commits.
git revert <commit>...

# Skip the commit message editing
git revert --no-edit

# Perform the revert but stop before creating a commit. Essentially applying all the revert work to your index.
git revert [-n|--no-commit]
{% endhighlight %}
