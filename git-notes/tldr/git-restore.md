---
title: "[TLDR] Restore"
excerpt: "Un-stage or reset files back to their last committed state."
---

Restore changes in the working directory and index.

{% highlight bash %}
# Reset changes made in the working directory. Staged changes are left untouched
git restore <filepath>...
# Same as above
git restore [-W|--worktree] <filepath>...

# Unstage changes
git restore [-S|--staged] <filepath>...

# Reset both staged and working directory changes. This essentially removes all uncommitted changes.
git restore [-SW|--staged --worktree] <filepath>...


# By default `restore` will reset files back to their state at `HEAD`.

# Reset files to their state at `<ref>`.
git restore --source <ref> <filepath>...
{% endhighlight %}
