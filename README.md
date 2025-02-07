# se-insomnia-demo

## Overview

**Introduction:**

This demonstration will walk through a day in the life of a developer, showcasing how Insomnia can seamlessly integrate into their workflow.

We’ll start where developers care most—the code—by examining the repository where the code resides. From there, we’ll highlight the challenges of manual API testing against the developer's code and demonstrate how Insomnia simplifies the debugging process. Next, we’ll explore how importing an OpenAPI Specification (OAS) can streamline the design process, significantly improving the quality of the specs. Finally, we’ll demonstrate automated testing and how these tests can be incorporated into a CI/CD pipeline for consistency and reliability.

**High Level Demo Structure:**

Manual Testing Pain

Login to Insomnia:

- SSO integration
- Storage Controls

Request Collections:

- Environments
- Request Chaining
- Pre-request Scripting
- Faker.js

Design Documents:

- Generation of Collection
- Authentication
- Private Environments
- Git Sync

Testing:

- Collections Runner
- After-Response Scripting for Testing
- Upload CSV Data

Automation:

- Inso CLI
- Run as part of a pipeline

Mocking

Postman Bulk Import

---

## Environment Setup

### Docker Compose

#### Prerequisites

This demonstration environment has been tested with the following:

- Insomnia 10.3
- inso cli 10.3.0
- jq 1.7.1
- docker 27.2.1
- openssl 3.4.0
- decK v1.40.2

#### Fork this Repository

Fork this repository or clone it to your own repository.

#### Configure Environment

Set the following enviroment variables:

``` bash
export KONNECT_REGION=eu|us
export KONNECT_TOKEN=[YOUR KONNECT PAT OR SAT]
```

#### Run Setup Script

To setup the environment, simply run the following command:

``` bash
sh start.sh
```

This will do the following:

- Generate TLS Key and Cert
- Create Kong Konnect Control Plane
- Upload the TLS Cert to the Control Plane
- Use Docker Compose to Deploy:
  - Insomnia Mock Server
  - Kong Gateway
  - Backend Applications (HTTPBin, Employees Directory)
  - KeyCloak
- Use decK to configure the Kong Gateway

#### Setup GitHub Self-hosted Runner

> Optional: Only required if you want to show integration with a real CI/CD pipeline.

Guidance available here:

<https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/adding-self-hosted-runners#adding-a-self-hosted-runner-to-a-repository>

#### Setup GitHub Repository Secrets

> Optional: Only required if you want to show integration with a real CI/CD pipeline.

Set the following Actions Secrets in your GitHub Repository:

`KEYCLOAK_CLIENT_ID: sOr3UTEwwuHrj5nyxpDVNJnK5GuoHEsN`

`KEYCLOAK_CLIENT_SECRET: 8tx6He8lOpQVVD2pBVZzfo6Zgz4kmUfI`

Guidance available here:

<https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions>

#### Clean-up

The following command will run docker compose down and delete the Kong Konnect Control Plane:

``` bash
sh delete.sh
```

---

## Demo Storyboard

### Situation

As a developer we've been tasked to create a new employee managment application, and we have a first version available.

### Section 1: Leading with Code

#### 1.1 Tell

This is a simple Go applications which offers CRUD operations on a list of employees. We can present the repository and show the resources and methods available.

#### 1.2 Show

Show Employee directory code in repository and show endpoints

<https://github.com/kong/se-insomnia-demo/blob/master/src/main.go>

Specifically, highlight this part which shows what exactly our code is doing:

![alt text](./docs/images/1-code/s1-1.png "Application Code")

#### 1.3 Tell

We've just had a look at our code, let's try it out!

---

### Section 2: Manual Testing with cURL

#### 2.1 Tell

Without a tool like Insomnia in place, invocation of APIs is cumbersome and complex using cURL.  This  is especially so when working with OAuth and chaining requests together.  This section we establish the pain of manual testing.

#### 2.2 Show

Send a Get Request and observe that it fails as we dont have any credentials.

``` bash
curl -s http://localhost:8000/api/employees | jq .
```

![alt text](./docs/images/2-manual-testing/s2-3.png "Authentication Failure")

Get an Access Token from KeyCloak:

``` bash
curl -s -X POST http://localhost:8080/realms/insomnia-demo/protocol/openid-connect/token -H "content-type: application/x-www-form-urlencoded" -H "accept: application/x-www-form-urlencoded, application/json" -H "Authorization: Basic c09yM1VURXd3dUhyajVueXhwRFZOSm5LNUd1b0hFc046OHR4NkhlOGxPcFFWVkQycEJWWnpmbzZaZ3o0a21VZkk=" -d "grant_type=client_credentials" | jq .
```

![alt text](./docs/images/2-manual-testing/s2-2.png "Getting a Token")

This time get the Access Token and save to an environment variable.  Highlight how clunky this is getting already:

``` bash
TOKEN=$(curl -s -X POST http://localhost:8080/realms/insomnia-demo/protocol/openid-connect/token -H "content-type: application/x-www-form-urlencoded" -H "accept: application/x-www-form-urlencoded, application/json" -H "Authorization: Basic c09yM1VURXd3dUhyajVueXhwRFZOSm5LNUd1b0hFc046OHR4NkhlOGxPcFFWVkQycEJWWnpmbzZaZ3o0a21VZkk=" -d "grant_type=client_credentials" | jq .access_token -r)
```

Now that we have the token, show further requests working directly against API (you don't have to show them all):

*Get All Employees:*

``` bash
curl -s http://localhost:8000/api/employees -H "Authorization: Bearer $TOKEN" | jq .
```

*Create a New Employee:*

``` bash
curl -s -X POST http://localhost:8000/api/employees -H "Authorization: Bearer $TOKEN" -d '{"id": "15","name": "Jane Doe","jobTitle": "Solutions Engineer", "email": "jane@email.com"}' | jq .
```

*Get an Employee by ID:*

``` bash
curl -s http://localhost:8000/api/employees/15 -H "Authorization: Bearer $TOKEN" | jq .
```

*Delete the Employee we Created:*

``` bash
curl -s -X DELETE http://localhost:8000/api/employees/15 -H "Authorization: Bearer $TOKEN" | jq .
```

#### 2.3 Tell

As we just saw, while possible, we need to remember and assemble complex commands in order to do even basic operations when authentication is required. If you only do this once maybe it's OK but you'll need to do this over and over, as will your colleagues.

---

### Section 3: Introduce Insomnia

#### 3.1 Tell

The purpose of this section is to introduce the Insomnia application and provide a view on the main components, whilst highlighting the governance functionality.

Let's have a look at how Insomnia can help!

#### 3.2 Show

Start logged out so that we can show SSO integration.

Open Insomnia App and Login and use this as the point to talk about SSO integration that we have setup in Kong:

![Logging in](./docs/images/3-insomnia-intro/s3-3.png "Logging in")

Talk about the main objects that we can create:

- Organisations and Projects
- Collections vs design documents

Navigate to your SE Org and speak about the collaboration between SEs with our Insomnia collections and documents.

![Collaboration](./docs/images/3-insomnia-intro/s3-1.png "Collaboration")

Navigate to your Personal Org

Create a new Local Project in your personal Org and talk about storage control limitations that can be put in place:

![Storage](./docs/images/3-insomnia-intro/s3-4.png "Storage")

> Optional Step: You will need an account that has access to this page, if not, just use slides or a talk track on the previous page.

Show rules on Insomnia Cloud (have this open in a tab in your browser already):

![Governance](./docs/images/3-insomnia-intro/s3-2.png "Governance")

#### 3.3 Tell

We just saw how we can use standardized credentials to sign in, how to organise work using Organisations and Projects, the objects we share and how they are stored. The security and governance of your data is a key differentiator for Kong, where Kong offers many options making collaboration and governance easy, without compromising on security.

---

### Section 4: Request Collections

#### 4.1 Tell

The purpose of this section is to show how easy it is to create a collections of requests, importing from cURL commands, and to show how comprehensive the Insomnia tooling is.

Let's create a similar set of requests we did with cURL in Insomnia, so we can reuse them in the future, and share to help our peers.

#### 4.2 Show

Within your Personal Project, create a new Collection and give it the name of your choice:

Talk through different ways of creating requests (multiple protocols, import from other sources).

Create a request manually and call any endpoint of your choosing.  For example:

`http://httpbin.konghq.com/anything`

Walk through the **Preview**, **Headers** and **Console** tabs on the right hand pane:

![alt text](./docs/images/4-request-collections/s4-1.png "Second Request")

Show response content filtering using JSONPath at bottom right hand corner (remember to hit enter):

``` jsonpath
$.method
```

![Third Request](./docs/images/4-request-collections/s4-2.png "Third Request")

Talk through folders and how they can be used to organise our collection.

Create a New Folder called `Employees Directory`

Right click on the new folder and select "From Curl":

![curl import](./docs/images/4-request-collections/s4-3.png "curl import")

Copy and paste our request to Keycloak into the text area and click on Import:

``` bash
curl -s -X POST http://localhost:8080/realms/insomnia-demo/protocol/openid-connect/token -H "content-type: application/x-www-form-urlencoded" -H "accept: application/x-www-form-urlencoded, application/json" -H "Authorization: Basic c09yM1VURXd3dUhyajVueXhwRFZOSm5LNUd1b0hFc046OHR4NkhlOGxPcFFWVkQycEJWWnpmbzZaZ3o0a21VZkk=" -d "grant_type=client_credentials"
```

![First Request](./docs/images/4-request-collections/s4-4.png "First Request")

Rename the Request to `Get Token`.

Send the request and show the response on the right hand pane.

We can then talk about parameterizing the requests so that values dont have to be hard coded.

Edit the Base Environment underneath Collection Environments:

![Environments](./docs/images/4-request-collections/s4-5.png "Environments")

Lets store the KeyCloak base path as an environment variable:

``` json
{
  "keycloak": "http://localhost:8080"
}
```

Go back to the request and refer to environment variable:

![alt text](./docs/images/4-request-collections/s4-6.png "Variables")

Import another cURL command into our folder to get all employees:

``` bash
curl http://localhost:8000/api/employees -H "Authorization: Bearer $TOKEN"
```

Rename the Request to Get All Employees (this isn't essential but does make the demo easier to follow).

**Send** the request and show error the Unauthorized Error due to the Token environment variable not being available via the import process:

![Unauthorized Error](./docs/images/4-request-collections/s4-7.png "Unauthorized Error")

Mention that you could run our previous command and then quickly copy and paste it across but this wouldnt be scalable.  We can use request chaining to solve for this.

Change this to use request chaining to get the token in the Authorization Header by selecting **Response -> Body Attribute** (right clicking on field with Bearer in it):

![Request Chaining](./docs/images/4-request-collections/s4-8.png "Request Chaining")

Click on the red tag and configure this as follows:

![Request Chaining Config](./docs/images/4-request-collections/s4-9.png "Request Chaining Config")

Request: `[Employees Directory] POST Get Token`
Filter: `$.access_token`

Talk through the Trigger Behaviour options and pick one, such as Always, then click Done.

**Send** the request and show that it is now working.

As before, Import the next cURL command into our folder to create a new employee:

``` bash
curl -s -X POST http://localhost:8000/api/employees \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"id": "15", "name": "Jane Doe", "jobTitle": "Solutions Engineer", "email": "jane@email.com" }'
```

Rename the request to `Create New Employee`.

Quickly copy and paste the contents of our previous requests Authorization header into the Authorization header for this request so that we can get a token.

**Send** the request and show that it has been successful.

We can now make it more dynamic by using faker.js on all fields apart from the uuid so that we arent sending in the same data every single time (we will come onto the UUID shortly):

![Faker.js](./docs/images/4-request-collections/s4-10.png "Faker.js")

**Send** the request and bring notice to the response received.

Instead of using faker.js, we can use an external service to get a UUID.  Maybe we dont want to use request chaining to do this, maybe we want to do some pre-processing via a script.  Talk about pre-request functions and what is possible.

Change the uuid value to `{{uuid}}`

![UUID Variable Setup](./docs/images/4-request-collections/s4-11.png "UUID Variable Setup")

> Note that this will be red and showing an error but this is expected as the uuid environment variable has not yet been set.

Navigate the the Scripts tab and add a Pre-request script:

``` javascript
insomnia.sendRequest("https://httpbin.konghq.com/uuid", function (err, res) {
    if (err) {
        console.log(err);
    } else {
    console.log("Response from httpbin:", res.json());
        var uuid = res.json().uuid;
        insomnia.environment.set("uuid", uuid);
        console.log("UUID fetched and set:", uuid);
    }
});
```

Explain that this gets a UUID from an external service using JavaScript and saves it to a variable that will be used by the uuid tag in our request body.

Optional: We can further enhance this script by adding the UUID to a header.  Use the Insomnia UI tools to Add UUID to Header via **Request Manipulation -> Add a Header** at the bottom of the central pane.

This will be inserted as follows:

``` javascript
insomnia.request.addHeader({key: 'X-Header-Name', value: 'header_value' });
```

Change this to the following and insert it underneath the `console.log` line:

``` javascript
insomnia.request.addHeader({key: 'X-UUID', value: uuid });
```

**Send** the Request and show the Console, highlighting the logs being written and the header that was set.

Right click on any of the requests that have been creted so far and show the **Generate Code** options:

![Generate Client Code](./docs/images/4-request-collections/s4-12.png "Generate Client Code")

#### 4.3 Tell

We explored collections, filtering, organizing with folders, importing from cURL, using variables, request chaining, generating values with Faker, pre- and post-request functions, setting headers and generating client code. Juggling tokens and complex flows just got more manageable!

---

### Section 5: Design Documents

#### 5.1 Tell

Design Documents (also called Documents) hold specifications, API requests, and tests. They also offer the capability to sync with Git.

> **TODO: Many of our customers prefer to take a Contract First Approach, APIOps**

#### 5.2 Show

Navigate back to your Personal Project

Create a new **Design Document**

Take the OAS file from `./config/oas/oas.yaml` and copy into Insomnia.  Useful to have this open in your text/code editor ahead of time.

Find the issue with the OpenAPI Specification and fix it by deleting line 13.

![Fix OAS](./docs/images/5-design-documents/s5-1.png "Fix OAS")

Show the interactive documentation in the preview pane on the right.  Chose a request and demonstrate the try it now functionality.  Remember to click the Authorize button first, the Client Credentials are available in the modal that is presented.

![Docs Preview Auth](./docs/images/5-design-documents/s5-3.png "Docs Preview Auth")

Setup Git Sync to your forked repository on GitHub.

![Git Sync Setup](./docs/images/5-design-documents/s5-2.png "Git Sync Setup")

**Commit changes** to the GitHub Repository, ensuring that all objects are staged, you provide a sensible commit message and hit Commit and push.

![Commiting Changes](./docs/images/5-design-documents/s5-7.png "Commiting Changes")

Bring up the git repository in GitHub or the tooling of your choice and talk through what has been created in the `.insomnia` folder.

![Git Repository Contents](./docs/images/5-design-documents/s5-8.png "Git Repository Contents")

Open and talk through the `.spectral.yaml` file found in the root of the repository:

``` yaml
rules:
  paths-kebab-case:
    description: Paths should be kebab-case.
    message: "{{property}} should be kebab-case (lower-case and separated with hyphens)"
    severity: warn
    given: $.paths[*]~
    then:
      function: pattern
      functionOptions:
        match: "^(\/|[a-z0-9-.]+|{[a-zA-Z0-9_]+})+$"
```

Show linting against custom ruleset by changing one of the paths to something that is not kebab case:

![alt text](./docs/images/5-design-documents/s5-9.png "Spectal Linting")

Create a new feature branch and give it the name of your choosing.

![alt text](./docs/images/5-design-documents/s5-10.png "Branching")

Make a minor change to the description field of the OpenAPI Specification file and **Commit and push** the change to the branch as before.  Note the diff viewer so you can see exactly what has changed.

#### 5.3 Tell

Using linting really helps finding simple errors early. Previewing documentation is a great motivator to create better documentation. Custom rulesets ensure you can apply your best practices.

---

### Section 6: Testing

#### 6.1 Tell

Testing APIs are essential to ensure they work as intended. Defining tests based on the specification ensures the specification is aligned with the actual API. Maintaining tests in an implementation-agnostic tool like Insomnia provides freedom to refactor the implementation in the future.

In order to work in more complex environments, environment management is required. Running tests in an automated way like CI/CD requires a reliable command line interface.

#### 6.2 Show

Generate a Request Collection from the OpenAPI Specification, significantly speeding up the time it has taken us to generate our collection of requests.  Remember all of that importing from cURL?

![alt text](./docs/images/6-testing/s6-1.png "Generate Collection")

Open up environments and delete the generated environment called **OpenAPI env localhost:8000**.

Copy and Paste the following to the base environment:

``` json
{
  "base_url": "http://localhost:8000",
  "employeeId": 1234
}
```

Create a new **Private environment**, name it Private and add the following:

``` json
{
  "oauth2ClientId": "sOr3UTEwwuHrj5nyxpDVNJnK5GuoHEsN",
  "oauth2ClientSecret": "8tx6He8lOpQVVD2pBVZzfo6Zgz4kmUfI"
}
```

![Create Private Environment](./docs/images/6-testing/s6-2.png "Create Private Environment")

Ensure that the Private Environment is selected:

![Private Environment Selected](./docs/images/6-testing/s6-3.png "Private Environment Selected")

**Commit and push** changes to your feature branch.

Show that a request works as expected now, with a lot less effort than before when we manually imported via Curl.

Show the Auth tab on one of the requests to see that that OAuth configuration to get an Access Token from KeyCloak has been automatically generated.  Talk about the other Authentication methods available by scrolling through the dropdown.

![OAuth Client](./docs/images/6-testing/s6-4.png "OAuth Client")

Open and Introduce the Collection Runner.

**Run** it, ensuring all requests are selected and show the result, note to the audience that we havent written any tests as yet:

![Collection Runner](./docs/images/6-testing/s6-5.png "Collection Runner")

But we can see a lot of useful information in the Console Tab:

![Insomnia Console](./docs/images/6-testing/s6-6.png "Insomnia Console")

Lets now create our tests by selecting the **Create a new employee** request and opening the **Scripts** tab and clicking the **After-response** tab.

Copy and Paste the following JavaScript and explain that we can check the status code is valid:

``` JavaScript
insomnia.test('Check if status is 201', () => {
 insomnia.expect(insomnia.response.code).to.eql(201);
});
```

**Send** the request and open the tests tab on the right to show that the test is passing:

![Test Passing](./docs/images/6-testing/s6-7.png "Test Passing")

Now do the same for the **Find Employee by ID** request:

``` javascript
insomnia.test("The response has all properties", () => {

 const responseJson = insomnia.response.json();
 insomnia.expect(responseJson.id).to.have.lengthOf(1);
 insomnia.expect(responseJson.id).to.eql('1');
 insomnia.expect(responseJson.name).to.be.a('string');
 insomnia.expect(responseJson.name).to.eql('Chris');
 insomnia.expect(responseJson.jobTitle).to.be.a('string');
 insomnia.expect(responseJson.jobTitle).to.eql('Solutions Engineer Manager');
 insomnia.expect(responseJson.email).to.be.a('string');
 insomnia.expect(responseJson.email).to.eql('chris@kongexample.com');

});

insomnia.test('Check if status is 200', () => {
    insomnia.expect(insomnia.response.code).to.eql(200);
});
```

**Send** the request and open the tests tab on the right to show that both tests are passing.

Now do the same for the **Get all employees** request:

``` JavaScript
insomnia.test("Check if the array has all expected properties", () => {

// Parse the response body as a JSON array
let body = insomnia.response.json();

insomnia.expect(body).to.be.an('array');

// Iterate through each item in the body array
body.forEach(item => {
    // Check if the item is an object
    insomnia.expect(item).to.be.an('object');
    // Check if the required properties exist in the object
    insomnia.expect(item).to.have.property('id');
    insomnia.expect(item).to.have.property('jobTitle');
    insomnia.expect(item).to.have.property('name');
    insomnia.expect(item).to.have.property('email');
});

});

insomnia.test('Check if status is 200', () => {
    insomnia.expect(insomnia.response.code).to.eql(200);
});
```

**Send** the request and open the tests tab on the right to show that both tests are passing.

Now open the Collection Runner and select the three requests that we have written tests for:

![Select our requests](./docs/images/6-testing/s6-8.png "Select our requests")

This is still fairly static, we could make this more interesting by passing in a csv file with our data and then iterate through it.

First we need to parameterise the **Create a new employee** request by changing the Body to the following:

``` javascript
{
  "id": "{{id}}",
  "name": "{{name}}",
  "jobTitle": "{{jobTitle}}",
  "email": "{{email}}"
}
```

This will show errors on each of the tags but these can be ignored as the data will be pulled from the csv file:

![Parameterize the post request](./docs/images/6-testing/s6-9.png "Parameterize the post request")

Click on the **Upload Data** button and use the csv file found in this repository `./test/runner.csv`:

![Csv Test Data File](./docs/images/6-testing/s6-10.png "Csv Test Data File")

The Collection Runner will automatically detected that it needs to iterate 5 times so select the 3 requests and hit Run.  You will see that 25 tests have been executed.

![Collection Runner Tests](./docs/images/6-testing/s6-11.png "Collection Runner Tests")

Go to the Console to go into the detail of the tests and show the csv data was injected.

**Commit and push** our changes to the feature branch.

Go to your Git Repository and you will see that a branch has been created:

![New Branch Created](./docs/images/6-testing/s6-12.png "New Branch Created")

We want to merge our feature branch with the main branch but in most organisations the main branch will be protected so we need to go through a proper change control process.  Click on **"Compare & pull request"** so that we can create a pull request.

**Create pull request** and then **Merge pull request** and then **Confirm merge**.  Optionally you can also delete the branch.

![Merge Pull Request](./docs/images/6-testing/s6-13.png "Merge Pull Request")

Open Insomnia and checkout the main branch using the Git Sync menu at the bottom left of the screen.

#### 6.3 Tell

Insomnia not just supports environments and test automation, it also supports test grouping with collection runner and pulling parameters from external sources like a .csv file. Insomnia supports modern pull request flows, making API testing a charm.

---

### Section 7: Automation

#### 7.1 Tell

Now that we have tests and a way to interact with Git, we'll want to run tests automatically (CI/CD). Let's have a look at using the collection runner on the command line and a GitHubActions pipeline example.

#### 7.2 Show

Go to collection runner and **Run via CLI** from the menu.

![alt text](./docs/images/7-automation/s7-1.png "Run via CLI")

This should look something like this:

``` bash
inso run collection wrk_d6ba5b -i req_a6612a8edba546bf8dafbc0334830bc0 -i req_7d723a191b404dfaabac6f8998be6b17 -i req_84b77271a61f4196a776c2907136d8a4 -e env_b979d4 -n 5 -d "/Users/konger@konghq.com/github/insomnia-demo-project/test/runner.csv" --bail
```

Run this in your terminal and show the output:

![Test Output](./docs/images/7-automation/s7-2.png "Test Output")

> The next step is optional if you want to show this running as part of a real pipeline.

We can use this as part of a pipeline.

Create a `ci.yaml` file in `.github/workflows`:

![Create file](./docs/images/7-automation/s7-3.png "Create file")

Add the following to the pipeline.  Talk through the linting step.

``` yaml
name: Inso

on:

  push:
    branches: 
      - '**'

  workflow_dispatch:

jobs:

  inso:

    runs-on: self-hosted
    name: Lints OAS and Runs Tests

    steps:
    
    - name: Checkout
      uses: actions/checkout@v4

    - name: Lint OpenAPI Spec
      run: |
        inso lint spec $(yq '._id' $(echo -n .insomnia/ApiSpec/*)) \
        --workingDir .

    - name: Run Tests
      id: run-tests
      run: |
        inso run collection $(yq '._id' $(echo -n .insomnia/Workspace/*)) \
        --env $(yq '._id' $(echo -n .insomnia/Environment/*)) \
        --iteration-data ./test/runner.csv \
        --iteration-count 5 \
        --workingDir . \
        --env-var "oauth2ClientId=$KEYCLOAK_CLIENT_ID" \
        --env-var "oauth2ClientSecret=$KEYCLOAK_CLIENT_SECRET" \
        --requestNamePattern "^(?!Delete an employee by ID$).*" \
        --verbose \
        --ci 2>/dev/null
      env:
        KEYCLOAK_CLIENT_ID: ${{ secrets.KEYCLOAK_CLIENT_ID }}
        KEYCLOAK_CLIENT_SECRET: ${{ secrets.KEYCLOAK_CLIENT_SECRET }}
```

Note that as we are not pushing our Private environment to GitHub, we need to get these variables from the repository itself.

Commit and Push directly to main using GitHub UI, click on **Actions** to show the pipeline running and completing:

![alt text](./docs/images/7-automation/s7-4.png "Run via CLI")

Feel free to explore the detailed output from the tests in the **Run Tests** section.

#### 7.3 Tell

We just saw how you can execute a collection of tests and set up CI/CD automation to have them run automatically as code is changed.

---

### Section 8: Mocking

#### 8.1 Tell

API mocks are useful for simulating an API endpoint. For example, when building a front end while the backend API is under construction and unstable, Insomnia allows us to customize responses from a set of API paths to simulate a static API. This mocked URL can then replace our front-end API backend URL.

#### 8.2 Show

Open Insomnia and create a new mock server in your Project.  We have a **Self-hosted Mock** server running in a Docker container so we can use this for the demonstration or you can choose to use a **Cloud Mock**.  Pick the most appropriate option for your prospective customer.

![Create mock server](./docs/images/8-mocking/s8-1.png "Create mock server")

Then navigate to the **Design Document** and select the request **Get all employees**.

Send the Request and Create a new mock server from the response by clicking on the **Mock** tab in the right hand pane and then selecting your newly created Mock Server from the drop down and then click **Create**:

![alt text](./docs/images/8-mocking/s8-2.png "Create mock")

For the route, leave the default `/api/employees` and press **Submit**.

Show mocking UI and talk through configuration options such as setting headers and status codes.

Hit **Test** and show the mocked response returned.

Copy the URL by clicking the copy icon next to the Test button and use this to replace the one our previous **Get all employees** request.

![alt text](./docs/images/8-mocking/s8-3.png "Get mock URL")

It should look similar to this:

`http://localhost:9090/bin/mock_90adfe93dcb642c0968b14bc2f3ce882/api/employees`

Navigate back to your **Get all employees** request, replace the URL with the mock URL we copied and hit **Send**:

![alt text](./docs/images/8-mocking/s8-4.png "Invoke Mock")

#### 8.3 Tell

We just saw how you can create new Mock servers using Insomnia. Mocking can be done locally or in the cloud, what ever fits your organisation best.

---

### Section 9: Postman Bulk Import

#### 9.1 Tell

Insomnia supports importing and exporting. Currently, the supported import formats are Insomnia, Postman v2, HAR, OpenAPI (versions 3.0, 3.1), Swagger, WSDL, and cURL.  We will demonstrate how we can import our Postman environment into Insomnia.

#### 9.2 Show

Go to your Insomnia Project and click on the Import button.

Drap and drop the `./config/postman/postman-bulk-export.zip` file into the dialog and then click **Import**.

![alt text](./docs/images/9-postman-import/s9-1.png "Invoke Mock")

Note that environments have been imported and these can be shared across Request Collections and Design Documents.

Go into the Imported `Employees Directory` Request Collection and send a request to get a new token and then exectute a few of the requests.

Show that the after-response scripts have been migrated across successfully.

#### 9.3 Tell

Importing and exporting to and from Insomnia enables moving from one tool to another, as well as backing up your data. We just saw a simple way to import a postman collection, including environments and scripts.
