windows_task_schedule Cookbook
============================

This cookbook provides Chef recipes that assists in test automation of the Windows Task Scheduling feature of SSD
  1) Set pre-conditions
  2) Clear changes made to the endpoint server by the test

Owners
------
Author: ruifengm@sg.ibm.com
Organization: IBM

Requirements
------------
Managed Node: Windows OS
Cookbook Dependency: windows (https://github.com/chef-cookbooks/windows)

Attributes
----------

#### windows_task_schedule::default
<table>
  <tr>
    <th>TBD</th>
  </tr>
  <tr>
    <td>TBD</td>
  </tr>
</table>

Usage
-----
#### windows_task_schedule::[recipe_name]


Include `windows_task_schedule` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[windows_task_schedule::delete_all_ssd_tasks]"
  ]
}
```

Contributing
------------
Contact the owner before contributing.

1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
-------------------
Authors: ruifengm@sg.ibm.com

