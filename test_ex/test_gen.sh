#!/bin/bash

# Define valid test cases
valid_tests=(
"def main with input x output y as
  y = 1 + 2 * 3;"

"def main with input x output y as
  y = (1 + 2) * 3;"

"def main with input x output y as
  y = 10 - 5 - 2;"

"def main with input x output y as
  y = 10 - (5 - 2);"

"def main with input x output y as
  y = 3 * 4 + 5 * 6;"

"def main with input x output y as
  y = 3 * (4 + 5) * 6;"

"def main with input x output y as
  y = 10 < 20 and 5 < 3;"

"def main with input x output y as
  y = not (10 < 20 and 5 < 3);"

"def main with input x output y as
  y = not 10 < 20 and 5 < 3;" 

"def main with input x output y as
  if 3 * 2 < 10 then y = 1 else y = 0;"

"def main with input x output y as
  while x < 10 do x = x + 1;"  

"def main with input x output y as
  y = 3 * (4 - 2) + 5 * (6 / 2);"
)

# Define invalid test cases
invalid_tests=(
"def main with input x output y as
  y = 10 < 20 5 < 3;"  # Missing operator

"def main with input x output y as
  y = (10 + 5;"  # Unmatched parenthesis

"def main with input x output y as
  if x then 5 else 10;"  # Missing condition syntax

"def main with input x output y as
  while (while) do x = 1;"  # Nested invalid while

"def main with input x output y as
  y = 10 --- 5;"  # Invalid operator

"def main with input x output y as
  y = x 10 +;"  # Unexpected number placement

"def main with input x output y as
  10 = y;"  # Assignment to a number

"def main with input x output y as
  y = 10 < < 20;"  # Double comparison operator
)

# Write valid tests to files
i=1
for test in "${valid_tests[@]}"; do
  echo "$test" > "test_$i.minimp"
  ((i++))
done

# Write invalid tests to files
for test in "${invalid_tests[@]}"; do
  echo "$test" > "test_$i.minimp"
  ((i++))
done

echo "Test files generated in the 'tests/' directory."
