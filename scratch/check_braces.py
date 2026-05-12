
import sys

def find_mismatch(filename):
    with open(filename, 'r') as f:
        content = f.read()
    
    stack = []
    line_num = 1
    col_num = 1
    
    for i, char in enumerate(content):
        if char == '\n':
            line_num += 1
            col_num = 1
        else:
            col_num += 1
            
        if char == '{':
            stack.append((line_num, col_num))
        elif char == '}':
            if not stack:
                print(f"Extra closing brace at {line_num}:{col_num}")
                return
            stack.pop()
            
    if stack:
        for line, col in stack:
            print(f"Unclosed opening brace at {line}:{col}")
    else:
        print("Braces are balanced")

if __name__ == "__main__":
    find_mismatch(sys.argv[1])
