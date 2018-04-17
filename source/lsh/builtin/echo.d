module lsh.builtin.echo;

import lsh.shell : Shell;
import std.algorithm : startsWith;
import std.stdio : stdout;
import std.typecons : BitFlags;

enum EchoFlags
{
    ESCAPE = 1,
    NO_NEWLINE = 1 << 1,
}

alias Flags = BitFlags!EchoFlags;

int builtinEcho(string[] args, Shell shell)
{
    import std.array : appender;
    auto data = appender!(string[]);
    Flags flags;
    foreach (arg; args)
    {
        if (arg.startsWith('-'))
        {
            bool isOption = true;
            Flags shortFlags;

            foreach (argOpt; arg[1..$])
            {
                if (argOpt == 'e')
                    shortFlags |= EchoFlags.ESCAPE;
                else if (argOpt == 'n')
                    shortFlags |= EchoFlags.NO_NEWLINE;
                else
                {
                    isOption = false;
                    break;
                }
            }
            if (isOption)
                flags |= shortFlags;
            else
                data.put(arg);
        }
        else
        {
            data.put(arg);
        }
    }

    auto buffer = stdout.lockingTextWriter();
    bool first = true;
    foreach (arg; data.data[1..$])
    {
        if (flags && EchoFlags.ESCAPE)
        {
            bool check = false;
            foreach (c; arg)
            {
                switch (c)
                {
                case '\\':
                    if (check)
                    {
                        buffer.put(c);
                        check = false;
                    }
                    else
                        check = true;
                    break;
                case 'a':
                    if (check)
                    {
                        buffer.put(char(7)); // bell.
                        check = false;
                        break;
                    }
                    goto default;
                case 'b':
                    if (check)
                    {
                        buffer.put(char(8)); // backspace.
                        check = false;
                        break;
                    }
                    goto default;
                case 'c':
                    if (check)
                    {
                        stdout.flush();
                        return 0;
                    }
                    goto default;
                case 'e':
                    if (check)
                    {
                        buffer.put(char(27)); // escape.
                        check = false;
                        break;
                    }
                    goto default;
                case 'f':
                    if (check)
                    {
                        buffer.put(char(12)); // form feed.
                        check = false;
                        break;
                    }
                    goto default;
                case 'n':
                    if (check)
                    {
                        buffer.put('\n'); // newline.
                        check = false;
                        break;
                    }
                    goto default;
                case 'r':
                    if (check)
                    {
                        buffer.put('\r');
                        check = false;
                        break;
                    }
                    goto default;
                case 't':
                    if (check)
                    {
                        buffer.put('\t');
                        check = false;
                        break;
                    }
                    goto default;
                case 'v':
                    if (check)
                    {
                        buffer.put(char(11)); // vertival tab.
                        check = false;
                        break;
                    }
                    goto default;
                default:
                    if (check)
                        buffer.put(['\\', c]);
                    else
                        buffer.put(c);
                    break;
                }
            }
        }
        else
            buffer.put(arg);
    }
    if (!(flags && EchoFlags.NO_NEWLINE))
        buffer.put("\n");
    stdout.flush();
    return 0;
}
