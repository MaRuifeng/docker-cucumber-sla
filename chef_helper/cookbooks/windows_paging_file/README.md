windows_paging_file Cookbook
============================

This cookbook provides Chef recipes that manage the virtual memory (paging file) of the Windows OS. 
TODO: add supported Windows OS versions
Windows paging file size management rules: 
	1. Automatically managed for all drives
	2. If not, the user has the authority with below setting options for each drive
	    a. Set custom size (Initial and Maximum in MegaBytes)
	    b. System managed
	    c. No paging file

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

#### windows_paging_file::default
<table>
  <tr>
    <th>name</th>
    <th>initial_size</th>
    <th>maximum_size</th>
    <th>system_managed</th>
    <th>automatic_managed</th>
  </tr>
  <tr>
    <td>path to the customized paging file, e.g. "C:/pagefile.sys"</td>
    <td>initial page file size in MegaBytes; check Windows support document for acceptable value</td>
    <td>maximum page file size in MegaBytes; check Windows support document for acceptable value</td>
    <td><tt>true/false</tt></td>
    <td><tt>true/false</tt></td>
  </tr>
</table>

Usage
-----
#### windows_paging_file::set_page_file


Include `windows_paging_file` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[windows_paging_file::set_page_file]"
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

