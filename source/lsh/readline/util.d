module lsh.readline.util;

enum AnsiState
{
    Norm,
    Esc,
    Csi,
    Osc,
}

R[] removeCodes(R : char)(R[] input)
{
    import std.algorithm : canFind;
    import std.array : appender;

    if (input.canFind("\x1B"))
    {
        auto clean = appender!(R[])();
        AnsiState s = AnsiState.Norm;
        foreach (c; input)
        {
            final switch (s)
            {
            case AnsiState.Norm:
                if (c == '\x1B')
                {
                    s = AnsiState.Esc;
                }
                else
                {
                    clean.put(c);
                }
                break;
            case AnsiState.Esc:
                switch (c)
                {
                case '[':
                    s = AnsiState.Csi;
                    break;
                case ']':
                    s = AnsiState.Osc;
                    break;
                default:
                    s = AnsiState.Norm;
                    break;
                }
                break;
            case AnsiState.Csi:
                switch (c)
                {
                case 'A': .. case 'Z':
                case 'a': .. case 'z':
                    s = AnsiState.Norm;
                    break;
                default:
                    break;
                }
                break;
            case AnsiState.Osc:
                if (c == '\x07')
                    s = AnsiState.Norm;
                break;
            }
        }
        return clean.data;
    }
    else
    {
        return input;
    }
}

size_t width(R : char)(R[] input)
{
    import std.range : walkLength;
    return removeCodes(input).walkLength;
}
