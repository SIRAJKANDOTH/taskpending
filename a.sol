    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.3;

    contract Array {
        // Several ways to initialize an array
        uint[] public arr;
        uint[] public arr2 = [1, 2, 3];
        // Fixed sized array, all elements initialize to 0
        uint[10] public myFixedSizeArr;

        function get(uint i) public view returns (uint) {
            return arr[i];
        }

        // Solidity can return the entire array.
        // But this function should be avoided for
        // arrays that can grow indefinitely in length.
        function getArr() public view returns (uint[] memory) {
            return arr;
        }

        function push(uint i) public {
            // Append to array
            // This will increase the array length by 1.
            arr.push(i);
        }

        function pop() public {
            // Remove last element from array
            // This will decrease the array length by 1
            arr.pop();
        }

        function getLength() public view returns (uint) {
            return arr.length;
        }

        function remove(uint index) public {
            // Delete does not change the array length.
            // It resets the value at index to it's default value,
            // in this case 0
            delete arr[index];
        }
    }

    contract CompactArray {
        uint[] public arr;

        // Deleting an element creates a gap in the array.
        // One trick to keep the array compact is to
        // move the last element into the place to delete.
        function remove(uint index) public {
            // Move the last element into the place to delete
            arr[index] = arr[arr.length - 1];
            // Remove the last element
            arr.pop();
        }

        function test() public {
            arr.push(1);
            arr.push(2);
            arr.push(3);
            arr.push(4);
            // [1, 2, 3, 4]

            remove(1);
            // [1, 4, 3]

            remove(2);
            // [1, 4]
        }
    }



    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.3;

    contract Todos {
        struct Todo {
            string text;
            bool completed;
        }

        // An array of 'Todo' structs
        Todo[] public todos;

        function create(string memory _text) public {
            // 3 ways to initialize a struct
            // - calling it like a function
            todos.push(Todo(_text, false));

            // key value mapping
            todos.push(Todo({text: _text, completed: false}));

            // initialize an empty struct and then update it
            Todo memory todo;
            todo.text = _text;
            // todo.completed initialized to false

            todos.push(todo);
        }

        // Solidity automatically created a getter for 'todos' so
        // you don't actually need this function.
        function get(uint _index) public view returns (string memory text, bool completed) {
            Todo storage todo = todos[_index];
            return (todo.text, todo.completed);
        }

        // update text
        function update(uint _index, string memory _text) public {
            Todo storage todo = todos[_index];
            todo.text = _text;
        }

        // update completed
        function toggleCompleted(uint _index) public {
            Todo storage todo = todos[_index];
            todo.completed = !todo.completed;
        }
    }

    pragma solidity >=0.4.0 <0.7.0;

    contract MappingExample {
        mapping(address => uint) public balances;

        function update(uint newBalance) public {
            balances[msg.sender] = newBalance;
        }
    }

    contract MappingUser {
        function f() public returns (uint) {
            MappingExample m = new MappingExample();
            m.update(100);
            return m.balances(address(this));
        }
    }

    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.3;

    contract IfElse {
        function foo(uint x) public pure returns (uint) {
            if (x < 10) {
                return 0;
            } else if (x < 20) {
                return 1;
            } else {
                return 2;
            }
        }
    }

    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.3;

    contract Loop {
        function loop() public {
            // for loop
            for (uint i = 0; i < 10; i++) {
                if (i == 3) {
                    // Skip to next iteration with continue
                    continue;
                }
                if (i == 5) {
                    // Exit loop with break
                    break;
                }
            }

            // while loop
            uint j;
            while (j < 10) {
                j++;
            }
        }
    }