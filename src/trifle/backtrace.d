module trifle.backtrace;

string[] getBacktrace(Throwable ex)
{
	import std.conv: to;
	import core.exception: OutOfMemoryError;
	import std.exception: enforce;
	if( ex is null )
		return null;

	string[] backTrace;
	try
	{
		if( ex.info is null )
			return null;

		foreach( inf; ex.info )
			backTrace ~= inf.to!string;
	}
	catch( OutOfMemoryError exc ) {} // Workaround for some bug in DefaultTraceInfo.opApply
	return backTrace;
}