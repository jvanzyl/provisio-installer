# Shell Init Files

## Bash Startup Files

When invoked as an interactive login shell, Bash looks for the /etc/profile file, and if the file exists , it runs the commands listed in the file. Then Bash searches for ~/.bash_profile, ~/.bash_login, and ~/.profile files, in the listed order, and executes commands from the first readable file found.

When Bash is invoked as an interactive non-login shell, it reads and executes commands from ~/.bashrc, if that file exists, and it is readable.

## Difference Between .bashrc and .bash_profile

`.bash_profile` is read and executed when Bash is invoked as an interactive login shell, while `.bashrc` is executed for an interactive non-login shell.

Use `.bash_profile` to run commands that should run only once, such as customizing the `$PATH` environment variable .

Put the commands that should run every time you launch a new shell in the `.bashrc file`. This include your aliases and functions , custom prompts, history customizations , and so on.

Typically, `~/.bash_profile` contains lines like below that source the `.bashrc` file. This means each time you log in to the terminal, both files are read and executed.

```
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
```

Most Linux distributions are using `~/.profile` instead of `~/.bash_profile`. The `~/.profile` file is read by all shells, while `~/.bash_profile` only by Bash.

If any startup file is not present on your system, you can create it.

A useful references for how bash/zsh works can be found [here][1] and [here][2].

[1]: https://medium.com/@rajsek/zsh-bash-startup-files-loading-order-bashrc-zshrc-etc-e30045652f2e

[2]: https://unix.stackexchange.com/questions/71253/what-should-shouldnt-go-in-zshenv-zshrc-zlogin-zprofile-zlogout
