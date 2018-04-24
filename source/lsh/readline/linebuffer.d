module lsh.readline.linebuffer;

import std.array : insertInPlace;
import std.utf;

class LineBuffer
{
    string buffer;
    size_t cap;
    size_t pos;  // Current cursor position.

    this(size_t cap)
    {
        this.cap = cap;
        this.buffer.reserve(cap);
        this.pos = 0;
    }

    void put(char c)
    {
        this.buffer ~= c;
        this.pos++;
    }

    void clear()
    {
        this.buffer = [];
        this.pos = 0;
    }

    size_t length() @property
    {
        return this.buffer.length;
    }

    bool insert(dchar c)
    {
        auto shift = c.codeLength!char();
        if (this.length + shift > cap)
            return false;

        auto push = this.pos == this.length;
        import std.stdio;
        if (push)
        {
            this.buffer ~= c;
            this.pos += shift;
        }
        else
        {
            writeln("*insert into buffer*");
            writeln("this.pos: ", this.pos);
            writeln("len: ", this.length);
            this.buffer.insertInPlace(this.pos, [c]);
            writeln("update position");
            this.pos += shift;
        }
        return true;
    }

    bool moveHome()
    {
        if (this.pos > 0)
        {
            this.pos = 0;
            return true;
        }
        else
        {
            return false;
        }
    }

    bool moveEnd()
    {
        if (this.pos == this.buffer.length)
        {
            return false;
        }
        else
        {
            this.pos = this.buffer.length;
            return true;
        }
    }
}
