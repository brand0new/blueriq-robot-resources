# Robot resources for Blueriq Modeling Platform

[Robot Framework](https://robotframework.org/) is a generic open source automation framework. It can be used for test automation and robotic process automation (RPA).

At Blueriq we've created these resources as a mean to enable quick and robust **automated regression tests**.

## Goal

Using these resources you'll be able to quickly get started creating automated tests that **don't depend on the GUI of Blueriq applications**.

This is achieved by using our [**UI REST API**](https://my.blueriq.com/display/DOC/UI+REST+API+V2) on which you can read more at our Community space.

## Benefits

The main benefit is the drastic improvement in duration time in comparison to automated test that have been **written against GUI components**.

This problem is tool-agnostic as it is possible to write non-performant tests with tools like Cypress.io, Cucumber or even Robot. 

You can determine whether or not this is the case if there are any **"waitForElement/waitForBlueriqElement"** components.

## Guide

In order to be able to use Robot Framework. You'll need to the following prerequisites:
1. Install python
2. Check version for python and pip (run "python --version" and "pip --version")
3. Add python to the "PATH" variable within the System Environments Variables
4. Install Robot Framework (run "pip install robotframework")

At this point you'll be able to run .robot and .resource files. But you'll either need to use a text editor with plugins - like Visual Studio Code - or you can continue down below to install Robot IDE (RIDE)

5. Install wxPython (run "pip install wxPython)
6. Install RIDE (run "pip install -U https://github.com/robotframework/RIDE/archive/master.zip", this depends on the version of the other software. Check https://github.com/robotframework/RIDE for more information)



