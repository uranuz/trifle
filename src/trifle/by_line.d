module trifle.by_line;

struct ByLine(Range)
{
private:
	import std.range: ElementType;

	alias Char = ElementType!Range;
	alias ThisType = typeof(this);

	Range _source;
	Range _front;
	bool _isEmpty;

public:
	@disable this(this);

	this(Range src)
	{
		_source = src.save;
		popFront();
	}

	this(ref return scope inout(ThisType) rhs) inout
	{
		this._source = rhs._source.save;
		this._front = rhs_front.save;
		this._isEmpty = rhs._isEmpty;
	}

	auto front() @property {
		return _front.save;
	}

	void popFront()
	{
		if( _source.empty )
		{
			_isEmpty = true;
			return;
		}

		auto lineRange = _source.save;

		size_t sliceLen = 0;
		bool br = false;


		size_t indentCount;
		IndentStyle indentStyle;

		range_loop:
		while( !br && !_source.empty )
		{
			char_select:
			switch( _source.front )
			{
				case '\n', '\v', '\f', '\u0085':
				{
					_source.getLineIndent( indentCount, indentStyle );
					br = true;
					break;
				}
				case '\r':
				{
					auto tmp = _source.save;
					tmp.popFront();
					if( tmp.empty || tmp.front != '\n' )
					{
						_source.getLineIndent( indentCount, indentStyle );
						br = true;
					}
					else
						break char_select;
					break;
				}
				default:
					break;
			}


			_source.popFront();
			++sliceLen;
		}

		_front = lineRange[0 .. sliceLen];
		_front.indentCount = indentCount;
		_front.indentStyle = indentStyle;
		_front.isIndenting = false;
	}

	auto opSlice() {
		return this.save;
	}

	@property auto save() {
		return ThisType(this);
	}

	bool empty() {
		return _isEmpty;
	}
}

auto byLine(Range)(auto ref Range range) {
	return ByLine!Range(range.save);
}