/**
Write a shell in C.  https://brennan.io/2015/01/16/write-a-shell-in-c/
*/
import std.file : chdir;
import std.stdio;
import std.string : cmp, split;


int builtinCd(string[] args)
{
    if (args.length < 2)
    {
        stderr.writeln(`lsh: expected argument to "cd"`);
    }
    else
    {
        chdir(args[1]);
    }
    return 1;
}

int builtinHelp(string[] args)
{
    stdout.writeln(`
This is D port of Stephen Brennan's LSH.
Type program names and arguments, and hit enter.
Use the man command for information on other programs.
`);
    return 1;
}

int builtinExit(string[] args)
{
    return 0;
}

class Builtins
{
    // Builtins should A-Z order.
    int function(string[])[string] builtinMap;

    this()
    {
        this.builtinMap = [
            "cd": &builtinCd,
            "exit": &builtinExit,
            "help": &builtinHelp,
            ];
    }

    string[] keys()
    {
        return this.builtinMap.keys();
    }

    int function(string[]) get(string builtin)
    {
        return this.builtinMap[builtin];
    }
}

class Lsh
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
}

void main()
{
    auto lsh = new Lsh;
    lsh.loop();
}
