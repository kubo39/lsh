module lsh.shell;

import lsh.builtin;

import std.stdio;
import std.string : cmp, split;

class Shell
{
    Builtins builtins;

    this()
    {
        this.builtins = new Builtins();
    }

    void loop()
    {
        int status;
        do
        {
            write("> ");
            auto line = readln();
            auto args = line.split();
            status = this.execute(args);
        }
        while (status);
    }

    void launch(string[] args)
    {
        import std.process : spawnProcess, wait;
        auto pid = spawnProcess(args);
        scope(exit) wait(pid);
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
                return (*this.builtins.get(builtin))(args);
            }
        }
        this.launch(args);
        return 1;
    }

    void displayVersion()
    {
        stdout.writeln("lsh/0.0.1");
    }
}
