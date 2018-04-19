module lsh.shell;

import core.stdc.stdlib : exit;
import lsh.builtin;
import lsh.colors;
import lsh.readline;
import lsh.util;
import std.format : format;
import std.process : Pid, spawnProcess, wait;
import std.stdio;
import std.string : cmp, split;

alias PromptFn = string function(int);

class Shell
{
private:
    PromptFn prompt;

public:
    Builtins builtins;
    int previousStatus;

    this()
    {
        this.builtins = new Builtins();
        this.previousStatus = 0;
        this.prompt = (int status) => status == 0
            ? format("\033[%sm%s > \033[%sm", COLORS["green"], getcwd(), COLORS["white"])
            : format("\033[%sm%s > \033[%sm", COLORS["red"], getcwd(), COLORS["white"]);
    }

    void setPrompt(PromptFn prompt)
    {
        this.prompt = prompt;
    }

    void loop()
    {
        string line;
        while ((line = readline(this.prompt(this.previousStatus))) !is null)
        {
            auto args = split(line);
            this.previousStatus = this.execute(args);
        }
    }

    int launch(string[] args)
    {
        try
        {
            Pid pid = spawnProcess(args);
            return wait(pid);
        }
        catch (Exception e)
        {
            return 1;
        }
    }

    int execute(string[] args)
    {
        if (args.length < 1)
        {
            return 0;
        }

        foreach (builtin; this.builtins.keys())
        {
            if (cmp(args[0], builtin) == 0)
            {
                return (*this.builtins.get(builtin))(args, this);
            }
        }
        return this.launch(args);
    }

    void exit(int status)
    {
        .exit(status);
    }

    void displayVersion()
    {
        stdout.writeln("lsh/0.0.1");
        exit(0);
    }
}
