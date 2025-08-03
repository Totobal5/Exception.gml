/// @ignore
#macro  __GMLEXCEPTION_VERSION "1.0"
show_debug_message($"GMLException version: {__GMLEXCEPTION_VERSION}");
/// @ignore
globalvar __YYGMLException_static;

// catch a system runtime exception to get its static struct
try 
{
    show_error("test", false);
} 
catch (exception) 
{
    __YYGMLException_static = static_get(exception);
}

/*
    /// @description                            Test exception
    function TestException() : Exception() constructor {
        message = "Throw a test exception.";
        longMessage = "Long\nMessage\nis\nhere";
    
        init();
    }
*/
/// @description    Base class for exceptions
/// @param {Struct} [_native_ex] Optional struct from unhandled_exception_handler.
function Exception(_native_ex = undefined) constructor
{
    // inherit from system YYGMLException.
    static_set(self, __YYGMLException_static);
    
    // Internal flag to check the origin of the exception
    var _is_from_unhandled = is_struct(_native_ex);
    
    // Vars
    message =       "";
    longMessage =   "";
    script =        "";
    /// @is {string[]}
    stacktrace =    [];
    // @ignore
    line =          -1;
    
    if (_is_from_unhandled)
    {
		// Populate data directly from the native exception struct
		message =       _native_ex.message;
		longMessage =   _native_ex.longMessage;
		script =        _native_ex.script;
		line =          _native_ex.line;
        
		// The stacktrace from unhandled exceptions is already well-formatted.
		stacktrace =    _native_ex.stacktrace;
    }
    else
    {
		// The original logic for exceptions created with "new"
		// TODO: Check callstack format on different target platfroms
		var _stack = debug_get_callstack();
		var i=0; repeat(array_length(_stack) )
		{
		    var _line = _stack[i];
		    var _pos =  string_pos(":", _line);
            
		    if (i == 2)
		    {
		        script = string_copy(_line, 1, _pos - 1);
		        line =   real(string_copy(_line, _pos + 1, string_length(_line) - _pos) );
		    }
            
		    _line =  string_replace(_line, ":", " (line ");
		    _line += ")";
            
		    array_push(stacktrace, _line);
		    i++;
		}
    }

    // If the exception comes from an unhandled error, we don't need to call init()
    if (_is_from_unhandled)
    {
        static_set(self, static_get(Exception) );
    }
   
    /// @return {String}
    static toString = function() 
    {
        return (longMessage);
    }
    
    /// @description Saves the exception information to an .exception file
    /// @returns {String} The name of the generated file or "" on failure.
    static saveToFile = function()
    {
        var _dt = date_current_datetime();
        var _datetime_str = date_datetime_string(_dt);
        _datetime_str = string_replace_all(_datetime_str, ":", "-");
        _datetime_str = string_replace_all(_datetime_str, "/", "-");
        var _filename = $"crash_{_datetime_str}.exception";
        
        var _file = file_text_open_write(_filename);
        
        if (_file < 0)
        {
            show_debug_message($"ERROR: Could not create exception file '{_filename}'");
            return "";
        }
        
        file_text_write_string(_file, "========================================");
        file_text_writeln(_file);
        file_text_write_string(_file, $"      GMLException Crash Report");
        file_text_writeln(_file);
        file_text_write_string(_file, "========================================");
        file_text_writeln(_file);
        file_text_write_string(_file, $"Version: {__GMLEXCEPTION_VERSION}");
        file_text_writeln(_file);
        file_text_write_string(_file, $"Timestamp: {date_datetime_string(_dt)}");
        file_text_writeln(_file);
        file_text_writeln(_file);
        
        file_text_write_string(_file, "Short Message:");
        file_text_writeln(_file);
        file_text_write_string(_file, "--------------");
        file_text_writeln(_file);
        file_text_write_string(_file, message);
        file_text_writeln(_file);
        file_text_writeln(_file);
        
        file_text_write_string(_file, "Long Message / Formatted Output:");
        file_text_writeln(_file);
        file_text_write_string(_file, "--------------------------------");
        file_text_writeln(_file);
        file_text_write_string(_file, longMessage);
        file_text_writeln(_file);
        file_text_writeln(_file);
        
        file_text_write_string(_file, "Stacktrace:");
        file_text_writeln(_file);
        file_text_write_string(_file, "-----------");
        file_text_writeln(_file);
        var i=0; repeat(array_length(stacktrace))
        {
            file_text_write_string(_file, $"  -> {stacktrace[i++]}" );
            file_text_writeln(_file);
        }
        file_text_writeln(_file);
        
        file_text_write_string(_file, "========================================");
        file_text_writeln(_file);
        file_text_write_string(_file, "End of Report");
        file_text_writeln(_file);
        
        file_text_close(_file);
        
        show_debug_message($"Exception information saved to: '{_filename}'");
        
        return _filename;
    }
    
    /// @description Initializes the exception
    static init = function() 
    {
        var _name =     instanceof(self);
        message =       $"{_name}: {message}";
        longMessage =   $"{_name}\r\n{longMessage}";
        
        // add more info for YYC as it is not adding standard error output like on VM
        if (code_is_compiled() ) 
		{
            longMessage = string("Unable to find a handler for exception {0}\r\n", longMessage);
            
			var i=0; repeat(array_length(stacktrace))
			{
				longMessage += "\r\n" + stacktrace[i++];
			}
        }
		
        static_set(self, static_get(Exception) );
    }

    /// @description Sets up the global handler for uncaught exceptions.
    static setupUnhandledHandler = function()
    {
        var _handler = function(ex)
        {
            show_debug_message("--- UNHANDLED EXCEPTION CAUGHT ---");
            
            // Check if the exception is already one of our custom exceptions
            if (instanceof(ex) == "Exception")
            {
                // If so, just save it to the file
                ex.saveToFile();
            }
            else
            {
                // If it's a native GM exception, create a new instance of our class
                // passing the native exception to it for processing
                var _custom_ex = new Exception(ex);
                _custom_ex.saveToFile();
            }
            
            // Show the error message to the player (useful for debugging)
            show_message(ex.longMessage);
        };
        
        exception_unhandled_handler(_handler);
    }
}

// This ensures the Exception constructor runs and its static methods are available.
script_execute(Exception);