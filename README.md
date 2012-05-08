I'm cf\_oo.  Im an object oriented library to help managing Cloud Formation Stacks.

Installation
============

Pre-requisites
--------------

* AWS Account
* nix OS with ruby (I'm tested with 1.9.3p125)

Steps
-----

Install cf\_oo

```
gem install cf_oo
```  

Setup the credentials file .cf_oo.yml within your home directory.  This will be used to manage Cloud Formation stacks across different accounts and different environments of the SDLC.

```
prod:
  app1:
    aws_access_key_id: XXXXXXXXXXXXXXXXXXXX
    aws_secret_access_key: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
preprod:
  app1:
    aws_access_key_id: XXXXXXXXXXXXXXXXXXXX
    aws_secret_access_key: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

Getting Started With CLI
========================

Create New Stack
----------------

To create a new stack, you will need to give a template and specify any options as well as a name for the new stack.

```
cf_oo create -n my-stack -e preprod -t ~/stacks/default.json -p Param1=value?1Param2=value2
```

**Required parameters:**

-e environement [Environement to build stack.  Must match keys in ~/.cf_oo.yml]  
-n name [name for the new stack]  
-p parameters [? seperated KEY=VALUE pairs of parameters to overide]  
-t template [Cloud Formation template to build stack against]  

**Optional parameters:**

-r region [AWS region]  

Listing Available Stacks
------------------------

Stacks are listed based on the contents of the .cf_oo.yml file created earlier.  To see a list of stacks.

```
cf_oo list
```

Get Stack Details
-----------------

```
cf_oo describe -n my-stack -e preprod
```

List Stack Instances
--------------------

```
cf_oo instances -n my-stack -e preprod
```

Show Stack Template
-------------------

```
cf_oo template -n my-stack -e preprod
```

Update Running Stack
--------------------

To update a running stack, you can either use the existing template and provide new paramaters.  For example:

```
cf_oo update -n my-stack -e preprod -p Param1=NewValue
```

or provide a new template if changes to non parameter resources are required:

```
cf_oo update -n my-stack -e preprod -t my-update-template.json
```

You can use the template command to download a stacks running template and make changes if desired.

Deleting A Stack
----------------

You must specify the stack name and environment you are deleting.  Be careful, theres no going back once this is in motion!

```
cf_oo delete -n my-stack -e preprod
```
