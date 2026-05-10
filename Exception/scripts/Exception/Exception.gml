/// @ignore [MAJOR.MINOR.PATCH]
#macro __GMLEXCEPTION_VERSION "2.0.0"
/// @ignore Show debug messages for library alerts (Default: true).
#macro __GMLEXCEPTION_ALERT true
/// @ignore Show debug messages for library errors (Default: true).
#macro __GMLEXCEPTION_ERROR true
/// @ignore Crash the game when there is a fatal library error (Default: true).
#macro __GMLEXCEPTION_STRICT_MODE true
/// @ignore Show a message box with the exception long message when an unhandled exception occurs. (Default: true)
#macro __GMLEXCEPTION_SHOW_MESSAGE true
/// @ignore Enable saving exception details to a file. This is required for the `SaveToFile` method and unhandled exception handler to work. (Default: true)
#macro __GMLEXCEPTION_SAVE_TO_FILE true

/// @ignore Store the static struct of the system exception to inherit from it in our custom Exception class.
globalvar __YYGMLException_static;

show_debug_message($"GMLException Alert:: version: {__GMLEXCEPTION_VERSION}. made by MusNik");
show_debug_message($"GMLException Alert:: Alert: {__GMLEXCEPTION_ALERT}, Error: {__GMLEXCEPTION_ERROR}, Strict Mode: {__GMLEXCEPTION_STRICT_MODE}, Show Message: {__GMLEXCEPTION_SHOW_MESSAGE}");

/// @ignore
/// @param {String} msg Message to show in the alert.
function __gmlexception_alert(_msg)
{
	if (__GMLEXCEPTION_ALERT) { show_debug_message($"GMLException Alert:: {_msg}"); }
}

/// @ignore
/// @param {String} msg Message to show in the error.
function __gmlexception_error(_msg)
{
	if (__GMLEXCEPTION_ERROR) { show_debug_message($"GMLException Error:: {_msg}"); }
	if (__GMLEXCEPTION_STRICT_MODE) 
	{
		show_error($"GMLException Fatal Error:: {_msg}", true);
	}
}

// Catch a system runtime exception to get its static struct.
// This should work on all platforms as show_error is implemented natively and will throw a YYGMLException that we can use as a template for our custom Exception class.
try
{
	show_error("test", false);
}
catch (exception)
{
	__YYGMLException_static = static_get(exception);
}

/// @description Base class for exceptions
/// @param {Struct} [native_ex] Optional struct from `unhandled_exception_handler`.
function Exception(_native_ex = undefined) constructor
{
	/// @ignore
	static __prefix = "Unable to find a handler for exception ";

	// inherit from system YYGMLException.
	static_set(self, __YYGMLException_static);
	
	// Internal flag to check the origin of the exception.
	var _is_from_unhandled = is_struct(_native_ex);
	
	// Variables
	message =		"";
	longMessage =	"";
	script =		"";
	line =			-1;
	/// @type {array<String>}
	stacktrace =	[];

	/// @type {array<Struct>}
	static snapshot =	[];
	/// @ignore Breadcrumb ring/list injected by user via future API.
	static breadcrumbs = [];

	// If the exception is created from the unhandled exception handler.
	if (_is_from_unhandled)
	{
		// Populate data directly from the native exception struct.
		message =		_native_ex.message;
		longMessage =	_native_ex.longMessage;
		script =		_native_ex.script;
		line =			_native_ex.line;

		// Prefer full live callstack; fallback to native stacktrace when unavailable.
		var _live_callstack = __parse_callstack(debug_get_callstack());
		stacktrace = (array_length(_live_callstack.stack) > 0) ? _live_callstack.stack : _native_ex.stacktrace;

		// Normalize native payload: keep only the short message line.
		longMessage = string_replace_all(longMessage, __prefix, "");
		if (string_pos(__prefix, message) == 1) { message = string_delete(message, 1, string_length(__prefix)); }

		var _cut = 0;
		var _lf = string_pos("\n", message);
		var _cr = string_pos("\r", message);
		var _dbl = string_pos("  ", message);
		if (_lf > 0) { _cut = _lf; }
		if (_cr > 0) { _cut = (_cut == 0) ? _cr : min(_cut, _cr); }
		if (_dbl > 0) { _cut = (_cut == 0) ? _dbl : min(_cut, _dbl); }
		if (_cut > 1) { message = string_copy(message, 1, _cut - 1); }
	}
	// If the exception is created manually with `new Exception()` or from a custom constructor.
	else
	{
		// TODO: Check callstack format on different target platfroms.
		var _parsed_callstack = __parse_callstack(debug_get_callstack(), 2);
		stacktrace = _parsed_callstack.stack;
		script = _parsed_callstack.script;
		line = _parsed_callstack.line;
	}

	// If the exception comes from an unhandled error, we don't need to call `init()`
	if (_is_from_unhandled) { static_set(self, static_get(Exception) ); }

	#region PRIVATE METHODS

	/// @ignore
	/// @desc Build a normalized stacktrace array from `debug_get_callstack()` entries.
	/// @param {array} stack The raw callstack from debug_get_callstack.
	/// @param {real} origin_index Optional index in the callstack that indicates the
	static __parse_callstack = function(_stack, _origin_index = -1)
	{
		var _result = {
			stack : [],
			script : "",
			line : -1
		};

		var i = 0; repeat(array_length(_stack))
		{
			var _entry = _stack[i];
			if (!is_string(_entry)) { i++; continue; }

			var _pos = string_pos(":", _entry);
			if (_pos <= 0) { i++; continue; }

			if (i == _origin_index)
			{
				_result.script = string_copy(_entry, 1, _pos - 1);
				_result.line = real(string_copy(_entry, _pos + 1, string_length(_entry) - _pos));
			}

			_entry = string_replace(_entry, ":", " (line ");
			_entry += ")";
			array_push(_result.stack, _entry);
			i++;
		}

		return _result;
	};

	/// @ignore
	/// @desc Resolve runtime environment metadata used by crash reports.
	/// @return {Struct}
	static __get_runtime_environment_info = function()
	{
		var _os_type_name = "Unknown";
		var _os_version_text = string(os_version);
		var _browser_name = "not_a_browser";
		switch (os_type)
		{
			case os_windows:	_os_type_name = "Windows"; break;
			case os_macosx:		_os_type_name = "macOS"; break;
			case os_ios:		_os_type_name = "iOS"; break;
			case os_android:	_os_type_name = "Android"; break;
			case os_linux:		_os_type_name = "Linux"; break;
			case os_ps4:		_os_type_name = "PS4"; break;
			case os_xboxone:	_os_type_name = "Xbox One"; break;
			case os_switch:		_os_type_name = "Switch"; break;
			case os_ps5:		_os_type_name = "PS5"; break;
			case os_tvos:		_os_type_name = "tvOS"; break;
		}

		// On Windows, os_version is packed as (major << 16) | minor.
		if (os_type == os_windows)
		{
			var _major = os_version div 65536;
			var _minor = os_version mod 65536;
			_os_version_text = $"{_major}.{_minor}";
		}

		// Build date normalize it for reporting.
		var _build_date_text = string(GM_build_date);
		if (is_real(GM_build_date) ) { _build_date_text = date_datetime_string(GM_build_date); }

		// If running in a browser environment, resolve the browser name.
		switch (os_browser)
		{
			case browser_not_a_browser:	_browser_name = "not_a_browser (non-browser target or GX.games)";	break;
			case browser_unknown:		_browser_name = "unknown";											break;
			case browser_ie:			_browser_name = "Internet Explorer";								break;
			case browser_ie_mobile:		_browser_name = "Internet Explorer Mobile";							break;
			case browser_edge:			_browser_name = "Edge";												break;
			case browser_firefox:		_browser_name = "Firefox";											break;
			case browser_chrome:		_browser_name = "Chrome";											break;
			case browser_safari:		_browser_name = "Safari";											break;
			case browser_safari_mobile:	_browser_name = "Safari Mobile";									break;
			case browser_opera:			_browser_name = "Opera";											break;
			case browser_tizen:			_browser_name = "Tizen";											break;
			case browser_windows_store:	_browser_name = "Windows Store";									break;
		}

		return {
			runtime_mode :		code_is_compiled() ? "YYC" : "VM",
			os_type_name :		_os_type_name,
			os_version :		_os_version_text,
			browser_name :		_browser_name,
			browser_id :		string(os_browser),
			game_version :		string(GM_version),
			runtime_version :	string(GM_runtime_version),
			build_type :		string(GM_build_type),
			build_date :		_build_date_text,
			release_mode :		string(gml_release_mode)
		};
	};

	/// @ignore
	/// @desc Build a short deterministic crash ID from the exception signature.
	/// @return {String}
	static __build_crash_id = function()
	{
		var _top_frame = (array_length(stacktrace) > 0) ? stacktrace[0] : "";
		var _sig = $"{message}|{script}|{line}|{_top_frame}";

		// Polynomial rolling hash (31-bit positive), then base36 short id.
		var _hash = 7;
		var _len = string_length(_sig);
		var i = 1; repeat(_len)
		{
			_hash = ((_hash * 131) + ord(string_char_at(_sig, i))) mod 2147483647;
			i++;
		}

		var _digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
		var _base36 = "";
		if (_hash <= 0) { _base36 = "0"; }
		else
		{
			var _n = _hash;
			repeat(8)
			{
				if (_n <= 0) { break; }
				var _r = _n mod 36;
				_base36 = string_char_at(_digits, _r + 1) + _base36;
				_n = _n div 36;
			}
		}

		// Left-pad to stable 8 chars.
		while (string_length(_base36) < 8) { _base36 = "0" + _base36; }

		return $"EX-{_base36}";
	};

	/// @ignore
	/// @desc Capture one snapshot entry. Structs/instances are tracked by weak ref.
	/// @param {Any} value
	static __snapshot_pack = function(_value)
	{
		var _entry = {
			kind : "value",
			value : _value,
			weak : undefined
		};

		if (is_struct(_value) || (is_real(_value) && instance_exists(_value)))
		{
			_entry.kind = "weakref";
			_entry.value = undefined;
			_entry.weak = weak_ref_create(_value);
		}

		return _entry;
	};

	/// @ignore
	/// @desc Convert runtime snapshot entries into a report-friendly array.
	/// @returns {array<Struct>}
	static __snapshot_to_report = function()
	{
		var _result = [];

		var i = 0; repeat(array_length(snapshot))
		{
			var _entry = snapshot[i++];
			if (!is_struct(_entry)) { continue; }

			if ((_entry.kind == "weakref") && is_struct(_entry.weak))
			{
				var _target = _entry.weak.ref;
				if (is_undefined(_target))
				{
					array_push(_result, {
						type : "weakref",
						alive : false,
						value : "<collected>"
					});
				}
				else
				{
					var _kind = instanceof(_target);
					var _report_entry = {
						type : "weakref",
						alive : true,
						target_kind : _kind,
						value : string(_target)
					};

					if (variable_struct_exists(_target, "object_index") && variable_struct_exists(_target, "id"))
					{
						_report_entry.object_name = object_get_name(_target.object_index);
						_report_entry.id = _target.id;
					}

					array_push(_result, _report_entry);
				}
			}
			else
			{
				array_push(_result, {
					type : "value",
					value : _entry.value
				});
			}
		}

		return _result;
	};

	/// @ignore
	/// @desc Build a normalized payload used by file writing and JSON fallback.
	/// @param {Real} dt Current datetime value.
	/// @param {Struct} env Runtime environment metadata.
	/// @param {String} crash_id Deterministic crash signature id.
	/// @returns {Struct}
	static __build_crash_payload = function(_dt, _env, _crash_id)
	{
		return {
			version : __GMLEXCEPTION_VERSION,
			crash_id : _crash_id,
			timestamp : date_datetime_string(_dt),
			environment : _env,
			short_message : message,
			long_message : longMessage,
			script : script,
			line : line,
			stacktrace : stacktrace,
			snapshot : __snapshot_to_report(),
			breadcrumbs : breadcrumbs
		};
	};

	/// @ignore
	static __write_header = function(_file, _payload)
	{
		file_text_write_string(_file, "========================================");
		file_text_writeln(_file);
		file_text_write_string(_file, "      GMLException Crash Report");
		file_text_writeln(_file);
		file_text_write_string(_file, "========================================");
		file_text_writeln(_file);
		file_text_write_string(_file, $"Crash ID: {_payload.crash_id}");
		file_text_writeln(_file);
		file_text_write_string(_file, $"Version: {_payload.version}");
		file_text_writeln(_file);
		file_text_write_string(_file, $"Timestamp: {_payload.timestamp}");
		file_text_writeln(_file);
	};

	/// @ignore
	static __write_environment = function(_file, _payload)
	{
		var _env = _payload.environment;
		file_text_write_string(_file, $"OS Type: {_env.os_type_name} ({os_type})");
		file_text_writeln(_file);
		file_text_write_string(_file, $"OS Version: {_env.os_version}");
		file_text_writeln(_file);
		file_text_write_string(_file, $"Browser: {_env.browser_name} ({_env.browser_id})");
		file_text_writeln(_file);
		file_text_write_string(_file, $"Runtime Mode: {_env.runtime_mode}");
		file_text_writeln(_file);
		file_text_write_string(_file, $"Game Version: {_env.game_version}");
		file_text_writeln(_file);
		file_text_write_string(_file, $"Runtime Version: {_env.runtime_version}");
		file_text_writeln(_file);
		file_text_write_string(_file, $"Build Type: {_env.build_type}");
		file_text_writeln(_file);
		file_text_write_string(_file, $"Build Date: {_env.build_date}");
		file_text_writeln(_file);
		file_text_write_string(_file, $"Release Mode: {_env.release_mode}");
		file_text_writeln(_file);
		file_text_writeln(_file);
	};

	/// @ignore
	static __write_snapshot = function(_file, _payload)
	{
		file_text_write_string(_file, "Snapshot:");
		file_text_writeln(_file);
		file_text_write_string(_file, "---------");
		file_text_writeln(_file);

		if (is_undefined(_payload.snapshot))
		{
			file_text_write_string(_file, "(not set)");
			file_text_writeln(_file);
		}
		else
		{
			file_text_write_string(_file, json_stringify(_payload.snapshot));
			file_text_writeln(_file);
		}

		file_text_writeln(_file);
	};

	/// @ignore
	static __write_breadcrumbs = function(_file, _payload)
	{
		file_text_write_string(_file, "Breadcrumbs:");
		file_text_writeln(_file);
		file_text_write_string(_file, "------------");
		file_text_writeln(_file);

		if (array_length(_payload.breadcrumbs) <= 0)
		{
			file_text_write_string(_file, "(none)");
			file_text_writeln(_file);
		}
		else
		{
			var i = 0; repeat(array_length(_payload.breadcrumbs))
			{
				file_text_write_string(_file, $"  - {_payload.breadcrumbs[i++]}");
				file_text_writeln(_file);
			}
		}

		file_text_writeln(_file);
	};

	/// @ignore
	static __write_messages = function(_file, _payload)
	{
		file_text_write_string(_file, "Short Message:");
		file_text_writeln(_file);
		file_text_write_string(_file, "--------------");
		file_text_writeln(_file);
		file_text_write_string(_file, _payload.short_message);
		file_text_writeln(_file);
		file_text_writeln(_file);

		file_text_write_string(_file, "Long Message / Formatted Output:");
		file_text_writeln(_file);
		file_text_write_string(_file, "--------------------------------");
		file_text_writeln(_file);
		file_text_write_string(_file, _payload.long_message);
		file_text_writeln(_file);
		file_text_writeln(_file);
	};

	/// @ignore
	static __write_stacktrace = function(_file, _payload)
	{
		file_text_write_string(_file, "Stacktrace:");
		file_text_writeln(_file);
		file_text_write_string(_file, "-----------");
		file_text_writeln(_file);

		var i = 0; repeat(array_length(_payload.stacktrace))
		{
			file_text_write_string(_file, $"  -> {_payload.stacktrace[i++]}");
			file_text_writeln(_file);
		}

		file_text_writeln(_file);
	};

	/// @ignore
	static __write_footer = function(_file, _payload)
	{
		file_text_write_string(_file, "========================================");
		file_text_writeln(_file);
		file_text_write_string(_file, "End of Report");
		file_text_writeln(_file);
	};

	#endregion

	#region PUBLIC METHODS
	
	/// @description Saves the exception information to an .exception file
	/// @returns {String} The name of the generated file or "" on failure.
	static SaveToFile = function()
	{
		var _dt = date_current_datetime();
		var _env = __get_runtime_environment_info();
		var _crash_id = __build_crash_id();

		var _datetime_str = date_datetime_string(_dt);
		_datetime_str = string_replace_all(_datetime_str, ":", "-");
		_datetime_str = string_replace_all(_datetime_str, "/", "-");
		var _filename = $"crash_{_datetime_str}.exception";
		var _payload = __build_crash_payload(_dt, _env, _crash_id);
		var _file = -1;

		try
		{
			_file = file_text_open_write(_filename);
			if (_file < 0) { throw $"Could not create exception file '{_filename}'"; }

			__write_header(_file, _payload);
			__write_environment(_file, _payload);
			__write_snapshot(_file, _payload);
			__write_breadcrumbs(_file, _payload);
			__write_messages(_file, _payload);
			__write_stacktrace(_file, _payload);
			__write_footer(_file, _payload);

			__gmlexception_alert($"Exception information saved to: '{_filename}'");
			return _filename;
		}
		catch (_save_ex)
		{
			__gmlexception_alert($"SaveToFile failed for '{_filename}'");

			var _fallback = {
				file : _filename,
				error : string(_save_ex),
				payload : _payload
			};

			try
			{
				__gmlexception_alert("GMLException Fallback Crash JSON::");
				__gmlexception_alert(json_stringify(_fallback));
			}
			catch (_json_ex)
			{
				__gmlexception_alert($"json_stringify fallback failed: {string(_json_ex)}");
			}

			return "";
		}
		finally
		{
			if (_file >= 0) { file_text_close(_file); }
		}
	}

	/// @description Captures one snapshot value for this exception.
	/// @param {Any} value Struct, instance id/self, or primitive value.
	/// @returns {Struct} Self, so calls can be chained before init().
	static Snapshot = function(_value)
	{
		array_push(snapshot, __snapshot_pack(_value));
		return self;
	}

	/// @description Adds a breadcrumb entry to the global rolling log. Call as `Exception.Breadcrum("...")`.
	/// @param {String} text
	static Breadcrumb = function(_text)
	{
		var _msg = string(_text);
		if (_msg == "") { return; }

		var _stamp = date_datetime_string(date_current_datetime());
		array_push(breadcrumbs, $"[{_stamp}] {_msg}");

		// Keep only the most recent breadcrumbs.
		while (array_length(breadcrumbs) > 20) { array_delete(breadcrumbs, 0, 1); }

		return self;
	}

	/// @description Clears breadcrumb history.
	static ClearBreadcrumbs = function()
	{
		breadcrumbs = [];
		return self;
	}
	
	/// @description Initializes the exception
	static init = function() 
	{
		var _name =		instanceof(self);
		var _short =	message;
		var _detail =	longMessage;
		message =		$"{_name}: {_short}";
		longMessage =	(_detail == _short) ? message : $"{message}\r\n{_detail}";

		// Add stacktrace details in YYC to better match VM diagnostics.
		if (code_is_compiled() && (array_length(stacktrace) > 0) )
		{
			longMessage += "\r\n\r\nStacktrace:";
			var i=0; repeat(array_length(stacktrace) ) { longMessage += "\r\n" + stacktrace[i++]; }
		}
		
		static_set(self, static_get(Exception) );
	}

	/// @description Sets up the global handler for uncaught exceptions.
	/// This should be called once during game initialization as `Exception.Handler()` to ensure all unhandled exceptions are caught and processed by our custom Exception class.
	static UnhandledHandler = function()
	{
		static __handler = function(ex)
		{
			// Preserve already-custom exceptions (including children) to keep their original message fields.
			var _custom_ex = is_instanceof(ex, Exception) ? ex : new Exception(ex);

			// Save the exception details to a file for later analysis
			if (__GMLEXCEPTION_SAVE_TO_FILE) { _custom_ex.SaveToFile(); }
			
			// Cleaner console output; full details remain in the crash report file.
			show_debug_message("--- UNHANDLED EXCEPTION CAUGHT ---");

			// -- Prepare messages for console and optional dialog --
			var _console_message = string_replace_all(string_replace_all(_custom_ex.message, "\r", " "), "\n", " ");
			var _long_ui = string_replace_all(_custom_ex.longMessage, "\r\n", "\n");
			var _long_console = string_replace_all(_long_ui, "\r", "");

			show_debug_message(_console_message);
			if (_long_console != _console_message) { show_debug_message($"Detail:\n{_long_console}"); }
			if ((_custom_ex.script != "") && (_custom_ex.line >= 0)) { show_debug_message($"Origin: {_custom_ex.script} (line {_custom_ex.line})"); }

			// Show stacktrace in console for unhandled exceptions to aid debugging.
			array_foreach(_custom_ex.stacktrace, function(line) {
				var _line = string_replace_all(string_replace_all(line, "\r", " "), "\n", " ");
				show_debug_message($"  -> {_line}");
			});

			// Show same content family as console: short summary + optional detail.
			if ((os_type == os_windows) && __GMLEXCEPTION_SHOW_MESSAGE)
			{
				var _dialog_message = _console_message;
				if (_long_ui != _custom_ex.message) { _dialog_message += "\n\n" + _long_ui; }

				show_message(_dialog_message);
			}

			show_debug_message("--- UNHANDLED EXCEPTION CAUGHT END ---");
			
			return 1;
		};
		
		exception_unhandled_handler(__handler);
	}

	/// @description Override for string representation of the exception.
	/// @return {String}
	static toString = function() 
	{
		return (longMessage);
	}
	
	#endregion

	__gmlexception_alert($"Creating Exception instance. Is from unhandled: {_is_from_unhandled}");
}

// This ensures the Exception constructor runs and its static methods are available.
script_execute(Exception);

/*	Example 1 Global constructor:
	/// @description Test exception
	function TestException() : Exception() constructor {
		message = "Throw a test exception.";
		longMessage = "Long\nMessage\nis\nhere";
	
		init();
	}
	new TestException();
/*

/*
	Example 2 Anonymous constructor:
	/// @description Test exception
	throw new (function(_msg) : Exception() constructor {
		message = _msg;
		longMessage = "Long\nMessage\nis\nhere";
	
		init();
	})("Test exception");
*/