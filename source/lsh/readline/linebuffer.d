module lsh.readline.linebuffer;

import std.array : insertInPlace, replaceInPlace;
import std.uni : graphemeStride;

class LineBuffer
{
    string buffer;
    size_t pos;  // Current cursor position.

    this(size_t capacity)
    {
        this.buffer.reserve(capacity);
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
        if (this.length + shift > this.buffer.capacity)
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

    size_t nextPos()
    {
        if (this.pos == this.buffer.length)
            return this.pos;
        return this.pos + graphemeStride(this.buffer, this.pos);
    }

    size_t prevPos()
    {
        if (this.pos == 0)
            return 0;

        size_t prev = 0;
        size_t next = 0;
        while (true)
        {
            next += graphemeStride(this.buffer, prev);
            if (next >= this.pos)
                break;
            prev += next;
        }
        return prev;
    }

    bool backspace()
    {
        if (this.pos > 0 && this.buffer.length > 0)
        {
            auto oldPos = this.pos;
            auto pos = this.prevPos();
            this.buffer.replaceInPlace(pos, oldPos, cast(char[]) []);
            this.pos = pos;
            return true;
        }
        return false;
    }

    bool editDelete()
    {
        if (this.buffer.length > 0 && this.pos < this.buffer.length)
        {
            auto cursorLen = this.nextPos();
            this.buffer.replaceInPlace(this.pos, cursorLen, cast(char[]) []);
            return true;
        }
        return false;
    }

    bool moveLeft()
    {
        if (this.pos > 0)
        {
            this.pos = prevPos();
            return true;
        }
        return false;
    }

    bool moveRight()
    {
        if (this.pos != this.buffer.length)
        {
            this.pos = nextPos();
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
