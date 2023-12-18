---
title: Restore
excerpt: "Un-stage or reset files back to their last committed state."
tldr: True
---

Un-stage or reset files back to their last committed state. Replacement for `git reset`.

You can restore the index and the working directory individually or together.

To restore the working directory to the state that the index is in use.

{% highlight bash %}
git restore <filepath>...
# Same as above
git restore --worktree <filepath>...
# Same as aboe
git restore -W <filepath>...
{% endhighlight %}

This essentially restores the given file paths to their last staged state. Note, the above commands will have no effect if you don't have any un-staged changes.

To restore the index to what `HEAD` is use.

{% highlight bash %}
git restore --staged <filepath>...
# Same as above
git restore -S <filepath>...
{% endhighlight %}

Essentially this un-stages the given file paths, but leaves their contents untouched.

To completely discard all your changes and reset back to `HEAD`, combine the above two options together.

{% highlight bash %}
git restore --staged --worktree <filepath>...
# Same as above
git restore -SW <filepath>...
{% endhighlight %}

By default, restore will use HEAD as the source to restore files to. You can specify a different git reference with the `source` option.

{% highlight bash %}
git restore --source <ref> <filepath>...
{% endhighlight %}

`ref` can be a commit hash, branch name or any other git reference.
