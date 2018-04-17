module lsh.shell;

import core.stdc.stdlib : exit;
import lsh.builtin;
import lsh.util;
import std.process : Pid, spawnProcess, wait;
import std.stdio;
import std.string : cmp, split;

class Shell
{
    Builtins builtins;
    int previousStatus;

    this()
    {
        this.builtins = new Builtins();
        this.previousStatus = 0;
    }

    void loop()
    {
        while (true)
        {
            auto cwd = getcwd();
            writef("%s > ", cwd);
            auto line = readln();
            auto args = line.split();
            previousStatus = this.execute(args);
        }
    }

    int launch(string[] args)
    {
        Pid pid;
        try
        {
            pid = spawnProcess(args);
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
            return 1;
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
