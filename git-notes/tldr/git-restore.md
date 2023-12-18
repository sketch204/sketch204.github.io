---
---

# [TLDR] Restore

{% highlight bash %}
# Restore all changes made in the working directory. Staged changes are left untouched
git restore <filepath>...
# Same as above
git restore [-W|--worktree] <filepath>...

# Same as above, but only restore staged changed instead of changes in the working directory.
git restore [-S|--staged] <filepath>...

# Restore changes in both staged and working directory changes. This essentially removes all uncommitted changes.
git restore [-SW|--staged --worktree] <filepath>...

# Restore files to a different point in time, specifically whatever is referenced by <ref>. By default HEAD is used.
git restore --source <ref> <filepath>...
{% endhighlight %}
