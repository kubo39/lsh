module lsh.readline;

import core.stdc.stdio : getchar;
import core.sys.posix.sys.ioctl;
import lsh.readline.linebuffer;
import lsh.readline.terminal;
import lsh.readline.util : width;
import std.array;
import std.format : format;
import std.stdio; // write

enum KEY_ACTION
{
    KEY_NULL = 0,
    CTRL_A = 1,
    CTRL_B = 2,
    CTRL_C = 3,
    CTRL_D = 4,
    CTRL_E = 5,
    CTRL_F = 6,
    CTRL_H = 8,
    TAB    = 9,
    CTRL_K = 11,
    CTRL_L = 12,
    ENTER  = 13,
    CTRL_N = 14,
    CTRL_P = 16,
    CTRL_T = 20,
    CTRL_U = 21,
    CTRL_W = 23,
    ESC     = 27,
    BACKSPACE =  127,
}

int[2] getWindowSize()
{
    auto size = winsize();
    if (ioctl(stdout.fileno(), TIOCGWINSZ, &size) == -1 || size.ws_col == 0)
    {
        return [80, 24];
    }
    else
    {
        return [size.ws_col, size.ws_row];
    }
}

int getColumns(int infd, int outfd)
{
    return getWindowSize()[0];
}

class State
{
    LineBuffer line;
    string prompt;
    size_t oldpos;
    int cols;
    size_t maxrows;

    this(string prompt)
    {
        this.line = new LineBuffer(80);
        this.prompt = prompt;
        this.oldpos = 0;
        this.cols = getColumns(stdin.fileno(), stdout.fileno());
        this.maxrows = 0;
    }
}

void clearScreen()
{
    write("\x1b[H\x1b[2J");
}

void refreshLine(State state)
{
    auto plen = width(state.prompt);
    auto pos = state.line.pos;

    auto ab = appender!string();

    // clear old rows and line.
    ab.put("\r");
    // display the prompt.
    ab.put(state.prompt);
    // and buffer.
    ab.put(state.line.buffer);
    // Erase to right.
    ab.put("\x1b[0K");
    // move cursor to original position.
    ab.put(format("\r\x1b[%dC", pos+plen));

    // write and flush.
    write(ab.data);
    stdout.flush();
}

void editInsert(State state, string c)
{
    if (state.line.insert(c))
        refreshLine(state);
}

void editBackspace(State state)
{
    if (state.line.backspace())
        refreshLine(state);
}

void editDelete(State state)
{
    if (state.line.length > 0 && state.line.pos < state.line.length)
    {
        state.line.buffer.replaceInPlace(state.line.pos, state.line.pos+1, cast(char[]) []);
        refreshLine(state);
    }
}

void editDeletePrevWord(State state)
{
    size_t oldpos = state.line.pos;
    while (state.line.pos != 0 && state.line.buffer[state.line.pos-1] == ' ')
        state.line.pos--;
    while (state.line.pos != 0 && state.line.buffer[state.line.pos-1] != ' ')
        state.line.pos--;
    size_t diff = oldpos - state.line.pos;
    state.line.buffer.replaceInPlace(state.line.pos, oldpos, cast(char[]) []);
    refreshLine(state);
}

void moveLeft(State state)
{
    if (state.line.pos > 0)
    {
        state.line.pos--;
        refreshLine(state);
    }
}

void moveRight(State state)
{
    if (state.line.pos != state.line.length)
    {
        state.line.pos++;
        refreshLine(state);
    }
}

void moveHome(State state)
{
    if (state.line.moveHome())
        refreshLine(state);
}

void moveEnd(State state)
{
    if (state.line.moveEnd())
        refreshLine(state);
}

char[] readUnicodeCharacter()
{
    char[] tmp;

    char c;
    stdin.readf!"%c"(c);
    if (c <= 0b01111111)  // short circuit ASCII.
    {
        tmp ~= c;
        return tmp;
    }
    else if (c <= 0b11011111)
    {
        tmp ~= c;
        tmp ~= char.init;
        stdin.readf!"%c"(tmp[1]);
        return tmp;
    }
    else if (c <= 0b11101111)
    {
        tmp ~= c;
        tmp ~= char.init;
        stdin.readf!"%c"(tmp[1]);
        tmp ~= char.init;
        stdin.readf!"%c"(tmp[2]);
        return tmp;
    }
    else if (c <= 0b11110111)
    {
        tmp ~= c;
        stdin.readf!"%c"(tmp[1]);
        tmp ~= char.init;
        stdin.readf!"%c"(tmp[2]);
        tmp ~= char.init;
        stdin.readf!"%c"(tmp[3]);
        return tmp;
    }
    else if (c <= 0b11111011)
    {
        tmp ~= c;
        tmp ~= char.init;
        stdin.readf!"%c"(tmp[1]);
        tmp ~= char.init;
        stdin.readf!"%c"(tmp[2]);
        tmp ~= char.init;
        stdin.readf!"%c"(tmp[3]);
        tmp ~= char.init;
        stdin.readf!"%c"(tmp[4]);
        return tmp;
    }
    else assert(false);
}

string readlineEdit(string prompt)
{
    auto state = new State(prompt);
    write(prompt);

    while (true)
    {
        char[] chars = readUnicodeCharacter();
        switch (chars[0])
        {
        case KEY_ACTION.ENTER:
            return state.line.buffer;
        case KEY_ACTION.CTRL_C:
            return ['^', 'C'];
        case KEY_ACTION.BACKSPACE:
        case KEY_ACTION.CTRL_H:
            editBackspace(state);
            break;
        case KEY_ACTION.CTRL_D:
            if (state.line.length > 0)
            {
                editDelete(state);
                break;
            }
            return null;
        case KEY_ACTION.CTRL_T:
            break;
        case KEY_ACTION.CTRL_B:
            moveLeft(state);
            break;
        case KEY_ACTION.CTRL_F:
            moveRight(state);
            break;
        case KEY_ACTION.CTRL_P:
        case KEY_ACTION.CTRL_N:
        case KEY_ACTION.ESC:
            break;
        default:
            editInsert(state, cast(immutable) chars);
            break;
        case KEY_ACTION.CTRL_U:
            state.line.clear();
            refreshLine(state);
            break;
        case KEY_ACTION.CTRL_K:
            state.line.buffer = state.line.buffer[0 .. state.line.pos];
            refreshLine(state);
            break;
        case KEY_ACTION.CTRL_A:
            moveHome(state);
            break;
        case KEY_ACTION.CTRL_E:
            moveEnd(state);
            break;
        case KEY_ACTION.CTRL_L:
            clearScreen();
            refreshLine(state);
            break;
        case KEY_ACTION.CTRL_W:
            editDeletePrevWord(state);
            break;
        }
    }
    assert(false);
}

string readlineRaw(string prompt)
{
    auto term = new Terminal;
    if (!term.enableRawMode())
        return null;
    auto s = cast(immutable) readlineEdit(prompt);
    term.disableRawMode();
    writeln();
    return s;
}

string readline(string prompt)
{
    return readlineRaw(prompt);
}
