module trifle.utils;

// Formats args into string without delimiter
string aformat(A...)(lazy A args)
{
	import std.format: formattedWrite;
	import std.array: appender;
	auto res = appender!string();
	foreach(item; args) {
		formattedWrite!"%s"(res, item);
	}

	return res[];
}

/// Tests assertion. If it's false then writes internal error to log and throws ExceptionType
template ensure(E : Throwable = Exception)
{
	import std.exception: enforce;
	alias enf = enforce!E;
	
	void ensure(C, A...) (C cond, lazy A args, string file = __FILE__, size_t line = __LINE__ ) {
		enf(cond, aformat(args), file, line);
	}
}