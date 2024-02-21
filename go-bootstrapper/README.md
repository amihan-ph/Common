# Golang Project Bootstrap Tool

### Description

Golang project bootstrap tool is a code generator that will create boilerplate code for a golang project.

### Installation

Install golang project bootstrap tool by cloning and building it:

`go install gitlab.com/amihan/common/tooling/go-bootstrapper@latest`


### Usage

`go-bootstrapper generate [type] [options]`

### Extended Description
Running `go-bootstrapper` will generate a boilerplate project in the directory that the command is run.
### Types
#### microservice

Will generate a golang microservice project in the current directory. 
##### Options

|Name|Default|Description|
|--|:--:|--|
|--git-host|gitlab.com|The git host where the project will be hosted. This will also be the first component in the project's module path|
|--project-group|amihan|The subgroup structure where this project will reside. It can be as deep a nested path as is required|
|--project-version|0.0.1|The semver version string of the project|
|--project-name||The human readable name of the project to generate|
|--project-slug||The Slug name for the project to generate. This will be used as the project identifier.|
|--has-database|false|If this option is passed, database (postgresql) boilerplate code will be generated|
|--has-messagebus|false|If this option is passed, kafka boilerplate code will be generated|
|--has-jwt|false|If this option is passed, boiler plate for authentication via json web tokens is generated|
|--has-api-key|false|If this option is passed, boiler plate for authentication via a API keys in the HTTP header is generated|

##### Examples
###### Generate bare microservice
`go-bootstrapper generate microservice`

Running this example will generate a microservice project with sample endpoints but no database, message bus or auth ingtegrations of any kind. 

The user will get prompted to input a git host, project group, name, slug and version.

###### Generate microservice with all possible integration boilerplate.
`go-bootstrapper generate microservice --has-database --has-messagebus --has-jwt --has-api-key`

Running this example will generate a microservice project with sample endpoints, database (postgres), messaging (kafka), jwt auth and api key auth.

###### Generate project without prompting for attributes
`go-bootstrapper generate microservice --git-host=gitlab.com --project-group=amihan/common/services --project-version=1.0.0 --project-name="My WebService" --project-slug=slug-service --has-database --has-messagebus --has-jwt --has-api-key`

Running this example will generate a microservice project with sample endpoints, database (postgres), messaging (kafka), jwt auth and api key auth. The user will not be prompted for the project attributes, the passed properties will instead be used.

##### Working with the generated projects.
The generated projects will use `wire` to as a dependency injection framework. 
* wire must first be installed by running `go install github.com/google/wire/cmd/wire@latest`. 
* Once wire is installed, the dependency code must be generated. This is done by cd-ing into the cmd folder inside the generated project:

`cd ${PROJECT_FOLDER}/cmd` then run `wire`

##### Packaging generated project
The generated build scripts assume that vendoring is enabled and hence that dependencies exist in the `vendor` folder of the project. Before trying to package a container from the generated project, first run:

`go mod vendor`

Once the above steps are done the project can be worked on as any normal golang project.
### Extending or modifying Golang Project Bootstrap Tool
Golang Project Bootstrap Tool uses `markbates/pkger` to bundle static assets with the generated binary. If you need to modify or add templates you will need to first install pkger.

`go install github.com/markbates/pkger/cmd/pkger@latest`

Every time a change or additional templates are added the following command needs to be run to regenerate the `pkged.go` file. 

`pkger -include /templates -o internal/eval`

*Note that the working directory must be the root of the Golang Project Bootstrap Tool code when the above command is run.

To add a type of project to be generated just add a new folder inside `templates` run pkger and rebuild Golang Project Bootstrap Tool. After that you should be able to pass the name of the folder as the `type` argument to `go-bootstrapper`
