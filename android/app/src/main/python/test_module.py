import os
import sys
import traceback

def test_function():
    try:
        log_file = "/storage/emulated/0/Download/python_test.txt"
        with open(log_file, 'w') as f:
            f.write("=== Test Python Module ===\n")
            f.write(f"Python version: {sys.version}\n")
            f.write(f"Python path: {sys.path}\n")
            f.write(f"Current directory: {os.getcwd()}\n")
            f.write(f"Directory contents: {os.listdir()}\n")
        return "Test successful"
    except Exception as e:
        error_msg = f"Test error: {str(e)}\n{traceback.format_exc()}"
        try:
            with open("/storage/emulated/0/Download/python_error.txt", 'w') as f:
                f.write(error_msg)
        except:
            pass
        return error_msg
