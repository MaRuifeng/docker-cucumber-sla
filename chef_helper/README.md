# Chef Helper

This Chef utility is created upon a local Chef development kit (workstation) and a remote Chef server.
Its purpose is to manage the endpoint servers for automated Cucumber test execution of the CCSSD project.

* Prior to executing a feature test, a cookbook/recipe can be run against the targeted server to set required pre-conditions
* After execution, the changes made to the server for that particular feature can be discarded using a counter cookbook/recipe

## Getting Started

This Chef utility is configured to connect to Chef server sla-d-cms-chef-sjc01.sdad.sl.dst.ibm.com (9.51.154.54) by default, at port 9443. The host sla-d-cms-chef-sjc01.sdad.sl.dst.ibm.com is actually running 2 Chef server instances. The other is the standard one used by CCSSD application.

As a Cucumber developer, you need to make sure helper cookbooks/recipes are also created and uploaded to the Chef server when developing test scripts for a particular feature. Those cookbooks/recipes can then be invoked before and after test execution to either set pre-conditions or restore server state. This way the test can be executed in a repeatable manner without human intervention.


### Prerequisites

Chef Development Kit

## Usage

* Use common `knife` commands to manage cookbooks and endpoint nodes
* Use common `chef generate` commands to work on customized resources/providers/templates/files
* Store test data used in pre-condition settings in Chef data bags

## Deployment

Bundled within the Cucumber docker image. 

## Built With

Cucumber docker image on the Jenkins server.

## Contributing

Develop the helper cookbooks/recipes and upload them to the Chef server properly. 

## Authors

* **[Ruifeng Ma](ruifengm@sg.ibm.com)** - *Initial work*


## License

N.A.

## Acknowledgments

N.A.
