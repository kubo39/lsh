module lsh.readline.linebuffer;

import std.array : array, insertInPlace, replaceInPlace;
import std.range : enumerate, retro, take, takeOne, walkLength;
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

    void clear()
    {
        this.buffer = [];
        this.pos = 0;
    }

    size_t length() @property
    {
        return this.buffer.length;
    }

    bool insert(string c)
    {
        auto shift = c.length;
        if (this.length + shift > cap)
            return false;

        if (this.pos == this.length)
        {
            this.buffer ~= c;
            this.pos += shift;
        }
        else
        {
            this.buffer.insertInPlace(this.pos, c);
            this.pos += shift;
        }
        return true;
    }

    size_t prevPos()
    {
        import std.uni;
        if (this.pos == 0)
            return 0;
        return this.buffer
            .take(this.pos)
            .byGrapheme()
            .enumerate()
            .array()
            .retro()
            .takeOne()[0][0];
    }

    bool backspace()
    {
        if (this.pos > 0 && this.buffer.length > 0)
        {
            auto oldPos = this.pos;
            auto pos = prevPos();
            this.buffer.replaceInPlace(pos, oldPos, cast(char[]) []);
            this.pos = pos;
            return true;
        }
        return false;
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
