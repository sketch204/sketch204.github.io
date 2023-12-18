---
title: Revert
excerpt: "Make a new commits that undo the work of previous commits"
tldr: True
---

Use `git revert` to undo the work of previous commits.

Let's assume that you've done some work on your repository and your commit history looks something like this.

{% highlight bash %}
$ git shortlog
Inal Gotov (215):
	Fix a bug
	Introduce brand new feature
	Change button color
	Clean up codebase
...
{% endhighlight %}

Some times ago you changed a button color as is shown by the third last commit in our history. Now let's imagine your boss comes over and says they don't like the new color and want it changed back.

The naive solution is go into the code, find the button and reset its color back to what it was. Assuming you made the change fairly recently it should be quite trivial. However if the change was done a while ago, or was done by someone else, getting all the details right might prove difficult.

Instead of going into the code, you could make use of `git revert`. All you'd need to do in this case is run:

{% highlight bash %}
git revert HEAD~2
{% endhighlight %}

`HEAD~2` in this case refers to the second last commit from `HEAD` ("Change button color"). `git revert` will take that commit, revert all of its changes and make a new commit from that. Before committing it will open a commit message editor for you to review and edit. The default message should be in the format `Revert "<original_message>"`. You can leave it as is or edit it to make it easier to read or add more context.

With this one command you've potentially saved yourself quite a bit of work.

{% aside tip %}
You can specify more than one reference if you want to revert more than one commit.
{% endaside %}

### Options

There are a couple useful options for `git revert`. The first is the `--no-edit` option which skips the commit message editor. Use this when you want to use the default commit message.

Another quite useful option is `-n` or `--no-commit`. This will do all the work of `git revert` and leave those changes staged in your index. So it is equivalent to the normal `git revert` except it doesn't automatically commit the changes. This is useful when you're reverting multiple commits and want to review the changes before committing.
