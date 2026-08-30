/// @desc Example object to demonstrate throwing and catching custom exceptions.

// Example of throwing a custom exception when a specific key is pressed.
if (keyboard_check_pressed(vk_f1) || keyboard_check_pressed(ord("1")) ) 
{
	Exception.Breadcrumb("F1 key pressed, about to throw TestException");
	throw new TestException();
}

// Example of throwing an ArgumentException when the number of arguments provided to a method is not valid.
if (keyboard_check_pressed(vk_f2) || keyboard_check_pressed(ord("2")) ) 
{
	Exception.Breadcrumb("F2 key pressed, about to throw ArgumentException");
	throw new ArgumentException(3, 2);
}

// Example of throwing a NotImplementedException when a method is not implemented.
if (keyboard_check_pressed(vk_f3) || keyboard_check_pressed(ord("3")) ) 
{
	Exception.Breadcrumb("F3 key pressed, about to throw NotImplementedException");
	throw new NotImplementedException("do_something");
}

// Anonymous constructor example
if (keyboard_check_pressed(vk_f4) || keyboard_check_pressed(ord("4")) ) 
{
	Exception.Breadcrumb("F4 key pressed, about to throw an exception from an anonymous constructor");
	throw new (function() : Exception() constructor
	{
		message = "Exception from anonymous constructor";
		longMessage = "This exception was created from an anonymous constructor function.";
		
		init();
	})();
}

// show_error example to demonstrate catching native exceptions with our custom handler
if (keyboard_check_pressed(vk_f5) || keyboard_check_pressed(ord("5")) )
{
	Exception.Breadcrumb("F5 key pressed, about to call show_error to demonstrate catching native exceptions");
	show_error("This is a native error that should be caught by our unhandled exception handler and converted to our custom Exception class.", false);
}