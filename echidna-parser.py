#!/usr/bin/env python3
import re

def parse_echidna_trace(trace):
    """Parse Echidna trace and extract function calls, parameters, delays, and 'from' addresses."""
    calls = []
    last_address = None  # Track the last 'from' address

    for line in trace.strip().splitlines():
        # Parse function calls, including those with underscores
        func_call = re.match(r"Tester\.([a-zA-Z0-9_]+)\(([^)]*)\)", line)
        if func_call:
            func_name = func_call.group(1)
            params = func_call.group(2)

            # Check for 'from' address
            from_address = re.search(r"from: (0x[a-fA-F0-9]+)", line)
            time_delay = re.search(r"Time delay: (\d+)", line)

            # If we have a 'from' address, we need to set it up
            if from_address:
                address = from_address.group(1)
                if address != last_address:
                    # Only set up the actor if the address has changed
                    calls.append(f"_setUpActor({address});")
                    last_address = address

            # Add the delay if it exists
            if time_delay:
                delay_time = time_delay.group(1)
                calls.append(f"_delay({delay_time});")

            # Add the function call
            calls.append(f"Tester.{func_name}({params});")

        # Handle special case of "*wait*" for a delay
        elif "*wait*" in line:
            time_delay = re.search(r"Time delay: (\d+)", line)
            if time_delay:
                delay_time = time_delay.group(1)
                calls.append(f"_delay({delay_time});")

    return calls

def generate_foundry_test(calls, test_name="test_replay"):
    """Generate the Solidity test function code."""
    test_code = [f"function {test_name}() public {{"]
    test_code.extend(f"    {call}" for call in calls)
    test_code.append("}")

    return "\n".join(test_code)

# Ask user to paste the Echidna trace
print("Paste your Echidna call trace below. Press Enter twice to finish:")
trace = []
while True:
    line = input()
    if line:
        trace.append(line.strip())
    else:
        break
trace = "\n".join(trace)

# Parse the trace and generate the test
parsed_calls = parse_echidna_trace(trace)
solidity_test = generate_foundry_test(parsed_calls)

# Output the generated Solidity test
print("\nGenerated Foundry Test Function:\n")
print(solidity_test)
