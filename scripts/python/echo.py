import json
import sys
import os

# If STDIN is provided, use this method
# Read user input (call raw_input only once!).
#input_str = raw_input()

# If ENV vars are provided, use this method
# A json object was sent to the program, so it must be parsed.
input_json = json.loads( os.environ['INPUT_JSON'] )

# Process the input
name   = input_json["name"] # name = input_str
output = 'Hello, pythonist ' + name + "!"

# The output of the program is the STDOUT...
sys.stdout.write(output)  # same as "print output"
# And STDERR
#sys.stderr.write(output)